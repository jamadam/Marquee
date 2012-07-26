package Marquee;
use strict;
use warnings;
use Mojo::Base 'Mojo';
use Data::Dumper;
use File::Spec;
use File::Basename 'dirname';
use Digest::MD5 qw(md5_hex);
use Mojo::Path;
use Mojo::Asset::File;
use Mojo::URL;
use Mojo::Util qw'encode';
use Mojolicious::Types;
use Mojolicious::Commands;
use Marquee::Hooks;
use Marquee::Context;
use Marquee::SSIHandler::EP;
use Marquee::SSIHandler::EPL;
use Marquee::Stash;
use Marquee::ErrorDocument;
our $VERSION = '0.07';

our $CONTEXT;

__PACKAGE__->attr('document_root');
__PACKAGE__->attr('default_file');
__PACKAGE__->attr(error_document => sub {Marquee::ErrorDocument->new});
__PACKAGE__->attr('log_file');
__PACKAGE__->attr(hooks => sub {Marquee::Hooks->new});
__PACKAGE__->attr(roots => sub {[]});
__PACKAGE__->attr(secret => sub {md5_hex($^T. $$. rand(1000000))});
__PACKAGE__->attr(ssi_handlers => sub {{}});
__PACKAGE__->attr(stash => sub {Marquee::Stash->new});
__PACKAGE__->attr(types => sub { Mojolicious::Types->new });
__PACKAGE__->attr('under_development' => 0);
__PACKAGE__->attr('x_powered_by' => 'Marquee(Perl)');

### --
### Constructor
### --
sub new {
    my $self = shift->SUPER::new(@_);
    
    ### hook points
    $self->hook(around_dispatch => sub {
        shift;
        $CONTEXT->app->dispatch;
    });
    $self->hook(around_static => sub {
        shift;
        $CONTEXT->app->serve_static(@_);
    });
    $self->hook(around_dynamic => sub {
        shift;
        $CONTEXT->app->serve_dynamic(@_);
    });
    
    $self->add_handler(ep => Marquee::SSIHandler::EP->new);
    $self->add_handler(epl => Marquee::SSIHandler::EPL->new);
    
    # base path for CGI environment
    if ($ENV{DOCUMENT_ROOT} && ! defined $ENV{MARQUEE_BASE_PATH}) {
        my $tmp = $self->home->to_string;
        if ($tmp =~ s{^$ENV{DOCUMENT_ROOT}}{}) {
            $ENV{MARQUEE_BASE_PATH} = $tmp;
        }
    }
    
    return $self;
}

### --
### Add SSI handler
### --
sub add_handler {
    my ($self, $name, $handler) = @_;
    $self->ssi_handlers->{$name} = $handler;
    return $self;
}

### --
### Shortcut for context
### --
sub c {
    return $_[1] ? $CONTEXT = $_[1] : $CONTEXT;
}

### --
### Accessor for localized context
### --
sub context {
    return $_[1] ? $CONTEXT = $_[1] : $CONTEXT;
}

### --
### dispatch
### --
sub dispatch {
    my ($self) = @_;
    
    my $tx = $CONTEXT->tx;
    my $path = $tx->req->url->path->clone->canonicalize;
    
    if (@{$path->parts}[0] && @{$path->parts}[0] eq '..') {
        return;
    }
    
    if (! $CONTEXT->served) {
        if ($path =~ /$self->{_handler_re}/) {
            $self->error_document->serve(403);
            return;
        }
    }
    
    if (! $CONTEXT->served) {
        my $path = _auto_fill_filename($path->clone, $self->default_file);
        $path->leading_slash(0);
        $path = "$path";
        
        if (my $try1 = $self->search_static($path)) {
            $self->hooks->emit_chain('around_static', $try1);
        } elsif (my $try2 = $self->search_template($path)) {
            $self->hooks->emit_chain('around_dynamic', $try2);
        }
    }
    
    if (! $CONTEXT->served) {
        if (! $path->trailing_slash && scalar @{$path->parts}
                                            && $self->is_directory($path)) {
            my $uri = $tx->req->url->clone->path(
                                $path->clone->trailing_slash(1))->to_abs;
            $self->serve_redirect($uri);
        }
    }
}

### --
### handler
### --
sub handler {
    my ($self, $tx) = @_;
    
    local $CONTEXT = Marquee::Context->new(app => $self, tx => $tx);
    
    $self->_init;
    
    $tx->res->headers->header('X-Powered-By' => $self->x_powered_by);

    eval {
        $self->hooks->emit_chain('around_dispatch');
    };
    
    if ($@) {
        $self->log->fatal("Processing request failed: $@");
        $self->error_document->serve(500, $@);
    }
    
    if (! $CONTEXT->served) {
        $self->error_document->serve(404);
        $self->log->fatal($tx->req->url->path. qq{ Not found});
    }
    
    $tx->resume;
}

### --
### Add hook
### --
sub hook {
    shift->hooks->on(@_);
}

### --
### Check if the path is a directory or not
### --
sub is_directory {
    my ($self, $path) = @_;
    
    for my $root (@{$self->roots}) {
        my $path = File::Spec->catdir($root, $path);
        if (-d $path) {
            return 1;
        }
    }
}

### --
### detect mime type out of path name
### --
sub path_to_type {
    my ($self, $path) = @_;
    if (my $ext = ($path =~ qr{\.(\w+)(?:\.\w+)?$})[0]) {
        return $self->types->type($ext);
    }
}

### --
### Register plugin
### --
sub plugin {
    my ($self, $name, $args) = @_;
    
    unless ($name =~ s/^\+//) {
        $name = "Marquee::Plugin\::$name";
    }
    
    if (! $name->can('register')) {
        my $file = $name;
        $file =~ s!::!/!g;
        require "$file.pm"; ## no critic
    }
    my $plug = $name->new;
    $plug->register($self, $args);
    return $plug;
}

### --
### detect and render
### --
sub render_ssi {
    my ($self, $path) = @_;
    my $ext = ($path =~ qr{\.\w+\.(\w+)$})[0];
    if (my $handler = $self->ssi_handlers->{$ext}) {
        return $handler->render_traceable($path);
    } else {
        die "SSI handler not detected for $path";
    }
}

### --
### search static file
### --
sub search_static {
    my ($self, $path) = @_;
    
    for my $root (($path =~ qr{^/}) ? '' : @{$self->roots}) {
        my $path = File::Spec->catdir($root, $path);
        if (-f $path) {
            return $path;
        }
    }
}

### --
### search template
### --
sub search_template {
    my ($self, $path) = @_;
    
    for my $root (($path =~ qr{^/}) ? undef : @{$self->roots}) {
        for my $ext (keys %{$self->ssi_handlers}) {
            my $path = File::Spec->catdir($root, "$path.$ext");
            if (-f $path) {
                return $path;
            }
        }
    }
}

### --
### serve redirect
### --
sub serve_redirect {
    my ($self, $uri) = @_;
    
    my $tx = $CONTEXT->tx;
    $tx->res->code(301);
    $tx->res->headers->location($self->to_abs($uri)->to_string);
    return $self;
}

### --
### serve static content
### --
sub serve_static {
    my ($self, $path) = @_;
    
    my $asset = Mojo::Asset::File->new(path => $path);
    my $modified = (stat $path)[9];
    
    my $tx = $CONTEXT->tx;
    
    # If modified since
    my $req_headers = $tx->req->headers;
    my $res_headers = $tx->res->headers;
    if (my $date = $req_headers->if_modified_since) {
        my $since = Mojo::Date->new($date)->epoch;
        if (defined $since && $since == $modified) {
            $res_headers->remove('Content-Type')
                ->remove('Content-Length')
                ->remove('Content-Disposition');
            return $tx->res->code(304);
        }
    }
    
    $tx->res->content->asset($asset);
    $tx->res->code(200);
    $res_headers->last_modified(Mojo::Date->new($modified));
    if (my $type = $self->path_to_type($path)) {
        $tx->res->headers->content_type($type);
    }
    
    return $self;
}

### --
### serve dynamic content
### --
sub serve_dynamic {
    my ($self, $path) = @_;
    
    my $ret = $self->render_ssi($path);
    
    if (defined $ret) {
        my $tx = $CONTEXT->tx;
        $tx->res->body(encode('UTF-8', $ret));
        $tx->res->code(200);
        if (my $type = $self->path_to_type($path)) {
            $tx->res->headers->content_type($type);
        }
    }
    
    return $self;
}

### --
### start app
### --
sub start {
    my $self = $ENV{MOJO_APP} = shift;
    $self->_init;
    Mojolicious::Commands->start;
}

### --
### auto fill files
### --
sub _auto_fill_filename {
    my ($path, $default) = @_;
    if ($default) {
        if ($path->trailing_slash || ! @{$path->parts}) {
            push(@{$path->parts}, $default);
            $path->trailing_slash(0);
        }
    }
    return $path;
}

### ---
### Asset directory
### ---
sub asset {
    my $class = shift;
    my $pm = $class. '.pm';
    $pm =~ s{::}{/}g;
    my @seed = (substr($INC{$pm}, 0, -3), 'Asset');
    if ($_[0]) {
        return File::Spec->catdir(@seed, $_[0]);
    }
    return File::Spec->catdir(@seed);
}

### --
### init
### --
sub _init {
    my $self = shift;
    
    if ($self->{_inited}) {
        return;
    }
    $self->{_inited} = 1;
    
    if (! -d $self->document_root) {
        die 'document_root is not a directory';
    }
    
    unshift(@{$self->roots}, $self->document_root, __PACKAGE__->asset());

    $self->{_handler_re} =
                '\.(?:'. join('|', keys %{$self->ssi_handlers}). ')$';
    
    if ($self->log_file) {
        $self->log->path($self->log_file);
    }
}

### --
### generate absolute uri
### --
sub to_abs {
    my ($self, $url) = @_;
    
    $url = Mojo::URL->new($url);
    
    if (! $url->scheme) {
        my $tx = $CONTEXT->tx;
        my $base = $tx->req->url->clone;
        $base->userinfo(undef);
        $url->base($base);
    }
    
    return $url->to_abs;
}

1;

__END__

=head1 NAME

Marquee - Simple HTTP server with Server-side include

=head1 SYNOPSIS
    
    #!/usr/bin/env perl
    use strict;
    use warnings;
    
    use File::Basename 'dirname';
    use File::Spec;
    use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';
    
    use Marquee;
    
    my $app = Marquee->new;
    $app->document_root($app->home->rel_dir('public_html'));
    $app->start;

=head1 DESCRIPTION

L<Marquee> is a simple web server base class. The module also is a
backend of C<mojo Marquee>, a command line tool.
This is built on mojo modules in L<Mojolicious> distribution. 

=head1 ATTRIBUTES

=head2 document_root

Specify a path to document root directory. The directory can contain both static
files and templates.

    $app->document_root($app->home->rel_dir('public_html'));

=head2 default_file

Specify a default file name and activate auto fill.

    $app->default_file('index.html');

=head2 error_document

Error document renderer instance. Defaults to
L<Marquee::ErrorDocument>

    $app->error_document(Marquee::ErrorDocument->new);

=head2 log_file

Specify a log file path.

    $app->document_root($app->home->rel_dir('log/myapp.log'));

=head2 hooks

A L<Marquee::Hooks> instance.

    $app->hooks(Marquee::Hooks->new);

=head2 roots

Array of paths that contains static and templates.

    push(@{$app->roots}, 'path/to/additional_dir')

=head2 secret

A secret passphrase used for signed cookies and the like, defaults to random
string. 

    my $secret = $app->secret;
    $app       = $app->secret('passw0rd');

=head2 ssi_handlers

An hash ref that contains Server side include handlers.

    $app->ssi_handlers->{ep} = Marquee::SSIHandler::EP->new;

You can append SSI association by C<add_handler> method instead of doing above.

=head2 stash

An L<Marquee::Stash> instance.

    $app->stash(Marquee::Stash->new);
    my $stash = $app->stash;

=head2 types

Contains L<Mojolicious::Type> instance.

    my $type = $app->types;
    $type->type(zip => 'application/zip');

=head2 under_development

Activate debug screen.

    $app->under_development(1);

=head2 x_powered_by

Set X-POWERED-BY response header.

    $app->x_powered_by('MyApp');

=head1 METHODS

=head2 Marquee->new;

Constructor.

    my $app = Marquee->new;

=head2 $instance->add_handler(name => $code_ref);

Adds C<ssi_handlers> entry.

    $instance->add_handler(ep => Marquee::SSIHandler::EP->new);

=head2 Marquee->asset($filename);

Returns bundled asset path for given file name.

    my $asset = Marquee->asset('path/to/common.css');
    
    say $asset # /path/to/lib/Marquee/Asset/path/to/common.css
    
    my $asset = Marquee->asset();
    
    say $asset # /path/to/lib/Marquee/Asset

In other packages

    my $asset = SomePackage->Marquee::asset('path/to/common.css');
    
    say $asset # /path/to/lib/SomePackage/Asset/path/to/common.css
    
    my $asset = SomePackage->Marquee::asset();
    
    say $asset # /path/to/lib/SomePackage/Asset

=head2 $instance->c()

An alias for C<context> method.

=head2 $instance->context()

Returns current context. This refers to localized C<$Marquee::CONTEXT>.

    my $context = $app->context;

=head2 $instance->dispatch()

Front dispatcher.

    $app->dispatch()

=head2 $instance->handler($tx)

Handler called by mojo layer.

    $app->handler($tx)

=head2 $instance->hook($name => $cb)

Alias to $instance->hooks->on. This adds a callback for the hook point.

    $app->hook(around_dispatch => sub {
        my ($next, @args) = @_;
        ### pre-process
        $next->(@args);
        ### post-process
    });

=head2 $instance->is_directory($path)

Returns if the path is directory.

    $app->is_directory('/path/to/directory') # bool

=head2 $instance->path_to_type($path)

Detect MIME type out of path name.

    my $type = $app->path_to_type('/path/to/file.css') # text/css

=head2 $instance->plugin($class => $params)

Load a class as a plugin. The prefix 'Marquee::Plugin' is prepended unless the
class name C<$class> begins with C<+> sign, which means the class name is
already fully qualified.

    my $plugin = $app->plugin(Plugin => $params); # Marquee::Plugin::PlugName
    my $plugin = $app->plugin('+NameSpace::Plugin' => $params); # NameSpace::Plugin

=head2 $instance->render_ssi($path)

    my $result = $app->render_ssi('/path/to/template.html.ep');

=head2 $instance->search_static($path)

Searches for static files for given path and returns the path if exists.

    $app->search_static('./a.html'); # /path/to/document_root/a.css
    $app->search_static('/path/to/a.html'); # /path/to/a.css

=head2 $instance->search_template($path)

Searches for SSI template for given path and returns the path with SSI
extension if exists.

    $app->search_template('./template.html'); # /path/to/document_root/template.html.ep
    $app->search_template('/path/to/template.html'); # /path/to/template.html.ep

=head2 $instance->serve_redirect($uri)

Serves response that redirects to given URI.

    $app->serve_redirect('http://example.com/');
    $app->serve_redirect('/path/');

=head2 $instance->serve_static($path)

Serves static file of given path.

    $app->serve_static('/path/to/static.png');

=head2 $instance->serve_dynamic($path)

Serves dynamic SSI page with given file path.

    $app->serve_dynamic('/path/to/template.html.ep');

=head2 $instance->start()

Starts app

    $app->start();

=head2 $instance->to_abs

Generates absolute URI for given path along to the request URI.
    
    say $self->to_abs('/path/to/file.html');

On request to https://example.com:3001/a/index.html
The example above generates https://example.com:3001/path/to/file.html

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

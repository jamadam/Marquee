package Marquee;
use strict;
use warnings;
use Mojo::Base 'Mojo';
use File::Spec::Functions;
use Digest::MD5 qw(md5_hex);
use Mojo::Asset::File;
use Mojo::URL;
use Mojo::Util qw'encode';
use Mojolicious::Types;
use Mojolicious::Commands;
use Mojo::Exception;
use Marquee::Context;
use Marquee::ErrorDocument;
use Marquee::Hooks;
use Marquee::SSIHandler::EP;
use Marquee::SSIHandler::EPL;
use Marquee::Stash;
use Marquee::Static;
our $VERSION = '0.16';

our $CONTEXT;

__PACKAGE__->attr('document_root');
__PACKAGE__->attr('default_file');
__PACKAGE__->attr(error_document => sub {Marquee::ErrorDocument->new});
__PACKAGE__->attr(hooks => sub {Marquee::Hooks->new});
__PACKAGE__->attr(roots => sub {[]});
__PACKAGE__->attr(secret => sub {md5_hex($^T. $$. rand(1000000))});
__PACKAGE__->attr(ssi_handlers => sub {{}});
__PACKAGE__->attr(stash => sub {Marquee::Stash->new});
__PACKAGE__->attr(static => sub {Marquee::Static->new});
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
        $CONTEXT->app->static->serve(@_);
    });
    $self->hook(around_dynamic => sub {
        shift;
        $CONTEXT->app->serve_dynamic(@_);
    });
    
    $self->add_handler(ep => Marquee::SSIHandler::EP->new(log => $self->log));
    $self->add_handler(epl => Marquee::SSIHandler::EPL->new(log => $self->log));
    
    # base path for CGI environment
    if ($ENV{DOCUMENT_ROOT} && ! defined $ENV{MARQUEE_BASE_PATH}) {
        my $tmp = $self->home->to_string;
        if ($tmp =~ s{^\Q$ENV{DOCUMENT_ROOT}\E}{}) {
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
    
    my $path = $CONTEXT->req->url->path->clone->canonicalize;
    
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
            my $uri = $CONTEXT->req->url->clone->path(
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
        $self->error_document->serve(500, $self->under_development && $@);
    }
    
    if (! $CONTEXT->served) {
        $self->error_document->serve(404);
        $self->log->fatal($tx->req->url->path. qq{ Not found});
    }
    
    $CONTEXT->close;
    
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
        if (-d catdir($root, $path)) {
            return 1;
        }
    }
}

### --
### Set log file path
### --
sub log_file {
    return shift->log->path(shift);
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
    my ($self, $name, @args) = @_;
    
    unless ($name =~ s/^\+//) {
        $name = "Marquee::Plugin\::$name";
    }
    
    if (! $name->can('register')) {
        my $file = $name;
        $file =~ s!::!/!g;
        require "$file.pm"; ## no critic
    }
    my $plug = $name->new;
    $plug->register($self, @args);
    return $plug;
}

### --
### detect and render
### --
sub render_ssi {
    my ($self, $path, $handler_ext) = @_;
    my $ext = $handler_ext || ($path =~ qr{\.\w+\.(\w+)$})[0];
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
    
    for my $root (file_name_is_absolute($path) ? undef : @{$self->roots}) {
        if (-f (my $path = $root ? catdir($root, $path) : $path)) {
            return $path;
        }
    }
}

### --
### search template
### --
sub search_template {
    my ($self, $path) = @_;
    
    for my $root (file_name_is_absolute($path) ? undef : @{$self->roots}) {
        my $base = $root ? catdir($root, $path) : $path;
        for my $ext (keys %{$self->ssi_handlers}) {
            if (-f (my $path = "$base.$ext")) {
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
    
    $CONTEXT->res->code(301);
    $CONTEXT->res->headers->location($self->to_abs($uri)->to_string);
}

### --
### serve static content
### --
sub serve_static {
    shift->static->serve(@_);
}

### --
### serve dynamic content
### --
sub serve_dynamic {
    my ($self, $path) = @_;
    
    if (defined (my $ret = $self->render_ssi($path))) {
        $CONTEXT->res->body(encode('UTF-8', $ret));
        $CONTEXT->res->code(200);
        if (my $type = $self->path_to_type($path)) {
            $CONTEXT->res->headers->content_type($type);
        }
    }
}

sub start {
    my $self = $ENV{MOJO_APP} = shift;
    $self->_init;
    Mojolicious::Commands->new(app => $self)->run(@_ ? @_ : @ARGV);
}

### --
### auto fill files
### --
sub _auto_fill_filename {
    my ($path, $default) = @_;
    
    if ($default && ($path->trailing_slash || ! @{$path->parts})) {
        push(@{$path->parts}, $default);
        $path->trailing_slash(0);
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
        return catdir(@seed, $_[0]);
    }
    return catdir(@seed);
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
    
    if (! $self->document_root || ! -d $self->document_root) {
        die 'document_root is not a directory';
    }
    
    unshift(@{$self->roots}, canonpath($self->document_root), __PACKAGE__->asset);

    $self->{_handler_re} =
                '\.(?:'. join('|', keys %{$self->ssi_handlers}). ')$';
}

### --
### generate absolute uri
### --
sub to_abs {
    my ($self, $url) = @_;
    
    $url = Mojo::URL->new($url);
    
    if (! $url->scheme) {
        my $base = $CONTEXT->req->url->clone;
        $base->userinfo(undef);
        $url->base($base);
    }
    
    return $url->to_abs;
}

1;

__END__

=head1 NAME

Marquee - Yet another Mojo based web framework

=head1 SYNOPSIS

use Marquee directly.

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

Inherited application.

    package MyApp;
    use Mojo::Base 'Marquee';
    
    sub new {
        my $self = shift->SUPER::new(@_);
		
        $self->document_root($self->home->rel_dir('public_html'));
        $self->log_file($self->home->rel_dir('mojo_log/Marquee.log'));
        $self->default_file('index.html');
        $self->under_development(1);
        $self->secret('g3y3nheher');
		
        return $self;
    }
    
    package main;
    
    MyApp->new->start;

=head1 DESCRIPTION

L<Marquee> distribution is yet another web framework built on mojo modules
in L<Mojolicious> distribution, designed to make dynamic content
development to be plotted at an extension of designer work.

=head1 ATTRIBUTES

L<Marquee> inherits all attributes from L<Mojo> and implements the following
new ones.

=head2 C<document_root>

Specify a path to document root directory. The directory can contain both static
files and templates.

    $app->document_root($app->home->rel_dir('public_html'));

=head2 C<default_file>

Specify a default file name and activate auto fill. The auto fill will occurs
when the request path is trailing slashed.

    $app->default_file('index.html');

=head2 C<error_document>

Error document renderer instance. Defaults to L<Marquee::ErrorDocument>.

    $app->error_document(Marquee::ErrorDocument->new);

=head2 C<hooks>

A L<Marquee::Hooks> instance.

    $app->hooks(Marquee::Hooks->new);

=head2 C<roots>

Array of paths that contains static and templates. Marquee tries to find asset
files in ascend order in the array. The array is started with L</document_root>
copy, and followed by bundle directories for Marquee core and plugins.

    push(@{$app->roots}, 'path/to/additional_dir')

=head2 C<secret>

A secret passphrase used for signed cookies and the like, defaults to random
string. By changing this, you can expire all signed cookies at once.

    my $secret = $app->secret;
    $app       = $app->secret('passw0rd');

=head2 C<ssi_handlers>

An hash ref that contains Server side include handlers. The hash keys
corresponds to the last extensions of templates.

    $app->ssi_handlers->{myhandler} = Marquee::SSIHandler::MyHandler->new;

You can append SSI association by L</add_handler> instead of doing above.

=head2 C<stash>

An L<Marquee::Stash> instance. Though Marquee's stash is localized and cloned
per request, this also can contain persistent values for application specific
and can be referred transparently from anywhere.

    $app->stash(Marquee::Stash->new);
    my $stash = $app->stash;

=head2 C<static>

Static class instance.

    $app->static(Marquee::Static->new);
    my $static = $app->static;

=head2 C<types>

Contains L<Mojolicious::Type> instance.

    my $type = $app->types;
    $type->type(zip => 'application/zip');

=head2 C<under_development>

Activate debug screen, defaults to undef.

    $app->under_development(1);

=head2 C<x_powered_by>

Set X-POWERED-BY response header.

    $app->x_powered_by('MyApp');

The header appears as follows.

    Content-Type: text/html;charset=UTF-8
    X-Powered-By: MyApp
    Server: Mojolicious (Perl)

=head1 CLASS METHODS

L<Marquee> inherits all class methods from L<Mojo> and implements the following
new ones.

=head2 new

Constructor.

    my $app = Marquee->new;

=head2 C<asset>

Returns bundled asset path for given file name. If the file name not specified,
The method returns the asset directory.

    my $asset = Marquee->asset('path/to/common.css');
    
    say $asset # /path/to/lib/Marquee/Asset/path/to/common.css
    
    my $asset = Marquee->asset();
    
    say $asset # /path/to/lib/Marquee/Asset

This method allows you to bundle files for perl modules in separated name spaces.
The following is an example for getting bundle files of arbitrary module.

    my $asset = SomePackage->Marquee::asset('path/to/common.css');
    
    say $asset # /path/to/lib/SomePackage/Asset/path/to/common.css
    
    my $asset = SomePackage->Marquee::asset();
    
    say $asset # /path/to/lib/SomePackage/Asset

=head1 INSTANCE METHODS

L<Marquee> inherits all instance methods from L<Mojo> and implements the
following new ones.

=head2 C<add_handler>

Adds L</ssi_handlers> entry. The first argument is corresponds to the last
extensions of templates. Second argument must be a
L<Marquee::SSIHandler> sub class instance. See L<Marquee::SSIHandler::EPL> as an
example.

    $app->add_handler(myhandler => Marquee::SSIHandler::MyHandler->new);

Following file will be available.

    template.html.myhandler

=head2 C<c>

An alias for L</context> method.

=head2 C<context>

Returns current context. This refers to C<$Marquee::CONTEXT> localized
per request.

    my $c = $app->context;

=head2 C<dispatch>

Front dispatcher.

    $app->dispatch()

=head2 C<handler>

Handler called by mojo layer. This is the base point for every request and sets
a response to C<$tx>.

    $app->handler($tx)

=head2 C<hook>

Alias to $app->hooks->on. This adds a callback for specified hook point.
These hooks are currently available:

=over 2

=item C<around_dispatch>

Wraps dispatch process.

    $app->hook(around_dispatch => sub {
        my ($next, @args) = @_;
        ### pre-process
        $next->(@args);
        ### post-process
    });

=item C<around_static>

Wraps static dispatch process.

    $app->hook(around_static => sub {
        my ($next, @args) = @_;
        ### pre-process
        $next->(@args);
        ### post-process
    });

=item C<around_dynamic>

Wraps dynamic dispatch process.

    $app->hook(around_dynamic => sub {
        my ($next, @args) = @_;
        ### pre-process
        $next->(@args);
        ### post-process
    });

=back

=head2 C<is_directory>

Returns if the path is directory. The search is made against the directories in
L</roots> attribute paths.

    $app->is_directory('/path/to/directory') # bool

=head2 C<log_file>

Set log file

    $app->log_file('/path/to/file')

=head2 C<path_to_type>

Detect MIME type out of path name.

    my $type = $app->path_to_type('/path/to/file.css') # text/css

=head2 C<plugin>

Load a class as a plugin. The prefix L<Marquee::Plugin> is prepended unless the
class name C<$class> begins with C<+> sign, which means the class name is
already fully qualified.

    my $plugin = $app->plugin(Plugin => @params); # Marquee::Plugin::PlugName
    my $plugin = $app->plugin('+NameSpace::Plugin' => @params); # NameSpace::Plugin

=head2 C<render_ssi>

Render given file of path as SSI template and returns the result.
This method auto detect the handler with the file name unless second argument is
given. Note that the renderer extension is NOT to be suffixed automatically.

    # render /path/to/template.html.ep by ep handler
    my $result = $app->render_ssi('/path/to/template.html.ep');
    
    # render /path/to/template.html.ep by epl handler
    my $result = $app->render_ssi('/path/to/template.html.ep', 'epl');
    
    # render /path/to/template.html by ep handler
    my $result = $app->render_ssi('/path/to/template2.html', 'ep');

=head2 C<search_static>

Searches for static files for given path and returns the path if exists.
The search is against the directories in L</roots> attribute.

    my $path = $app->search_static('./a.html'); # /path/to/document_root/a.html
    my $path = $app->search_static('/path/to/a.html'); # /path/to/a.html

=head2 C<search_template>

Searches for SSI template for given path and returns the path with SSI
extension if exists. The search is against the directories in C</roots> attribute.

    my $path = $app->search_template('./tmpl.html'); # /path/to/document_root/tmpl.html.ep
    my $path = $app->search_template('/path/to/tmpl.html'); # /path/to/tmpl.html.ep

=head2 C<serve_redirect>

Serves response that redirects to given URI.

    $app->serve_redirect('http://example.com/');
    $app->serve_redirect('/path/');

=head2 C<serve_static>

Serves static file of given path. This method is an alias to
L<Marquee::Static/serve>.

    $app->serve_static('/path/to/static.png');

=head2 C<serve_dynamic>

Serves dynamic SSI page with given file path.

    $app->serve_dynamic('/path/to/template.html.ep');

=head2 C<start>

Starts app

    $app->start();

=head2 C<to_abs>

Generates absolute URI for given path along to the request URI.

On request to https://example.com:3001/a/index.html
The example below generates https://example.com:3001/path/to/file.html
    
    say $self->to_abs('/path/to/file.html');

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Marquee;
use strict;
use warnings;
use Mojo::Base -base;
use feature 'signatures';
no warnings "experimental::signatures";
use File::Spec::Functions;
use Digest::MD5 qw(md5_hex);
use Carp;
use Mojo::Asset::File;
use Mojo::URL;
use Mojo::Home;
use Mojolicious::Commands;
use Mojo::Exception;
use Mojo::Log;
use Mojo::Transaction::HTTP;
use Mojo::Util;
use Marquee::Context;
use Marquee::Dynamic;
use Marquee::ErrorDocument;
use Marquee::Hooks;
use Marquee::SSIHandler::EP;
use Marquee::SSIHandler::EPL;
use Marquee::Stash;
use Marquee::Static;
use Marquee::Types;
our $VERSION = '0.42';

our $CONTEXT;

has 'document_root';
has 'default_file';
has dynamic => sub {Marquee::Dynamic->new};
has error_document => sub {Marquee::ErrorDocument->new};
has home => sub { Mojo::Home->new->detect(ref shift) };
has log              => sub {
  my $self = shift;

  # Check if we have a log directory that is writable
  my $log  = Mojo::Log->new;
  my $home = $self->home;
  my $mode = $self->mode;
  $log->path($home->child('log', "$mode.log"))
    if -d $home->child('log') && -w _;

  # Reduced log output outside of development mode
  return $mode eq 'development' ? $log : $log->level('info');
};
has hooks => sub {Marquee::Hooks->new};
has mode     => sub { $ENV{MOJO_MODE} || $ENV{PLACK_ENV} || 'development' };
has roots => sub {[]};
has route => sub {
    my $router = $_[0]->plugin(Router => sub {});
    return $router->route;
};
has secrets => sub {[md5_hex($^T. $$. rand(1000000))]};
has stash => sub {Marquee::Stash->new};
has static => sub {Marquee::Static->new};
has types => sub { Marquee::Types->new };
has under_development => 0;
has x_powered_by => 'Marquee(Perl)';

### --
### Constructor
### --
sub new($class, @args) {
    my $self = $class->SUPER::new(@args);
    
    ### hook points
    $self->hook(around_dispatch => sub($) {
        $CONTEXT->app->dispatch;
    });
    $self->hook(around_static => sub($, @args) {
        $CONTEXT->app->static->serve(@args);
    });
    $self->hook(around_dynamic => sub($, @args) {
        $CONTEXT->app->dynamic->serve(@args);
    });
    
    $self->dynamic->add_handler(
                    ep => Marquee::SSIHandler::EP->new(log => $self->log));
    $self->dynamic->add_handler(
                    epl => Marquee::SSIHandler::EPL->new(log => $self->log));
    
    return $self;
}

### ---
### Asset directory
### ---
sub asset($class, $name=undef) {
    my $pm = $class. '.pm';
    $pm =~ s{::}{/}g;
    my @seed = (substr($INC{$pm}, 0, -3), 'Asset');
    return catdir(@seed, $name) if ($name);
    return catdir(@seed);
}

sub build_tx {
  return Mojo::Transaction::HTTP->new;
}

sub config { Mojo::Util::_stash(config   => @_) }

### --
### Shortcut for context
### --
sub c($, $set=undef) {
    return $set ? $CONTEXT = $set : $CONTEXT;
}

### --
### Accessor for localized context
### --
sub context($, $set=undef) {
    return $set ? $CONTEXT = $set : $CONTEXT;
}

### --
### dispatch
### --
sub dispatch($self) {
    
    my $path = $CONTEXT->req->url->path->clone->canonicalize;
    
    if (! $CONTEXT->served) {
        if ($path =~ $self->dynamic->handler_re) {
            $self->error_document->serve(403);
            return;
        }
    }
    
    if (! $CONTEXT->served) {
        $self->serve();
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
sub handler($self, $tx) {
    
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
    
    if ($tx->res->code == 200 && ! defined $tx->res->headers->content_type) {
        if (my $type = $self->types->type_by_path($tx->req->url->path)) {
            $tx->res->headers->content_type($type);
        }
    }
    
    $CONTEXT->close;
    
    $tx->resume;
}

### --
### Add hook
### --
sub hook($self, @args) {
    $self->hooks->on(@args);
}

### --
### Check if the path is a directory or not
### --
sub is_directory($self, $path) {
    for my $root (@{$self->roots}) {
        return 1 if (-d catdir($root, $path));
    }
}

### --
### Set log file path
### --
sub log_file($self, $path) {
    return $self->log->path($path);
}

### --
### Register plugin
### --
sub plugin($self, $name, @args) {
    
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
### server
### mojo v7.80 (commit:57310d5)
### --
sub server { }

### --
### serve
### --
sub serve($self, $path=undef) {
    
    if (! defined $path) {
        $path = $CONTEXT->req->url->path->clone->canonicalize;
        if (@{$path->parts}[0] && @{$path->parts}[0] eq '..') {
            $self->error_document->serve(400);
            my $path = $CONTEXT->req->url->path;
            $self->log->fatal(qq{Bad request path "$path", possible directory traversal attempt.});
            return;
        }
        $path = _auto_fill_filename($path->clone, $self->default_file);
        $path->leading_slash(0);
    }
    
    if (my $try1 = $self->static->search($path)) {
        $self->hooks->emit_chain('around_static', $try1);
    } elsif (my $try2 = $self->dynamic->search($path)) {
        $self->hooks->emit_chain('around_dynamic', $try2);
    }
}

### --
### serve redirect
### --
sub serve_redirect($self, $uri) {
    $CONTEXT->res->code(301);
    $CONTEXT->res->headers->location($self->to_abs($uri)->to_string);
}

### --
### generate absolute uri
### --
sub to_abs($self, $url) {
    
    $url = Mojo::URL->new($url);
    
    if (! $url->scheme) {
        my $base = $CONTEXT->req->url->clone;
        $base->userinfo(undef);
        $url->base($base);
    }
    
    return $url->to_abs;
}

### --
### start application
### --
sub start($self, @args) {
    $self->_init;
    Mojolicious::Commands->new(app => $self)->run(@args ? @args : @ARGV);
}

### --
### auto fill files
### --
sub _auto_fill_filename($path, $default=undef) {
    if ($default && ($path->trailing_slash || ! @{$path->parts})) {
        push(@{$path->parts}, $default);
        $path->trailing_slash(0);
    }
    return $path;
}

### --
### init
### --
sub _init($self) {
    
    return if ($self->{_inited});
    
    $self->{_inited} = 1;
    
    if (! $self->document_root || ! -d $self->document_root) {
        die 'document_root is not a directory';
    }
    
    unshift(@{$self->roots}, canonpath($self->document_root), __PACKAGE__->asset);
    
    $self->static->roots($self->roots);
    $self->dynamic->roots($self->roots);
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
    
    sub new($class, @args) {
        my $self = $class->SUPER::new(@args);
        
        $self->document_root($self->home->rel_dir('public_html'));
        $self->log_file($self->home->rel_dir('mojo_log/Marquee.log'));
        $self->default_file('index.html');
        $self->under_development(1);
        $self->secrets(['g3y3nheher']);
        
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

=head2 C<dynamic>

L<Marquee::Dynamic> class instance.

    $app->dynamic(Marquee::Dynamic->new);
    my $dynamic = $app->dynamic;

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

=head2 C<secrets>

A secret passphrases used for signed cookies and the like, defaults to random
string. By changing this, you can expire all signed cookies at once.

    my $secrets = $app->secrets;
    $app       = $app->secrets(['passw0rd']);

Only the first passphrase is used to create new signatures, but all of them for
verification. So you can increase security without invalidating all your
existing signed cookies by rotating passphrases, just add new ones to the
front and remove old ones from the back.

  # Rotate passphrases
  $app->secrets(['new_passw0rd', 'old_passw0rd', 'very_old_passw0rd']);

=head2 C<stash>

An L<Marquee::Stash> instance. Though Marquee's stash is localized and cloned
per request, this also can contain persistent values for application specific
and can be referred transparently from anywhere.

    $app->stash(Marquee::Stash->new);
    my $stash = $app->stash;

=head2 C<static>

L<Marquee::Static> class instance.

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

=head2 config

    my $hash = $app->config;
    my $foo  = $app->config('foo');
    $app     = $app->config({foo => 'bar', baz => 23});
    $app     = $app->config(foo => 'bar', baz => 23);

Application configuration.

    # Remove value
    my $foo = delete $app->config->{foo};
    
    # Assign multiple values at once
    $app->config(foo => 'test', bar => 23);

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

    $app->hook(around_dispatch => sub($next) {
        ### pre-process
        $next->();
        ### post-process
    });

=item C<around_static>

Wraps static dispatch process.

    $app->hook(around_static => sub($next, @args) {
        ### pre-process
        $next->(@args);
        ### post-process
    });

=item C<around_dynamic>

Wraps dynamic dispatch process.

    $app->hook(around_dynamic => sub($next, @args) {
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

=head2 C<plugin>

Load a class as a plugin. The prefix L<Marquee::Plugin> is prepended unless the
class name C<$class> begins with C<+> sign, which means the class name is
already fully qualified.

    my $plugin = $app->plugin(MyPlug => @params); # Marquee::Plugin::MyPlug
    my $plugin = $app->plugin('+MyPlugins::MyPlug' => @params); # MyPlugins::MyPlug

=head2 C<serve>

Serves specific content for given file path. This internally searches static
contents and dynamic contents.

    $app->serve('index.html');

=head2 C<serve_redirect>

Serves response that redirects to given URI.

    $app->serve_redirect('http://example.com/');
    $app->serve_redirect('/path/');

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

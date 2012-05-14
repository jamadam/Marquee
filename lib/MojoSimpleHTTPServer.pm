package MojoSimpleHTTPServer;
use strict;
use warnings;
use Mojo::Base 'Mojo';
use Data::Dumper;
use File::Spec;
use File::Basename 'dirname';
use Mojo::Path;
use Mojo::Asset::File;
use Mojo::Util qw'encode';
use Mojolicious::Types;
use Mojolicious::Commands;
use MojoSimpleHTTPServer::Hooks;
use MojoSimpleHTTPServer::Context;
use MojoSimpleHTTPServer::SSIHandler::EP;
use MojoSimpleHTTPServer::SSIHandler::EPL;
use MojoSimpleHTTPServer::Stash;

    our $VERSION = '0.01';
    
    our $CONTEXT;

    __PACKAGE__->attr('x_powered_by' => 'Simple HTTP Server with Mojo(Perl)');
    __PACKAGE__->attr('under_development' => 0);
    __PACKAGE__->attr('document_root');
    __PACKAGE__->attr('default_file');
    __PACKAGE__->attr('log_file');
    __PACKAGE__->attr('hooks' => sub {MojoSimpleHTTPServer::Hooks->new});
    __PACKAGE__->attr('plugin_entry', sub {[]});
    __PACKAGE__->attr('roots', sub {[]});
    __PACKAGE__->attr('stash' => sub {MojoSimpleHTTPServer::Stash->new});
    __PACKAGE__->attr('types', sub { Mojolicious::Types->new });
    
    __PACKAGE__->attr('ssi_handlers', sub {{
        ep  => MojoSimpleHTTPServer::SSIHandler::EP->new,
        epl => MojoSimpleHTTPServer::SSIHandler::EPL->new,
    }});
    
    my %error_messages = (
        404 => 'File not found',
        500 => 'Internal server error',
        403 => 'Forbidden',
    );
    
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
    ### Accessor for localized context
    ### --
    sub context {
        if ($_[1]) {
            $CONTEXT = $_[1];
        }
        $CONTEXT;
    }
    
    ### --
    ### dispatch
    ### --
    sub dispatch {
        my ($self) = @_;
        
        my $tx = $CONTEXT->tx;
        my $res = $tx->res;
        my $path = $tx->req->url->path;
        
        if (! $res->code) {
            if ($tx->req->url =~ /$self->{_handler_re}/) {
                $self->serve_error_document(403);
                return;
            }
        }
        
        if (! $res->code) {
            my $filled_path = $self->default_file
                            ? $self->_auto_fill_filename($path->clone) : $path;
            $filled_path->leading_slash(1);
            
            for my $root (@{$self->roots}) {
                my $path = File::Spec->catfile($root. $filled_path);
                if (-f $path) {
                    $self->hooks->emit_chain('around_static', $path);
                } else {
                    $self->hooks->emit_chain('around_dynamic', $path);
                }
                if ($res->code) {
                    last;
                }
            }
        }
        
        if (! $res->code) {
            if (-d File::Spec->catfile($self->document_root. $path) && 
                        (! $path->trailing_slash && scalar @{$path->parts})) {
                $self->serve_redirect_to_slashed($path);
            }
        }
    }

    ### --
    ### handler
    ### --
    sub handler {
        my ($self, $tx) = @_;
        
        local $CONTEXT =
                    MojoSimpleHTTPServer::Context->new(app => $self, tx => $tx);
        
        $self->_init;
        
        $tx->res->headers->header('X-Powered-By' => $self->x_powered_by);

        eval {
            $self->hooks->emit_chain('around_dispatch');
        };
        
        if ($@) {
            $self->log->fatal("Processing request failed: $@");
            if ($self->under_development) {
                $self->serve_debug_screen($@);
            } else {
                $self->serve_error_document(500);
            }
        }
        
        if (! $tx->res->code) {
            $self->serve_error_document(404);
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
    ### Load and instanciate plugin
    ### --
    sub load_plugin {
        my ($self, $name, $args) = @_;
        
        my $prefix = 'MojoSimpleHTTPServer::Plugin';
        if ($prefix) {
            unless ($name =~ s/^\+// || $name =~ /^$prefix/) {
                $name = "$prefix\::$name";
            }
        }
        if (! $name->can('register')) {
            my $file = $name;
            $file =~ s!::!/!g;
            require "$file.pm"; ## no critic
        }
        return $name->new($args);
    }
    
    ### --
    ### Register plugin
    ### --
    sub plugin {
        my ($self, $class, @args) = @_;
        push(@{$self->plugin_entry}, $self->load_plugin($class, \@args));
    }
    
    ### --
    ### detect and render
    ### --
    sub render_ssi {
        my ($self, $path, $ext) = @_;
        $ext ||= ($path =~ qr{\.\w+\.(\w+)$})[0];
        if (my $handler = $self->ssi_handlers->{$ext}) {
            return $handler->render_traceable($path);
        }
    }
    
    ### --
    ### serve redirect to slashed directory
    ### --
    sub serve_redirect_to_slashed {
        my ($self, $path) = @_;
        
        my $uri =
            $CONTEXT->tx->req->url->clone->path(
                                    $path->clone->trailing_slash(1))->to_abs;
        return $self->serve_redirect($uri);
    }
    
    ### --
    ### serve redirect
    ### --
    sub serve_redirect {
        my ($self, $uri) = @_;
        
        my $tx = $CONTEXT->tx;
        $tx->res->code(301);
        $tx->res->headers->location($uri);
        return $self;
    }
    
    ### --
    ### serve error document
    ### --
    sub serve_debug_screen {
        my ($self, $exception) = @_;
        
        my $tx = $CONTEXT->tx;
        $CONTEXT->stash->(
            'mshs.static_dir' => 'static',
            'mshs.exception' => $exception
        );
        $tx->res->body(
            encode('UTF-8',
                MojoSimpleHTTPServer::SSIHandler::EP->new->render_traceable(
                                                _asset('debug_screen.ep'))));
        $tx->res->code(200);
        $tx->res->headers->content_type($self->types->type('html'));
        return $self;
    }
    
    ### --
    ### serve error document
    ### --
    sub serve_error_document {
        my ($self, $code, $message) = @_;
        
        my $tx = $CONTEXT->tx;
        $tx->res->body($message || ($code. ' '. $error_messages{$code}));
        $tx->res->code($code);
        $tx->res->headers->content_type($self->types->type('html'));
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
        my $tx = $CONTEXT->tx;
        
        for my $ext (keys %{$self->ssi_handlers}) {
            my $path = "$path.$ext";
            if (-f $path) {
                my $ret = $self->render_ssi($path, $ext);
                if (defined $ret) {
                    $tx->res->body(encode('UTF-8', $ret));
                    $tx->res->code(200);
                    if (my $type = $self->path_to_type($path)) {
                        $tx->res->headers->content_type($type);
                    }
                    last;
                }
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
        my ($self, $path) = @_;
        if ($path->trailing_slash || ! @{$path->parts}) {
            push(@{$path->parts}, $self->default_file);
            $path->trailing_slash(0);
        }
        return $path;
    }

    ### ---
    ### Asset directory
    ### ---
    sub _asset {
        my @seed = (substr(__FILE__, 0, -3), 'Asset');
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
        
        $self->roots([$self->document_root, _asset()]);

        $self->{_handler_re} =
                    '\.(?:'. join('|', keys %{$self->ssi_handlers}). ')$';
        
        if ($self->log_file) {
            $self->log->path($self->log_file);
        }
        
        ### Register plugins
        for my $plugin (@{$self->plugin_entry}) {
            $plugin->register($self, @{$plugin->config || []});
        }
    }
    
    ### --
    ### detect mimt type out of path name
    ### --
    sub path_to_type {
        my ($self, $path) = @_;
        if (my $ext = ($path =~ qr{\.(\w+)(?:\.\w+)?$})[0]) {
            return $self->types->type($ext);
        }
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer - Simple HTTP server with Server-side include

=head1 SYNOPSIS
    
    #!/usr/bin/env perl
    use strict;
    use warnings;
    
    use File::Basename 'dirname';
    use File::Spec;
    use lib join '/', File::Spec->splitdir(dirname(__FILE__)), 'lib';
    
    use MojoSimpleHTTPServer;
    
    my $app = MojoSimpleHTTPServer->new;
    $app->document_root($app->home->rel_dir('public_html'));
    $app->start;

=head1 DESCRIPTION

MojoSimpleHTTPServer is a simple web server base class. The module also is a
backend of 'mojo SimpleHTTPServer', a command line tool.
This is built on mojo modules in L<Mojolicious> distribution. 

=head1 ATTRIBUTES

=head2 document_root

=head2 default_file

Specify a default file name and activate auto fill.

=head2 log_file

Specify a log file path.

=head2 ssi_handlers

An hash ref that contains Server side include handlers.

=head2 Hooks

A MojoSimpleHTTPServer::Hooks instance.

=head2 stash

An MojoSimpleHTTPServer::Stash instance.

=head2 types

Contains L<Mojolicious::Type> instance.

=head2 under_development

Activate debug screen.

=head2 x_powered_by

Set X-POWERED-BY response header.

=head1 METHODS

=head2 $instance->new;

Constructor.

=head2 $instance->add_handler(name => $code_ref);

Adds ssi_handlers entry.

    $instance->add_handler(ep => MojoSimpleHTTPServer::SSIHandler::EP->new);

=head2 $instance->context()

Returns current context

=head2 $instance->dispatch()

Front dispatcher.

=head2 $instance->handler($tx)

Handler called by mojo layer.

=head2 $instance->hook

Alias to $instance->hooks->on. This adds a callback for the hook point.

    $app->hook(around_dispatch => sub {
        my ($next, @args) = @_;
        ### pre-process
        $next->(@args);
        ### post-process
    });

=head2 $instance->load_plugin(name => {})

Loads plugin of given name with given arguments.

=head2 $instance->plugin('class', @args)

=head2 $instance->path_to_type($path)

Detect MIME type out of path name.

=head2 $instance->render_ssi($path, $ext)

=head2 $instance->serve_redirect_to_slashed($path)

Serves response that redirects to trailing slashed URI.

=head2 $instance->serve_redirect($uri)

Serves response that redirects to given URI.

=head2 $instance->serve_error_document($code, $message)

Serves error document with given status code and message.

=head2 $instance->serve_static($path)

Serves static file of given path.

=head2 $instance->serve_debug_screen($exception)

Serves debug screen with given L<Mojo::Exception> instance.

=head2 $instance->serve_dynamic($path)

Serves dynamic SSI page with given file path.

=head2 $instance->serve_index($path)

Serves auto index page.

=head2 $instance->start()

Starts app

=head2 $instance->tx()

Returns current tx

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

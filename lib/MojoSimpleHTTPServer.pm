package MojoSimpleHTTPServer;
use strict;
use warnings;
use Mojo::Base 'Mojo';
use Data::Dumper;
use File::Spec;
use File::Basename 'dirname';
use Mojo::Path;
use Mojo::Asset::File;
use Mojo::Util qw'url_unescape encode decode';
use Mojolicious::Types;
use Mojolicious::Commands;
use MojoSimpleHTTPServer::Helper;
use MojoSimpleHTTPServer::Context;
use MojoSimpleHTTPServer::TemplateHandler::EP;
use MojoSimpleHTTPServer::TemplateHandler::EPL;

    our $VERSION = '0.01';
    
    our $CONTEXT;

    __PACKAGE__->attr('under_development' => 0);
    __PACKAGE__->attr('auto_index');
    __PACKAGE__->attr('document_root');
    __PACKAGE__->attr('default_file');
    
    __PACKAGE__->attr('helper' => sub {
        MojoSimpleHTTPServer::Helper->new->load_preset;
    });
    
    __PACKAGE__->attr('inited');
    __PACKAGE__->attr('log_file');
    
    __PACKAGE__->attr('template_handlers', sub {{
        ep  => MojoSimpleHTTPServer::TemplateHandler::EP->new,
        epl => MojoSimpleHTTPServer::TemplateHandler::EPL->new,
    }});

    __PACKAGE__->attr('types', sub { Mojolicious::Types->new });
    
    my %error_messages = (
        404 => 'File not found',
        500 => 'Internal server error',
        403 => 'Forbidden',
    );
    
    ### --
    ### Add template handler
    ### --
    sub add_handler {
        my ($self, $name, $handler) = @_;
        $self->template_handlers->{$name} = $handler;
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
        
        if ($tx->req->url =~ /$self->{_handler_re}/) {
            $self->serve_error_document(403);
        } else {
            my $res = $tx->res;
            my $path = $tx->req->url->path;
            my $filled_path =
                $self->default_file
                            ? $self->_auto_fill_filename($path->clone) : $path;
            $filled_path->leading_slash(1);
            
            if (my $type = $self->path_to_type($filled_path)) {
                $res->headers->content_type($type);
            }
            
            for my $root ($self->document_root, _asset()) {
                my $path = File::Spec->catfile($root. $filled_path);
                if (-f $path) {
                    $self->serve_static($path);
                } else {
                    $self->serve_dynamic($path);
                }
                if ($res->code) {
                    last;
                }
            }
            
            if (! $res->code &&
                        -d File::Spec->catfile($self->document_root. $path)) {
                if (! $path->trailing_slash && scalar @{$path->parts}) {
                    $self->serve_redirect_to_slashed($path);
                } elsif ($self->auto_index) {
                    $self->serve_index($path);
                }
            }
            
            if (! $res->code) {
                $self->serve_error_document(404);
                $self->log->fatal($tx->req->url->path. qq{ Not found});
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
        
        $self->init;
        
        eval {
            $self->dispatch;
        };
        
        if ($@) {
            $self->log->fatal("Processing request failed: $@");
            if ($self->under_development) {
                $self->serve_debug_screen($@);
            } else {
                $self->serve_error_document(500);
            }
        }
        
        $tx->resume;
    }
    
    ### --
    ### init
    ### --
    sub init {
        my $self = shift;
        
        if ($self->inited) {
            return;
        }
        $self->inited(1);
        
        if (! -d $self->document_root) {
            die 'document_root is not a directory';
        }
        
        $self->{_handler_re} =
                    '\.(?:'. join('|', keys %{$self->template_handlers}). ')$';
        
        if ($self->log_file) {
            $self->log->path($self->log_file);
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
        my ($self, $message) = @_;
        
        my $tx = $CONTEXT->tx;
        $tx->res->body($message);
        $tx->res->code(200);
        $tx->res->headers->content_type('text/plain');
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
        
        return $self;
    }
    
    ### --
    ### serve dynamic content
    ### --
    sub serve_dynamic {
        my ($self, $path) = @_;
        
        for my $ext (keys %{$self->template_handlers}) {
            my $handler = $self->template_handlers->{$ext};
            my $path = "$path.$ext";
            if (-f $path && $handler) {
                my $tx = $CONTEXT->tx;
                $tx->res->body(
                            encode('UTF-8', $handler->render($path)));
                $tx->res->code(200);
            }
        }
    }
    
    ### ---
    ### Render file list
    ### ---
    sub serve_index {
        my ($self, $path) = @_;
        
        $path = decode('UTF-8', url_unescape($path));
        my $dir = File::Spec->catfile($self->document_root, $path);
        
        opendir(my $DIR, $dir);
        my @file = readdir($DIR);
        closedir $DIR;
        
        my @dset = ();
        for my $file (@file) {
            $file = url_unescape(decode('UTF-8', $file));
            if ($file =~ qr{^\.$} || $file =~ qr{^\.\.$} && $path eq '/') {
                next;
            }
            my $fpath = File::Spec->catfile($dir, $file);
            my $name;
            my $type;
            if (-f $fpath) {
                $name = $file;
                $name =~ s{(\.\w+)$self->{_handler_re}}{$1};
                $type = (($self->path_to_type($name) || 'text') =~ /^(\w+)/)[0];
            } else {
                $name = $file. '/';
                $type = 'dir';
            }
            push(@dset, {
                name        => $name,
                type        => $type,
                timestamp   => _file_timestamp($fpath),
                size        => _file_size($fpath),
            });
        }
        
        @dset = sort {
            ($a->{type} ne 'dir') <=> ($b->{type} ne 'dir')
            ||
            $a->{name} cmp $b->{name}
        } @dset;
        
        my $tx = $CONTEXT->tx;
        $self->stash(
            dir         => $path,
            dataset     => \@dset,
            static_dir  => 'static'
        );
        
        $tx->res->body(
            encode('UTF-8',
                MojoSimpleHTTPServer::TemplateHandler::EPL->new->render(
                                                        _asset('index.epl')))
        );
        $tx->res->code(200);
        $tx->res->headers->content_type($self->types->type('html'));
        
        return $self;
    }
    
    ### --
    ### start app
    ### --
    sub start {
        my $self = $ENV{MOJO_APP} = shift;
        $self->init;
        Mojolicious::Commands->start;
    }
    
    ### --
    ### stash
    ### --
    sub stash {
        my $self = shift;
      
        # Hash
        my $stash = $self->{stash} ||= {};
        return $stash unless @_;
        
        # Get
        return $stash->{$_[0]} unless @_ > 1 || ref $_[0];
      
        # Set
        my $values = ref $_[0] ? $_[0] : {@_};
        for my $key (keys %$values) {
            $stash->{$key} = $values->{$key};
        }
      
        return $self;
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
    
    ### ---
    ### Get file utime
    ### ---
    sub _file_timestamp {
        my $path = shift;
        my @dt = localtime((stat($path))[9]);
        return sprintf('%d-%02d-%02d %02d:%02d',
                            1900 + $dt[5], $dt[4] + 1, $dt[3], $dt[2], $dt[1]);
    }
    
    ### --
    ### detect mimt type out of path name
    ### --
    sub path_to_type {
        my ($self, $path) = @_;
        if (my $ext = ($path =~ qr{\.(\w+)$})[0]) {
            return $self->types->type($ext);
        }
    }
    
    ### ---
    ### Get file size
    ### ---
    sub _file_size {
        my $path = shift;
        return ((stat($path))[7] > 1024)
            ? sprintf("%.1f",(stat($path))[7] / 1024) . 'KB'
            : (stat($path))[7]. 'B';
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
    $app->auto_index(1);
    $app->start;

=head1 DESCRIPTION

MojoSimpleHTTPServer is a simple web server base class. The module also is a
backend of 'mojo SimpleHTTPServer', a command line tool.
This is built on mojo modules in L<Mojolicious> distribution. 

=head1 ATTRIBUTES

=head2 document_root

=head2 auto_index

=head2 default_file

=head2 inited

=head2 log_file

=head2 template_handlers

=head1 METHODS

=head2 $instance->add_handler(name => $code_ref);

Adds handlers for template rendering.

    $instance->add_handler(ep => MojoSimpleHTTPServer::TemplateHandler::EP->new);

=head2 $instance->context()

Returns current context

=head2 $instance->dispatch()

=head2 $instance->handler($tx)

=head2 $instance->init()

=head2 $instance->path_to_type($path)

=head2 $instance->serve_redirect_to_slashed($path)

=head2 $instance->serve_redirect($uri)

=head2 $instance->serve_error_document($code, $message)

=head2 $instance->serve_static($path)

=head2 $instance->serve_dynamic($path)

=head2 $instance->serve_index($path)

=head2 $instance->stash($key => $value)

Generates file index for response and set to tx

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

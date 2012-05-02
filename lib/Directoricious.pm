package Directoricious;
use Mojo::Base 'Mojo';
use Data::Dumper;
use File::Spec;
use File::Basename 'dirname';
use Mojo::Path;
use Mojo::Asset::File;
use Mojo::Util qw'url_unescape encode decode';
use Mojolicious::Types;
use Mojolicious::Commands;

    our $tx;
    
    __PACKAGE__->attr('document_root');
    __PACKAGE__->attr('auto_index');
    __PACKAGE__->attr('default_file');
    __PACKAGE__->attr('inited');
    __PACKAGE__->attr('log_file');
    __PACKAGE__->attr('template_handlers', sub {{
        ep => \&handle_ep,
    }});

    my $types = Mojolicious::Types->new;
    
    my %error_messages = (
        404 => 'File not found',
        500 => 'Internal server error',
        403 => 'Forbidden',
    );
    
    ### --
    ### dispatch
    ### --
    sub dispatch {
        my ($self) = @_;
        
        if ($tx->req->url =~ /$self->{_handler_re}/) {
            $self->serve_error_document(403);
        } else {
            my $res = $tx->res;
            my $path = $tx->req->url->path;
            my $filled_path = $self->_auto_fill_filename($path->clone);
            
            if (my $type = $self->mime_type($filled_path)) {
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
                if (substr($path, -1, 1) ne '/') {
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
        (my $self, local $tx) = @_;
        
        $self->init;
        
        eval {
            $self->dispatch;
        };
        
        if ($@) {
            $self->log->fatal("Processing request failed: $@");
            $tx->res->code(500);
        }
        $tx->resume;
    }
    
    ### --
    ### ep handler
    ### --
    sub handle_ep {
        my ($path, $args) = @_;
        
        my $mt = Mojo::Template->new;
        my $prepend = 'use strict;';
        $prepend .= 'my $_S = $_[0];';
        for my $var (keys %{$args}) {
            if ($var =~ /^\w+$/) {
                $prepend .= " my \$$var = \$_S->{'$var'};";
            }
        }
        $mt->prepend($prepend);
        $mt->render_file($path, $args);
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
    ### detect mimt type out of path name
    ### --
    sub mime_type {
        my ($self, $path) = @_;
        if (my $ext = ($path =~ qr{\.(\w+)$})[0]) {
            return $types->type($ext);
        }
    }
    
    ### --
    ### serve redirect to slashed directory
    ### --
    sub serve_redirect_to_slashed {
        my ($self, $path) = @_;
        my $uri =
            $tx->req->url->clone->path($path->clone->trailing_slash(1))->to_abs;
        return $self->serve_redirect($uri);
    }
    
    ### --
    ### serve redirect
    ### --
    sub serve_redirect {
        my ($self, $uri) = @_;
        $tx->res->code(301);
        $tx->res->headers->location($uri);
        return $tx;
    }
    
    ### --
    ### serve error document
    ### --
    sub serve_error_document {
        my ($self, $code, $message) = @_;
        $tx->res->body($message || ($code. ' '. $error_messages{$code}));
        $tx->res->code($code);
        $tx->res->headers->content_type($types->type('html'));
        return $tx;
    }
    
    ### --
    ### serve static content
    ### --
    sub serve_static {
        my ($self, $path) = @_;
        
        my $asset = Mojo::Asset::File->new(path => $path);
        my $modified = (stat $path)[9];
        
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
        
        return $tx;
    }
    
    ### --
    ### serve dynamic content
    ### --
    sub serve_dynamic {
        my ($self, $path) = @_;
        
        # dynamic dispatch
        for my $ext (keys %{$self->template_handlers}) {
            my $cb = $self->template_handlers->{$ext};
            my $path = "$path.$ext";
            if (-f $path && $cb) {
                $tx->res->body(encode('UTF-8', $cb->($path, $self->{stash})));
                $tx->res->code(200);
                return $tx->resume;
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
                $type = (split('/', Mojolicious::Types->type(($name =~ qr{\.(\w+)$}) ? $1 : '') || 'text/plain'))[0];
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
        
        $tx->res->body(
            encode('UTF-8', handle_ep(_asset('index.ep'), {
                dir         => $path,
                dataset     => \@dset,
                static_dir  => 'static'
            }))
        );
        $tx->res->code(200);
        $tx->res->headers->content_type($types->type('html'));
        
        return $tx;
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
    ### start app
    ### --
    sub start {
        my $self = $ENV{MOJO_APP} = shift;
        $self->init;
        Mojolicious::Commands->start;
    }
    
    ### --
    ### transaction
    ### --
    sub tx {
        $tx;
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
        return sprintf('%d-%02d-%02d %02d:%02d', 1900 + $dt[5], $dt[4] + 1, $dt[3], $dt[2], $dt[1]);
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

Directoricious - Simple HTTP server with Server-side include

=head1 SYNOPSIS
    
    #!/usr/bin/env perl
    use strict;
    use warnings;
    
    use File::Basename 'dirname';
    use File::Spec;
    use lib join '/', File::Spec->splitdir(dirname(__FILE__)), 'lib';
    
    use Directoricious;
    
    my $my_app = Directoricious->new;
    $my_app->document_root($my_app->home->rel_dir('public_html'));
    $my_app->auto_index(1);
    $my_app->start;

=head1 DESCRIPTION

=head1 METHODS

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

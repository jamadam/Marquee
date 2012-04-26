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

    __PACKAGE__->attr('document_root');
    __PACKAGE__->attr('auto_index', 0);
    __PACKAGE__->attr('default_file', 'index.html');
    
    __PACKAGE__->attr('template_handlers', sub {{
        ep => sub {Mojo::Template->new->render_file($_[0])},
    }});
    
    my $types = Mojolicious::Types->new;
    
    my %error_messages = (
        404 => 'File not found',
        500 => 'Internal server error',
        403 => 'Forbidden',
    );
    
    ### --
    ### handler
    ### --
    sub handler {
        my ($self, $tx) = @_;
        
        if (! -d $self->document_root) {
            die 'document_root is not a directory';
        }
        
        $self->{_handler_re} =
                    '\.(?:'. join('|', keys %{$self->template_handlers}). ')$';
        
        if ($tx->req->url =~ /$self->{_handler_re}/) {
            $self->serve_error_document($tx, 403);
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
                    $self->serve_static($tx, $path);
                } else {
                    $self->serve_dynamic($tx, $path);
                }
                if ($res->code) {
                    last;
                }
            }
            
            if (! $res->code) {
                my $dir = File::Spec->catfile($self->document_root. $path);
                if (-d $dir) {
                    if (substr($path, -1, 1) ne '/') {
                        $self->serve_redirect_to_slashed($tx, $path);
                    } elsif ($self->auto_index) {
                        $self->serve_index($tx, $path);
                    }
                }
            }
            
            if (! $res->code) {
                $self->serve_error_document($tx, 404);
            }
        }
        
        return $tx->resume;
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
        my ($self, $tx, $path) = @_;
        my $uri =
            $tx->req->url->clone->path($path->clone->trailing_slash(1))->to_abs;
        return $self->serve_redirect($tx, $uri);
    }
    
    ### --
    ### serve redirect
    ### --
    sub serve_redirect {
        my ($self, $tx, $uri) = @_;
        $tx->res->code(301);
        $tx->res->headers->location($uri);
        return $tx;
    }
    
    ### --
    ### serve error document
    ### --
    sub serve_error_document {
        my ($self, $tx, $code, $message) = @_;
        $tx->res->body($message || ($code. ' '. $error_messages{$code}));
        $tx->res->code($code);
        $tx->res->headers->content_type($types->type('html'));
        return $tx;
    }
    
    ### --
    ### serve static content
    ### --
    sub serve_static {
        my ($self, $tx, $path) = @_;
        
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
        my ($self, $tx, $path) = @_;
        
        # dynamic dispatch
        while (my ($ext, $cb) = each %{$self->template_handlers}) {
            my $path = "$path.$ext";
            if (-f $path && $cb) {
                $tx->res->body(encode('UTF-8', $cb->($path)));
                $tx->res->code(200);
                return $tx->resume;
            }
        }
    }
    
    ### ---
    ### Render file list
    ### ---
    sub serve_index {
        my ($self, $tx, $path) = @_;
        
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
            push(@dset, {
                name        => -f $fpath ? $self->_strip_template_ext($file) : $file. '/',
                timestamp   => _file_timestamp($fpath),
                size        => _file_size($fpath),
                type        => -f $fpath ? _file_to_mime_class($file) : 'dir',
            });
        }
        
        @dset = sort {
            ($a->{type} ne 'dir') <=> ($b->{type} ne 'dir')
            ||
            $a->{name} cmp $b->{name}
        } @dset;
        
        my $mt = Mojo::Template->new;
        my $body = $mt->render_file(_asset('index.ep'), $path, \@dset, 'static');
        $tx->res->body(encode('UTF-8', $body));
        $tx->res->code(200);
        $tx->res->headers->content_type($types->type('html'));
        
        return $tx;
    }
    
    ### --
    ### start app
    ### --
    sub start {
        Mojolicious::Commands->start_app($_[0]);
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
    ### handler
    ### --
    sub _strip_template_ext {
        my ($self, $file) = @_;
        $file =~ s/$self->{_handler_re}//;
        return $file;
    }
    
    ### ---
    ### Guess type by file extension
    ### ---
    sub _file_to_mime_class {
        my $name = shift;
        my $ext = ($name =~ qr{\.(\w+)$}) ? $1 : '';
        return (split('/', Mojolicious::Types->type($ext) || 'text/plain'))[0];
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

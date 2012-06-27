package Marquee::Plugin::AutoIndex;
use strict;
use warnings;
use Mojo::Base 'Marquee::Plugin';
use Mojo::Util qw'url_unescape encode decode';
    
    ### --
    ### Register the plugin into app
    ### --
    sub register {
        my ($self, $app, $args) = @_;
        
        ### Add mime types
        {
            my $types = $app->types;
            my %catalog = mime_types();
            while (my ($ext, $mime) = (each %catalog)) {
                if (! $types->type($ext)) {
                    $types->type($ext => $mime);
                }
            }
        }
        
        push(@{$app->roots}, __PACKAGE__->Marquee::asset());
        
        $app->hook(around_dispatch => sub {
            my ($next, @args) = @_;
            
            $next->();
            
            my $c = Marquee->c;
            
            if (! $c->served) {
                my $app = $c->app;
                my $path = $c->tx->req->url->path->clone->canonicalize;
                if (@{$path->parts}[0] && @{$path->parts}[0] eq '..') {
                    return;
                }
                my $mode = $c->tx->req->param('mode');
                if ($mode && $mode eq 'tree') {
                    $self->_serve_tree($path);
                } elsif (-d File::Spec->catdir($app->document_root, $path)) {
                    $self->_serve_index($path);
                }
            }
        });
    }
    
    ### ---
    ### Server directory tree
    ### ---
    sub _serve_tree {
        my ($self, $path) = @_;
        
        my $c   = Marquee->c;
        my $tx  = Marquee->c->tx;
        my $app = Marquee->c->app;
        my $maxdepth = 3;
        
        $c->stash->set(
            dir         => $path,
            static_dir  => 'static'
        );
        
        $tx->res->body(
            encode('UTF-8',
                Marquee::SSIHandler::EP->new->add_function(filelist => sub {
                    my ($self, $cpath) = @_;
                    
                    $cpath ||= $path;
                    $cpath =~ s{/$}{};
                    $cpath = decode('UTF-8', url_unescape($cpath));
                    my $fixed_path =
                            File::Spec->catfile($app->document_root, $cpath);
                    opendir(my $dh, $fixed_path);
                    my @files =
                        map {
                            my $name = $_;
                            $name =~ s{(\.\w+)$app->{_handler_re}}{$1};
                            [
                                -d File::Spec->catfile($fixed_path, $name),
                                File::Spec->catfile($cpath, $name),
                            ]
                        } sort {$a cmp $b} grep {$_ !~ qr/^\./} readdir($dh);
                    closedir($dh);
                    return \@files;
                })->render_traceable(
                __PACKAGE__->Marquee::asset('auto_index_tree.html.ep')
                )
            )
        );
        
        $tx->res->code(200);
        $tx->res->headers->content_type($app->types->type('html'));
        
        return $app;
    }
    
    ### ---
    ### Render file list
    ### ---
    sub _serve_index {
        my ($self, $path) = @_;
        
        my $c = Marquee->c;
        my $app = $c->app;
        
        $path = decode('UTF-8', url_unescape($path));
        my $dir = File::Spec->catdir($app->document_root, $path);
        
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
                $name =~ s{(\.\w+)$app->{_handler_re}}{$1};
                $type = (($app->path_to_type($name) || 'text') =~ /^(\w+)/)[0];
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
        
        my $tx = $c->tx;
        $c->stash->set(
            dir         => $path,
            dataset     => \@dset,
            static_dir  => 'static'
        );
        
        $tx->res->body(
            encode('UTF-8',
                Marquee::SSIHandler::EP->new->render_traceable(
                __PACKAGE__->Marquee::asset('auto_index.html.ep')
                )
            )
        );
        $tx->res->code(200);
        $tx->res->headers->content_type($app->types->type('html'));
        
        return $app;
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
    
    ### ---
    ### Get file size
    ### ---
    sub _file_size {
        my $path = shift;
        return ((stat($path))[7] > 1024)
            ? sprintf("%.1f",(stat($path))[7] / 1024) . 'KB'
            : (stat($path))[7]. 'B';
    }
    
    ### ---
    ### Mime type catalog
    ### ---
    sub mime_types {
        return (
            "3gp"     => "video/3gpp",
            "a"       => "application/octet-stream",
            "ai"      => "application/postscript",
            "aif"     => "audio/x-aiff",
            "aiff"    => "audio/x-aiff",
            "asc"     => "application/pgp-signature",
            "asf"     => "video/x-ms-asf",
            "asm"     => "text/x-asm",
            "asx"     => "video/x-ms-asf",
            "atom"    => "application/atom+xml",
            "au"      => "audio/basic",
            "avi"     => "video/x-msvideo",
            "bat"     => "application/x-msdownload",
            "bin"     => "application/octet-stream",
            "bmp"     => "image/bmp",
            "bz2"     => "application/x-bzip2",
            "c"       => "text/x-c",
            "cab"     => "application/vnd.ms-cab-compressed",
            "cc"      => "text/x-c",
            "chm"     => "application/vnd.ms-htmlhelp",
            "class"   => "application/octet-stream",
            "com"     => "application/x-msdownload",
            "conf"    => "text/plain",
            "cpp"     => "text/x-c",
            "crt"     => "application/x-x509-ca-cert",
            "css"     => "text/css",
            "csv"     => "text/csv",
            "cxx"     => "text/x-c",
            "deb"     => "application/x-debian-package",
            "der"     => "application/x-x509-ca-cert",
            "diff"    => "text/x-diff",
            "djv"     => "image/vnd.djvu",
            "djvu"    => "image/vnd.djvu",
            "dll"     => "application/x-msdownload",
            "dmg"     => "application/octet-stream",
            "doc"     => "application/msword",
            "dot"     => "application/msword",
            "dtd"     => "application/xml-dtd",
            "dvi"     => "application/x-dvi",
            "ear"     => "application/java-archive",
            "eml"     => "message/rfc822",
            "eps"     => "application/postscript",
            "exe"     => "application/x-msdownload",
            "f"       => "text/x-fortran",
            "f77"     => "text/x-fortran",
            "f90"     => "text/x-fortran",
            "flv"     => "video/x-flv",
            "for"     => "text/x-fortran",
            "gem"     => "application/octet-stream",
            "gemspec" => "text/x-script.ruby",
            "gif"     => "image/gif",
            "gz"      => "application/x-gzip",
            "h"       => "text/x-c",
            "hh"      => "text/x-c",
            "htm"     => "text/html",
            "html"    => "text/html",
            "ico"     => "image/vnd.microsoft.icon",
            "ics"     => "text/calendar",
            "ifb"     => "text/calendar",
            "iso"     => "application/octet-stream",
            "jar"     => "application/java-archive",
            "java"    => "text/x-java-source",
            "jnlp"    => "application/x-java-jnlp-file",
            "jpeg"    => "image/jpeg",
            "jpg"     => "image/jpeg",
            "js"      => "application/javascript",
            "json"    => "application/json",
            "log"     => "text/plain",
            "m3u"     => "audio/x-mpegurl",
            "m4v"     => "video/mp4",
            "man"     => "text/troff",
            "manifest"=> "text/cache-manifest",
            "mathml"  => "application/mathml+xml",
            "mbox"    => "application/mbox",
            "mdoc"    => "text/troff",
            "me"      => "text/troff",
            "mid"     => "audio/midi",
            "midi"    => "audio/midi",
            "mime"    => "message/rfc822",
            "mml"     => "application/mathml+xml",
            "mng"     => "video/x-mng",
            "mov"     => "video/quicktime",
            "mp3"     => "audio/mpeg",
            "mp4"     => "video/mp4",
            "mp4v"    => "video/mp4",
            "mpeg"    => "video/mpeg",
            "mpg"     => "video/mpeg",
            "ms"      => "text/troff",
            "msi"     => "application/x-msdownload",
            "odp"     => "application/vnd.oasis.opendocument.presentation",
            "ods"     => "application/vnd.oasis.opendocument.spreadsheet",
            "odt"     => "application/vnd.oasis.opendocument.text",
            "ogg"     => "application/ogg",
            "ogv"     => "video/ogg",
            "p"       => "text/x-pascal",
            "pas"     => "text/x-pascal",
            "pbm"     => "image/x-portable-bitmap",
            "pdf"     => "application/pdf",
            "pem"     => "application/x-x509-ca-cert",
            "pgm"     => "image/x-portable-graymap",
            "pgp"     => "application/pgp-encrypted",
            "pkg"     => "application/octet-stream",
            "pl"      => "text/x-script.perl",
            "pm"      => "text/x-script.perl-module",
            "png"     => "image/png",
            "pnm"     => "image/x-portable-anymap",
            "ppm"     => "image/x-portable-pixmap",
            "pps"     => "application/vnd.ms-powerpoint",
            "ppt"     => "application/vnd.ms-powerpoint",
            "ps"      => "application/postscript",
            "psd"     => "image/vnd.adobe.photoshop",
            "py"      => "text/x-script.python",
            "qt"      => "video/quicktime",
            "ra"      => "audio/x-pn-realaudio",
            "rake"    => "text/x-script.ruby",
            "ram"     => "audio/x-pn-realaudio",
            "rar"     => "application/x-rar-compressed",
            "rb"      => "text/x-script.ruby",
            "rdf"     => "application/rdf+xml",
            "roff"    => "text/troff",
            "rpm"     => "application/x-redhat-package-manager",
            "rss"     => "application/rss+xml",
            "rtf"     => "application/rtf",
            "ru"      => "text/x-script.ruby",
            "s"       => "text/x-asm",
            "sgm"     => "text/sgml",
            "sgml"    => "text/sgml",
            "sh"      => "application/x-sh",
            "sig"     => "application/pgp-signature",
            "snd"     => "audio/basic",
            "so"      => "application/octet-stream",
            "svg"     => "image/svg+xml",
            "svgz"    => "image/svg+xml",
            "swf"     => "application/x-shockwave-flash",
            "t"       => "text/troff",
            "tar"     => "application/x-tar",
            "tbz"     => "application/x-bzip-compressed-tar",
            "tcl"     => "application/x-tcl",
            "tex"     => "application/x-tex",
            "texi"    => "application/x-texinfo",
            "texinfo" => "application/x-texinfo",
            "text"    => "text/plain",
            "tif"     => "image/tiff",
            "tiff"    => "image/tiff",
            "torrent" => "application/x-bittorrent",
            "tr"      => "text/troff",
            "txt"     => "text/plain",
            "vcf"     => "text/x-vcard",
            "vcs"     => "text/x-vcalendar",
            "vrml"    => "model/vrml",
            "war"     => "application/java-archive",
            "wav"     => "audio/x-wav",
            "wma"     => "audio/x-ms-wma",
            "wmv"     => "video/x-ms-wmv",
            "wmx"     => "video/x-ms-wmx",
            "wrl"     => "model/vrml",
            "wsdl"    => "application/wsdl+xml",
            "xbm"     => "image/x-xbitmap",
            "xhtml"   => "application/xhtml+xml",
            "xls"     => "application/vnd.ms-excel",
            "xml"     => "application/xml",
            "xpm"     => "image/x-xpixmap",
            "xsl"     => "application/xml",
            "xslt"    => "application/xslt+xml",
            "yaml"    => "text/yaml",
            "yml"     => "text/yaml",
            "zip"     => "application/zip",
        );
    }

1;

__END__

=head1 NAME

Marquee::Plugin::AutoIndex - Auto index

=head1 SYNOPSIS

    $app->plugin('AutoIndex');

=head1 DESCRIPTION

This is a plugin for auto index. When app attribute default_file is undefined
or the file is not found, the directory access causes the auto index to be
served.

=head1 METHODS

=head2 $instance->register($app, $hash_ref)

=head2 $instance->mime_types()

Returns common MIME types.

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

package Marquee::Plugin::Scss;
use strict;
use warnings;
use Mojo::Base 'Marquee::Plugin';
use feature 'signatures';
no warnings "experimental::signatures";
use IPC::Open3 qw(open3);
use Carp ();
use CSS::Sass;

my $text_sass;

has 'scss';

### --
### Register the plugin into app
### --
sub register($self, $app) {
    
    if (`which sass`) {
        my $version = `sass -v`;
        if ($version  && $version =~ /Sass 3/) {
            $self->scss(\&scss_command);
        }
    }
    if (! $self->scss && eval { require CSS::Sass }) {
        $self->scss(\&scss_perl);
    }
    if (! $self->scss) {
        Carp::croak("Can't find sass gem nor CSS::Sass module");
    }
    
    $app->hook(around_dispatch => sub($next) {
        
        $next->();
        
        my $c = Marquee->c;
        
        if (!$c->served && (my $path = $c->req->url->path) =~ m{\.css$}) {
            my $res = $c->res;
            $path =~ s/\.css$/.scss/i;
            $c->req->url->path($path);
            $next->();
            if ($c->served) {
                my $css = $self->scss->($res->body);
                $res->code(200);
                $res->body($css);
                $res->headers->content_type('text/css');
            }
        }
    });
}

sub scss_command($body) {

    my $pid = open3(my $in, my $out, my $err, "sass", "--stdin", '--scss');
    print $in $body;
    close $in;

    my $buf = join '', <$out>;
    waitpid $pid, 0;

    return $buf;
}

sub scss_perl($scss) {
    $text_sass ||= CSS::Sass->new;
    $text_sass->scss2css($scss);
}

1;

__END__

=head1 NAME

Marquee::Plugin::Sass - Serve CSS out of SASS

=head1 SYNOPSIS
    
    $app->plugin('Sass');

=head1 DESCRIPTION

=head1 INSTANCE METHODS

=head2 register

Register the plugin.

    $self->register($app);

=head1 SEE ALSO

L<Marquee::Plugin>, L<Marquee>, L<Mojolicious>

=cut

package Marquee::Plugin::Router;
use strict;
use warnings;
use Marquee::Plugin::Router::Route;
use Mojo::Base 'Marquee::Plugin';

__PACKAGE__->attr('route', sub {Marquee::Plugin::Router::Route->new});

### --
### Register the plugin into app
### --
sub register {
    my ($self, $app, $generator) = @_;
    
    $generator->($self->route);
    
    $app->hook(around_dispatch => sub {
        my ($next, @args) = @_;
        
        my $c       = Marquee->c;
        my $path    = $c->req->url->path->clone->leading_slash(1)->to_string;
        
        for my $elem (@{$self->route->elems}) {
            my ($regex, $cond, $cb) = @$elem;
            map {$_->($c) || next} @$cond;
            if (my @captures = ($path =~ $regex)) {
                $cb->(defined $1 ? @captures : ());
                last;
            }
        }
        
        if (! $c->served) {
            $next->(@args);
        }
    });
}

1;

__END__

=head1 NAME

Marquee::Plugin::Router - Router [EXPERIMENTAL]

=head1 SYNOPSIS
    
    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/index\.html})->to(sub {
            ### DO SOMETHING
        });
        $r->route(qr{^/special\.html})->to(sub {
            ### DO SOMETHING
        });
        $r->route(qr{^/capture/(.+)-(.+)\.html})->to(sub {
            my ($a, $b) = @_;
            ### DO SOMETHING
        });
        $r->route(qr{^/rare/})->via('get')->to(sub {
            ### DO SOMETHING
        });
        $r->route(qr{^/default})->to(sub {
            ### DO SOMETHING
        });
    });

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 route

L<Marquee::Plugin::Router::Route> instance.

=head1 METHODS

=head2 $instance->register($app, $routes)

=head1 SEE ALSO

L<Marquee::Plugin::Router::Route>, L<Marquee>,
L<Mojolicious>

=cut

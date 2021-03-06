package Marquee::Plugin::Router;
use strict;
use warnings;
use Marquee::Plugin::Router::Route;
use Mojo::Base 'Marquee::Plugin';
use feature 'signatures';
no warnings "experimental::signatures";

has route => sub {Marquee::Plugin::Router::Route->new};

### --
### Register the plugin into app
### --
sub register($self, $app, $generator) {
    
    $generator->($self->route);
    
    $app->hook(around_dispatch => sub($next) {
        
        my $c       = Marquee->c;
        my $path    = $c->req->url->path->clone->leading_slash(1)->to_string;
        
        for my $entry (@{$self->route->aggregate->data}) {
            my ($regex, $cond, $cb) = @$entry;
            map {$_->($c) || next} @$cond;
            if (my @captures = ($path =~ $regex)) {
                $cb->($#+ ? @captures : ());
                
                if (! $c->served) {
                    $c->app->log->warn("Route for $regex better serves some contents");
                }
                
                return;
            }
        }
        
        if (! $c->served) {
            $next->();
        }
    });
}

1;

__END__

=head1 NAME

Marquee::Plugin::Router - Router

=head1 SYNOPSIS
    
    $app->plugin(Router => sub($r) {
        $r->route(qr{^/index\.html})->to(sub($c) {
            my $c = Marquee->c;
            my $req = $c->tx->req;
            my $res = $c->tx->res;
            $res->code(200);
            $res->body('content');
            $res->headers->content_type('text/html');
        });
        
        $r->route(qr{^/special\.html})->to(sub($c) {
            ...
        });
        
        $r->route(qr{^/capture/(.+)-(.+)\.html})->to(sub($c) {
            my ($a, $b) = @_;
            ...
        });
        
        $r->route(qr{^/rare/})->via('get')->to(sub($c) {
            ...
        });
        
        $r->route(qr{^/rare/})->viax('post')->to(sub($c) {
            ...
        });
        
        $r->route(qr{^/default})->to(sub($c) {
            ...
        });
        
        my $bridge = $r->bridge(sub($c) {
            return 1; # or 0
        });
        
        $bridge->route(qr{})->to(sub() {...});
    });

=head1 DESCRIPTION

L<Marquee::Plugin::Router> plugin provides an ability to route requests to
certain actions.

=head1 ATTRIBUTES

L<Marquee::Plugin::Router> inherits all attributes from
L<Marquee::Plugin> and implements the following new ones.

=head2 C<route>

L<Marquee::Plugin::Router::Route> instance.

    $router->route(Marquee::Plugin::Router::Route->new);
    my $r = $router->route;

=head1 INSTANCE METHODS

L<Marquee::Plugin::Router> inherits all instance methods from
L<Marquee::Plugin> and implements the following new ones.

=head2 register

Register the plugin.

    $self->register($app, $generator);

=head1 SEE ALSO

L<Marquee::Plugin::Router::Route>, L<Marquee>,
L<Mojolicious>

=cut

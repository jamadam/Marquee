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
            my $c = Marquee->c;
            my $req = $c->tx->req;
            my $res = $c->tx->res;
            $res->code(200);
            $res->body('content');
            $res->headers->content_type('text/html');
        });
        
        $r->route(qr{^/special\.html})->to(sub {
            ...
        });
        
        $r->route(qr{^/capture/(.+)-(.+)\.html})->to(sub {
            my ($a, $b) = @_;
            ...
        });
        
        $r->route(qr{^/rare/})->via('get')->to(sub {
            ...
        });
        
        $r->route(qr{^/default})->to(sub {
            ...
        });
        
        my $bridge = $r->bridge(sub {
            return 1; # or 0
        });
        
        $bridge->route(qr{})->to(sub {...});
    });

=head1 DESCRIPTION

L<Marquee::Plugin::Router> plugin provides an ability to route requests to
certain actions.

=head1 ATTRIBUTES

L<Marquee::Plugin::Router> inherits all attributes from
L<Marquee::Plugin> and implements the following new ones.

=head2 C<route>

L<Marquee::Plugin::Router::Route> instance.

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

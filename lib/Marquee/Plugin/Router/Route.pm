package Marquee::Plugin::Router::Route;
use strict;
use warnings;
use Mojo::Base -base;

__PACKAGE__->attr('elems', sub {[]});

sub add_cond {
    my ($self, @conds) = @_;
    unshift(@{$self->elems->[-1]->[1]}, @conds);
    return $self;
}

sub bridge {
    my ($self, $cb) = @_;
    my $r = __PACKAGE__->new(bridge => $cb);
    $r->elems($self->elems);
    return $r;
}

sub route {
    my ($self, $regex) = @_;
    push(@{$self->elems}, [$regex, [], undef]);
    if ($self->{bridge}) {
        $self->add_cond($self->{bridge});
    }
    return $self;
}

sub to {
    my ($self, $cb) = @_;
    $self->elems->[-1]->[2] = $cb;
    return $self;
}

sub via {
    my ($self, @methods) = @_;
    return $self->add_cond(sub {
        my $c = shift;
        scalar grep {uc $_ eq uc $c->req->method} @methods;
    });
}

1;

__END__

=head1 NAME

Marquee::Plugin::Router - Route generator and container [EXPERIMENTAL]

=head1 SYNOPSIS
    
    my $r = Marquee::Plugin::Router::Route->new;
    $r->route(qr{^/index\.html})->to(sub {
        ...
    });
    
    $r->route(qr{^/special\.html})->to(sub {
        ...
    });
    
    $r->route(qr{^/capture/(.+)-(.+)\.html})->to(sub {
        my ($a, $b) = @_;
        ...
    });
    
    $r->route(qr{^/rare/})->via('GET', 'POST')->to(sub {
        ...
    });
    
    $r->route(qr{^/default})->to(sub {
        ...
    });
    
    my $bridge = $r->bridge(sub {
        return 1; # or 0
    });
    
    $bridge->route(qr{})->to(sub {...});

=head1 DESCRIPTION

L<Marquee::Plugin::Router> is a class for generating and storing routes.

=head1 ATTRIBUTES

L<Marquee::Plugin::Router> implements the following attributes.

=head2 elems

Route entries.

=head1 INSTANCE METHODS

L<Marquee::Plugin::Router> implements the following instance methods.

=head2 $instance->bridge(sub {...})

    my $bridge = $r->bridge(sub {
        my $context = shift;
        return $bool;
    });

=head2 $instance->route($regex)

Set a regex that matches to request URI.

    $r->route(qr{^/index\.html});

=head2 $instance->to($code_ref)

Set an action to invoke when the route matches.

    $r->to(sub {...});

=head2 $instance->via(@http_methods)

Filters route by HTTP method.

    $r->via('GET', 'POST');

=head2 $instance->add_cond(sub {})

Add condition for the route entry.

    $r->add_cond(sub {
        my $context = shift;
        return 1; # or 0
    });

=head1 SEE ALSO

L<Marquee::Plugin::Router>, L<Marquee>, L<Mojolicious>

=cut

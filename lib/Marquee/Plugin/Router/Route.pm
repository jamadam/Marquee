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
        my $tx = shift;
        scalar grep {uc $_ eq uc $tx->req->method} @methods;
    });
}

1;

__END__

=head1 NAME

Marquee::Plugin::Router - Router [EXPERIMENTAL]

=head1 SYNOPSIS
    
    my $r = Marquee::Plugin::Router::Route->new;
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
    $r->route(qr{^/rare/})->via('GET', 'POST')->to(sub {
        ### DO SOMETHING
    });
    $r->route(qr{^/default})->to(sub {
        ### DO SOMETHING
    });
    
    my $bridge = $r->bridge(sub {
        return 1; # or 0
    });
    
    $bridge->route(qr{});

=head1 DESCRIPTION

=head1 METHODS

=head2 $instance->bridge(sub {...})

    my $bridge = $r->bridge(sub {
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

=head2 $instance->add_condition(sub {})

Add condition for the route entry.

    $r->add_cond(sub {
        my $tx = shift;
        return 1; # or 0
    });

=head1 SEE ALSO

L<Marquee::Plugin::Router>, L<Marquee>, L<Mojolicious>

=cut

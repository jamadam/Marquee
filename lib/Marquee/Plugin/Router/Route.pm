package Marquee::Plugin::Router::Route;
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::Util 'deprecated';
use feature 'signatures';
no warnings "experimental::signatures";

has aggregate => sub {Marquee::Plugin::Router::Route::_Aggregate->new};

sub bridge($self, $cb) {
    my $r = __PACKAGE__->new(bridge => $cb);
    $r->aggregate($self->aggregate);
    return $r;
}

sub route($self, $regex) {
    $self->aggregate->add([$regex]);
    if ($self->{bridge}) {
        unshift(@{$self->aggregate->current->[1]}, $self->{bridge});
    }
    return $self;
}

sub to($self, $cb) {
    $self->aggregate->current->[2] = $cb;
    return $self;
}

sub via($self, @methods) {
    unshift(@{$self->aggregate->current->[1]}, sub($c) {
        return !! scalar grep{uc $_ eq uc $c->req->method} @methods;
    });
    return $self;
}

sub viax($self, @methods) {
    $self->via(@methods);
    $self->aggregate->add([$self->aggregate->current->[0]]);
    unshift(@{$self->aggregate->current->[1]}, sub($c) {
        return ! scalar grep {uc $_ eq uc $c->req->method} @methods;
    });
    $self->aggregate->current->[2] = sub {
        my $c = Marquee->c;
        $c->app->error_document->serve(404);
    };
    $self->aggregate->prev;
    return $self;
}

package Marquee::Plugin::Router::Route::_Aggregate;
use strict;
use warnings;
use Mojo::Base -base;
use feature 'signatures';
no warnings "experimental::signatures";

has pointer => 0;
has data => sub{[]};

sub add($self, $rule) {
    push(@{$self->data}, $rule);
    $self->last;
}

sub current($self) {
    return $self->data->[$self->pointer];
}

sub last($self) {
    my $pointer = scalar @{$self->data} - 1;
    $self->pointer($pointer);
    return $self->data->[$pointer];
}

sub next($self) {
    my $pointer = $self->pointer + 1;
    $self->pointer($pointer);
    return $self->data->[$pointer];
}

sub prev($self) {
    my $pointer = $self->pointer - 1;
    $self->pointer($pointer);
    return $self->data->[$pointer];
}

1;

__END__

=head1 NAME

Marquee::Plugin::Router - Route generator and container

=head1 SYNOPSIS
    
    my $r = Marquee::Plugin::Router::Route->new;
    $r->route(qr{^/index\.html})->to(sub() {
        ...
    });
    
    $r->route(qr{^/special\.html})->to(sub() {
        ...
    });
    
    $r->route(qr{^/capture/(.+)-(.+)\.html})->to(sub($a, $b) {
        my ($a, $b) = @_;
        ...
    });
    
    $r->route(qr{^/rare/})->via('GET', 'POST')->to(sub() {
        ...
    });
    
    $r->route(qr{^/rare/})->viax('POST')->to(sub() {
        ...
    });
    
    $r->route(qr{^/rare/})->viax('post')->to(sub() {
        ...
    });
    
    $r->route(qr{^/default})->to(sub() {
        ...
    });
    
    my $bridge = $r->bridge(sub($c) {
        return 1; # or 0
    });
    
    $bridge->route(qr{})->to(sub() {...});

=head1 DESCRIPTION

L<Marquee::Plugin::Router> is a class for generating and storing routes.

=head1 ATTRIBUTES

L<Marquee::Plugin::Router> implements the following attributes.

=head2 C<elems>

Route entries.

    my $elems = $r->elems;

=head1 INSTANCE METHODS

L<Marquee::Plugin::Router> implements the following instance methods.

=head2 bridge

    my $bridge = $r->bridge(sub($c) {
        my $c = Marquee->c;
        return $bool;
    });

=head2 route

Set a regex that matches to request URI.

    $r->route(qr{^/index\.html});

=head2 to

Set an action to invoke when the route matches.

    $r->to(sub() {...});
    $r->to(sub($capture1, $capture2) {...});

=head2 via

Filters route by HTTP method.

    $r->via('GET', 'POST');

=head2 viax

Filters route by HTTP method exclusively. The method adds two routes at once
which restricts the HTTP method to given one.

    $r->route(qr{^/receptor})->viax('POST')->to(sub() {...});
    
    # equivalent to..

    $r->route(qr{^/receptor})->via('POST')->to(sub() {...});
    $r->route(qr{^/receptor})->to(sub() {
        my $c = Marquee->c;
        $c->app->error_document->serve(404);
    });

=head1 SEE ALSO

L<Marquee::Plugin::Router>, L<Marquee>, L<Mojolicious>

=cut

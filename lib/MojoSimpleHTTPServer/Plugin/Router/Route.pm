package MojoSimpleHTTPServer::Plugin::Router::Route;
use strict;
use warnings;
use Mojo::Base -base;
    
    __PACKAGE__->attr('elems', sub {[]});
    
    sub basic_auth {
        my ($self, $realm, $cb) = @_;
        
        my $bridge = $self->bridge(sub {
            my $tx = shift;
            my $auth = $tx->req->url->to_abs->userinfo || ':';
            if (! $cb->(split(/:/, $auth), 2)) {
                $tx->res->headers->www_authenticate("Basic realm=$realm");
                $tx->res->code(401);
                return;
            }
            return 1;
        });
        
        return $bridge;
    }
    
    sub bridge {
        my ($self, $cb) = @_;
        my $r = __PACKAGE__->new(bridge => $cb);
        $r->elems($self->elems);
        return $r;
    }
    
    sub route {
        my ($self, $regex) = @_;
        my $cond = $self->{bridge} ? [$self->{bridge}] : [];
        push(@{$self->elems}, $regex, $cond);
        return $self;
    }
    
    sub to {
        my ($self, $cb) = @_;
        push(@{$self->elems}, $cb);
        return $self;
    }
    
    sub via {
        my ($self, @methods) = @_;
        return $self->_add_cond(sub {
            my $tx = shift;
            scalar grep {uc $_ eq uc $tx->req->method} @methods;
        });
    }
    
    sub _add_cond {
        my ($self, $cond) = @_;
        my @elems = @{$self->elems};
        if (ref $elems[$#elems] ne 'ARRAY') {
            push(@elems, []);
        }
        unshift(@{$elems[$#elems]}, $cond);
        return $self;
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Plugin::Router - Router [EXPERIMENTAL]

=head1 SYNOPSIS
    
    my $r = MojoSimpleHTTPServer::Plugin::Router::Route->new;
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
    $r->route(qr{^/rare/})->via('get', 'post')->to(sub {
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

=head2 $instance->basic_auth($realm => sub {...})

[EXPERIMENTAL] Basic Authentication
    
    $app->plugin(Router => sub {
        my $r = shift;
        my $bridge = $r->basic_auth('Secret Area' => sub {
            $_[0] eq 'user' && $_[1] eq 'pass'
        });
    });

=head2 $instance->route($regex)

Set a regex that matches to request URI.

=head2 $instance->to($code_ref)

Set an action to invoke when the route matches.

=head2 $instance->via(@http_methods)

Filters route by HTTP method.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
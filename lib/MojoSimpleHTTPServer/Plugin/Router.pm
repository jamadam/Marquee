package MojoSimpleHTTPServer::Plugin::Router;
use strict;
use warnings;
use MojoSimpleHTTPServer::Plugin::Router::Route;
use Mojo::Base 'MojoSimpleHTTPServer::Plugin';
    
    __PACKAGE__->attr('route', sub {
        MojoSimpleHTTPServer::Plugin::Router::Route->new;
    });
    
    ### --
    ### Register the plugin into app
    ### --
    sub register {
        my ($self, $app, $routes) = @_;
        
        $routes->($self->route);
        
        $app->hook(around_dispatch => sub {
            my ($next, @args) = @_;
            
            my $tx      = $MSHS::CONTEXT->tx;
            my $path    = $tx->req->url->path->clone->leading_slash(1)->to_string;
            my @elems   = @{$self->route->elems};
            
            while (@elems) {
                my ($regex, $cond, $cb) = splice(@elems, 0,3);
                map {$_->($tx) || next} @$cond;
                if (my @captures = ($path =~ $regex)) {
                    $cb->(defined $1 ? @captures : ());
                    last;
                }
            }
            
            if (! $tx->res->code) {
                $next->(@args);
            }
        });
        
        return $self;
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Plugin::Router - Router [EXPERIMENTAL]

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

L<MojoSimpleHTTPServer::Plugin::Router::Route> instance.

=head1 METHODS

=head2 $instance->register($app, $routes)

=head1 SEE ALSO

L<MojoSimpleHTTPServer::Plugin::Router::Route>, L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

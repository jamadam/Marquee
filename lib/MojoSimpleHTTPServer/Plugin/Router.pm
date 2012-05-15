package MojoSimpleHTTPServer::Plugin::Router;
use strict;
use warnings;
use Mojo::Base 'MojoSimpleHTTPServer::Plugin';
    
    __PACKAGE__->attr('routes');
    
    ### --
    ### Register the plugin into app
    ### --
    sub register {
        my ($self, $app, $routes) = @_;
        
        $self->routes($routes);
        
        $app->hook(around_dispatch => sub {
            my ($next, @args) = @_;
            
            my $tx = $MojoSimpleHTTPServer::CONTEXT->tx;
            
            my @routes = @{$self->routes};
            
            while (my ($regex, $cb) = splice(@routes, 0,2)) {
                if (ref $cb eq 'HASH') {
                    $cb = _judge($tx->req, $cb) || next;
                }
                
                if (my @captures = ($tx->req->url->path =~ $regex)) {
                    $cb->(defined $1 ? @captures : ());
                    last;
                }
            }
            
            if (! $tx->res->code) {
                $next->(@args);
            }
        });
    }
    
    sub _judge {
        my ($req, $cond) = @_;
        
        if (defined $cond->{method} && uc $cond->{method} ne uc $req->method) {
            return;
        }
        
        return $cond->{cb};
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Plugin::Router - Router [EXPERIMENTAL]

=head1 SYNOPSIS

    $app->load_plugin(Router => [
        qr{index\.html} => sub {
            my $context = MyApp->context;
            ### DO SOMETHING
        },
        qr{(.+)_(.+)\.html} => sub {
            my ($capture1, $capture2) = @_;
            my $context = MyApp->context;
            ### DO SOMETHING
        },
        qr{(.+)_(.+)\.html} => {
            method  => 'GET',
            cb      => sub {
                my ($capture1, $capture2) = @_;
                my $context = MyApp->context;
                ### DO SOMETHING
            },
        }
    ]);

=head1 DESCRIPTION

=head1 METHODS

=head2 $instance->register($app, $hash_ref, $array_ref)

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

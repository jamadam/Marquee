package MojoSimpleHTTPServer::Plugin::Router;
use strict;
use warnings;
use Mojo::Base -base;
    
    ### --
    ### Register the plugin into app
    ### --
    sub register {
        my ($self, $app, $args) = @_;
        
        $app->around_method_hook('dispatch', sub {
            my ($app, $next, @args) = @_;
            
            my $tx = $MojoSimpleHTTPServer::CONTEXT->tx;
            
            my %args = %$args;
            while (my ($regex, $cb) = each %args) {
                if ($tx->req->url->path =~ $regex) {
                    $cb->();
                } else {
                    $next->(@args);
                }
            }
            
            return $app;
        });
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Plugin::Router - Router [EXPERIMENTAL]

=head1 SYNOPSIS

    $app->load_plugin(Router => {
        qr/index\.html/ => sub {
            my $context = MyApp->context;
            ### DO SOMETHING
        },
        qr/special\.html/ => sub {
            my $context = MyApp->context;
            ### DO SOMETHING
        },
    });

=head1 DESCRIPTION

=head1 METHODS

=head2 $instance->register($app, $hash_ref)

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

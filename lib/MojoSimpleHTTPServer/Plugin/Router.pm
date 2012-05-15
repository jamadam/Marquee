package MojoSimpleHTTPServer::Plugin::Router;
use strict;
use warnings;
use Mojo::Base 'MojoSimpleHTTPServer::Plugin';
    
    ### --
    ### Register the plugin into app
    ### --
    sub register {
        my ($self, $app, $args) = @_;
        
        $app->hook(around_dispatch => sub {
            my ($next, @args) = @_;
            
            my $tx = $MojoSimpleHTTPServer::CONTEXT->tx;
            
            for my $regex (keys %$args) {
                if ($tx->req->url->path =~ $regex) {
                    $args->{$regex}->();
                    last;
                }
            }
            
            if (! $tx->res->code) {
                $next->(@args);
            }
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

package Marquee::Plugin::Auth;
use strict;
use warnings;
use Mojo::Base 'Marquee::Plugin';
    
    ### --
    ### Register the plugin into app
    ### --
    sub register {
        my ($self, $app, $entries) = @_;
        
        $app->hook(around_dispatch => sub {
            my ($next, @args) = @_;
            
            my $tx  = Marquee->c->tx;
            my $path= $tx->req->url->path->clone->leading_slash(1)->to_string;
            
            my @entries = @$entries;
            while (@entries) {
                my $regex   = shift @entries;
                my $realm   = shift @entries if (! ref $entries[0]);
                my $cb      = shift @entries;
                
                $realm ||= 'Secret Area';
                
                if ($path =~ $regex) {
                    my $auth = $tx->req->url->to_abs->userinfo || ':';
                    if (! $cb->(split(/:/, $auth), 2)) {
                        $tx->res->headers->www_authenticate("Basic realm=$realm");
                        $tx->res->code(401);
                        return;
                    }
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

Marquee::Plugin::Auth - Basic Authentication

=head1 SYNOPSIS
    
    $self->plugin(Auth => [
        qr{^/admin/} => 'Secret Area' => sub {
            my ($username, $password) = @_;
            return $username eq 'user' &&  $password eq 'pass';
        },
        qr{^/admin/} => 'Secret Area2' => sub {
            my ($username, $password) = @_;
            return $username eq 'user' &&  $password eq 'pass';
        },
    ]);

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head2 $instance->register($app, $path_entries)

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

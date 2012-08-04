package Marquee::Plugin::Auth;
use strict;
use warnings;
use Mojo::Base 'Marquee::Plugin';

__PACKAGE__->attr(realm => 'Secret Area');

### --
### Register the plugin into app
### --
sub register {
    my ($self, $app, $entries) = @_;
    
    $app->hook(around_dispatch => sub {
        my ($next, @args) = @_;
        
        my $c    = Marquee->c;
        my $tx   = $c->tx;
        my $path = $tx->req->url->path->clone->leading_slash(1)->to_string;
        
        my @entries = @$entries;
        while (@entries) {
            my $regex   = shift @entries;
            my $realm   = ! ref $entries[0] ? shift @entries : $self->realm;
            my $cb      = shift @entries;
            
            if ($path =~ $regex) {
                my $auth = $tx->req->url->to_abs->userinfo || ':';
                if (! $cb->(split(/:/, $auth), 2)) {
                    $tx->res->headers->www_authenticate("Basic realm=$realm");
                    $tx->res->code(401);
                    return;
                }
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

This plugin wraps the whole dispatcher and requires basic authentication for
specific path.

=head1 ATTRIBUTES

=head2 realm

Default value of realm which appears to response header. Each entry can override
it with second option.

=head1 METHODS

=head2 $instance->register($app, $path_entries)

Register the plugin with path entries. $path_entries must be a list of
regex, realm, auth callback groups. realm is optional.

=head2 EXAMPLE

You can port apache htpasswd entries as follows.

    my $htpasswd = {
        user1 => 'znq.opIaiH.zs',
        user2 => 'dF45lPM2wMCDA',
    };
    
    $self->plugin(Auth => [
        qr{^/admin/} => 'Secret Area' => sub {
            my ($username, $password) = @_;
            if (my $expect = $htpasswd->{$username}) {
                return crypt($password, $expect) eq $expect;
            }
        },
    ]);

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

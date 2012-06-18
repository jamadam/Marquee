package MojoSimpleHTTPServer::Plugin;
use strict;
use warnings;
use Mojo::Base -base;

    sub register {
        die "Class ". (ref $_[0]) . " must implements register method";
    }

1;

=head1 NAME

MojoSimpleHTTPServer::Plugin - Plugin base class

=head1 SYNOPSIS

    package MojoSimpleHTTPServer::Plugin::SomePlugin;
    use Mojo::Base 'MojoSimpleHTTPServer::Plugin';

    sub register {
        my ($self, $app, $args) = @_;
        ...
        return $self;
    }

=head1 DESCRIPTION

L<MojoSimpleHTTPServer::Plugin> is the plugin base class
of L<MojoSimpleHTTPServer> plugins.

=head1 METHODS

=head2 MojoSimpleHTTPServer::Plugin->new(@args)

=head1 SEE ALSO

L<MojoSimpleHTTPServer>, L<Mojolicious>

=cut

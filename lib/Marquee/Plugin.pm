package Marquee::Plugin;
use strict;
use warnings;
use Mojo::Base -base;

sub register {
    die "Class ". (ref $_[0]) . " must implements register method";
}

1;

__END__

=head1 NAME

Marquee::Plugin - Plugin base class

=head1 SYNOPSIS

    package Marquee::Plugin::SomePlugin;
    use Mojo::Base 'Marquee::Plugin';

    sub register {
        my ($self, $app, $args) = @_;
        ...
        return $self;
    }

=head1 DESCRIPTION

L<Marquee::Plugin> is the plugin base class
of L<Marquee> plugins.

=head1 CLASS METHODS

L<Marquee::Plugin> implements the following class methods.

=head2 Class->register($app, $conf)

This must be overridden by sub classes.

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

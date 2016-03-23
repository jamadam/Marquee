package Marquee::SSIHandler::EPL;
use strict;
use warnings;
use Mojo::Base 'Marquee::SSIHandler';
use feature 'signatures';
no warnings "experimental::signatures";
use Marquee::Cache;
use Mojo::Util qw{encode md5_sum};
use Mojo::Template;

has template_cache => sub {Marquee::Cache->new};

sub get_cache($self, $path) {
    return $self->template_cache->get(md5_sum(encode('UTF-8', $path)));
}

### --
### Accessor to template cache
### --
sub set_cache($self, $path, $mt, $expire=undef) {
    return $self->template_cache->set(md5_sum(encode('UTF-8', $path)), $mt, $expire);
}

### --
### EPL handler
### --
sub render($self, $path) {
    
    my $c = Marquee->c;
    
    my $mt = $self->get_cache($path);
    
    if (! $mt) {
        $mt = Mojo::Template->new;
        $self->set_cache($path, $mt, sub($ts) {$ts < (stat($path))[9]});
    }
    
    my $output = $mt->compiled
            ? $mt->process($self, $c) : $mt->render_file($path, $self, $c);
    
    return ref $output ? die $output : $output;
}

1;

__END__

=head1 NAME

Marquee::SSIHandler::EPL - EPL template handler

=head1 SYNOPSIS

    my $epl = Marquee::SSIHandler::EPL->new;
    $epl->render('/path/to/template.html.ep');

=head1 DESCRIPTION

EPL handler.

=head1 ATTRIBUTES

L<Marquee::SSIHandler::EPL> inherits all attributes from
L<Marquee::SSIHandler> and implements the following new ones.

=head2 C<template_cache>

    my $cache = $epl->template_cache;

=head1 INSTANCE METHODS

L<Marquee::SSIHandler::EPL> inherits all instance methods from
L<Marquee::SSIHandler> and implements the following new ones.

=head2 C<get_cache>

Get cache.

    my $mt = $epl->get_cache('/path/to/template.html.ep');

=head2 C<set_cache>

Set cache.

    $epl->set_cache('/path/to/template.html.ep', $mt);
    $epl->set_cache('/path/to/template.html.ep', $mt, sub($ts) {
        return $ts > time() + 86400
    });

=head2 C<render>

Renders given template and returns the result. If rendering fails, die with
L<Mojo::Exception>.

    $epl->render('/path/to/template.html.epl');

=head1 SEE ALSO

L<Marquee::SSIHandler>, L<Marquee>, L<Mojolicious>

=cut

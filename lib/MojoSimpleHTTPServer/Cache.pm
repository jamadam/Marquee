package MojoSimpleHTTPServer::Cache;
use strict;
use warnings;
use Mojo::Base -base;
    
    __PACKAGE__->attr('max_keys');
    
    my $ATTR_CACHE      = 1;
    my $ATTR_STACK      = 2;
    
    sub get {
        if (my $cache = $_[0]->{$ATTR_CACHE}->{$_[1]}) {
            if ($cache->[2]) {
                for my $code (@{$cache->[2]}) {
                    if ($code->($cache->[1])) {
                        return;
                    }
                }
            }
            $cache->[0];
        }
    }
    
    sub set {
        my ($self, $key, $value, $expire) = @_;
        
        my $max_keys    = $self->max_keys || 100;
        my $cache       = $self->{$ATTR_CACHE} ||= {};
        my $stack       = $self->{$ATTR_STACK} ||= [];
        
        while (@$stack >= $max_keys) {
            delete $cache->{shift @$stack};
        }
        
        push @$stack, $key;
        
        $cache->{$key} = [
            $value,
            time,
            (ref $expire eq 'CODE') ? [$expire] : $expire
        ];
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Stash - stash

=head1 SYNOPSIS

    use MojoSimpleHTTPServer::Stash;
    
    my $stash = MojoSimpleHTTPServer::Stash->new(a => 'b', c => 'd');
    is_deeply $stash->set(), {a => 'b', c => 'd'};
    
    $stash->set(e => 'f');
    is_deeply $stash->get(), {a => 'b', c => 'd', e => 'f'};
    
    $stash->set(e => 'g');
    is_deeply $stash->get(), {a => 'b', c => 'd', e => 'g'};
    
    my $clone = $stash->clone(h => 'i');
    is_deeply $clone->get(), {a => 'b', c => 'd', e => 'g', h => 'i'};
    is_deeply $stash->get(), {a => 'b', c => 'd', e => 'g'};

=head1 DESCRIPTION

A class represents stash. The instance is a code ref accessing to closed hash
ref.

=head1 METHODS

=head2 MojoSimpleHTTPServer::Stash->new(%key_value)

=head2 $instance->get($name)

Get stash value for given name.

=head2 $instance->set(%key_value)

Set stash values with given hash or hash reference.

=head2 $instance->clone(%key_value)

Clone stash with given hash or hash reference merged.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package Marquee::Stash;
use strict;
use warnings;
use Mojo::Base -base;

sub get {
    my $self = shift;
    if (! $_[0]) {
        return $self;
    }
    
    return $self->{$_[0]};
}

sub set {
    my $self = shift;
    my $values = ref $_[0] ? $_[0] : {@_};
    for my $key (keys %$values) {
        $self->{$key} = $values->{$key};
    }
}

### --
### Clone
### --
sub clone {
    my $self = shift;
    (ref $self)->new(%{$self}, @_);
}

1;

__END__

=head1 NAME

Marquee::Stash - stash

=head1 SYNOPSIS

    use Marquee::Stash;
    
    my $stash = Marquee::Stash->new(a => 'b', c => 'd');
    is_deeply $stash->set(), {a => 'b', c => 'd'};
    
    $stash->set(e => 'f');
    is_deeply $stash->get(), {a => 'b', c => 'd', e => 'f'};
    
    $stash->set(e => 'g');
    is_deeply $stash->get(), {a => 'b', c => 'd', e => 'g'};
    
    my $clone = $stash->clone(h => 'i');
    is_deeply $clone->get(), {a => 'b', c => 'd', e => 'g', h => 'i'};
    is_deeply $stash->get(), {a => 'b', c => 'd', e => 'g'};

=head1 DESCRIPTION

A class represents stash.

=head1 CLASS METHODS

L<Marquee::Stash> implements the following class methods.

=head2 C<new>

    my $stash = Marquee::Stash->new(key => 'val', key2 => 'val2');

=head1 INSTANCE METHODS

L<Marquee::Stash> implements the following instance methods.

=head2 C<get>

Get stash value for given name.

    my $hash_ref = $stash->get();
    my $value    = $stash->get('key');
    
=head2 C<set>

Set stash values with given hash or hash reference.

    $stash->set(key => 'value');

=head2 C<clone>

Clone stash with given hash or hash reference merged.

    my $clone = $stash->clone;
    my $clone = $stash->clone(key => 'value');

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

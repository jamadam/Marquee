package MojoSimpleHTTPServer::Stash;
use strict;
use warnings;
use Mojo::Base -base;
    
    ### --
    ### Constractor
    ### --
    sub new {
        my $class = shift;
        my $stash = $class->SUPER::new(@_);
        return bless sub {
            
            if (! @_) {
                return $stash;
            }
            
            # Get
            if (! (@_ > 1 || ref $_[0])) {
                return $stash->{$_[0]};
            }
          
            # Set
            my $values = ref $_[0] ? $_[0] : {@_};
            for my $key (keys %$values) {
                $stash->{$key} = $values->{$key};
            }
            return;
        }, $class;
    }
    
    ### --
    ### Clone
    ### --
    sub clone {
        my $self = shift;
        (ref $self)->new(%{$self->()}, @_);
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Stash - stash

=head1 SYNOPSIS

    use MojoSimpleHTTPServer::Stash;
    
    my $stash = MojoSimpleHTTPServer::Stash->new(a => 'b', c => 'd');
    is_deeply $stash->(), {a => 'b', c => 'd'};
    
    $stash->(e => 'f');
    is_deeply $stash->(), {a => 'b', c => 'd', e => 'f'};
    
    $stash->(e => 'g');
    is_deeply $stash->(), {a => 'b', c => 'd', e => 'g'};
    
    my $clone = $stash->clone(h => 'i');
    is_deeply $clone->(), {a => 'b', c => 'd', e => 'g', h => 'i'};
    is_deeply $stash->(), {a => 'b', c => 'd', e => 'g'};

=head1 DESCRIPTION

A class represents stash. The instance is a code ref accessing to closed hash
ref.

=head1 METHODS

=head2 MojoSimpleHTTPServer::Stash->new(%key_value)

=head2 $instance->clone(%key_value)

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

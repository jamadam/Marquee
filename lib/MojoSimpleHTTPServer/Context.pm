package MojoSimpleHTTPServer::Context;
use strict;
use warnings;
use Mojo::Base -base;
    
    ### ---
    ### App
    ### ---
    __PACKAGE__->attr('app');
    
    ### ---
    ### Transaction
    ### ---
    __PACKAGE__->attr('tx');
    
    ### ---
    ### localized Stash
    ### ---
    sub stash {
        my $self = shift;
      
        # Hash
        my $stash = $self->{stash} ||= {%{$self->app->stash}};
        
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
      
        return $self;
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Context - Context

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 app

MojoSimpleHTTPServer instance.

=head2 tx

Mojo::Transaction instance.

=head1 METHODS

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

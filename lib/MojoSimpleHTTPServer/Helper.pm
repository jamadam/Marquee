package MojoSimpleHTTPServer::Helper;
use Mojo::Base -base;

    sub param {
        my $class = shift;
        $MojoSimpleHTTPServer::context->tx->req->param($_[0]);
    }

    sub stash {
        my $class = shift;
        $MojoSimpleHTTPServer::context->stash(@_);
    }
    
    sub helpers {
        my %names;
        for my $name (qw/ param stash /) {
            $names{$name} = sub { __PACKAGE__->$name(@_) };
        }
        return \%names;
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Helper - Helper functions for ep renderer

=head1 SYNOPSIS

    <%= param('key') %>

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 <% param('key') %>

Returns request parameters for given key.

=head2 <% stash('key') %>

Returns stash value for given key.

=head1 METHODS

=head2 $instance->helpers()

Generates hash of built-in helper name and code refs.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

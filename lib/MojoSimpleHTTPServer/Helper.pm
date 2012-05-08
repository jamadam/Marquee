package MojoSimpleHTTPServer::Helper;
use Mojo::Base -base;
use File::Basename 'dirname';

    ### --
    ### Request param
    ### --
    sub param {
        my $class = shift;
        $MojoSimpleHTTPServer::context->tx->req->param($_[0]);
    }

    ### --
    ### Stash
    ### --
    sub stash {
        my $class = shift;
        $MojoSimpleHTTPServer::context->stash(@_);
    }
    
    ### --
    ### Current template path
    ### --
    sub ctd {
        my $class = shift;
        $MojoSimpleHTTPServer::context->stash->{template_path};
    }
    
    ### --
    ### Include template
    ### --
    sub include {
        my ($class, $path) = @_;
        
        my $path_abs = dirname($class->ctd). '/'. $path;
        
        if (-f $path_abs) {
            my $context = $MojoSimpleHTTPServer::context;
            my $ext = ($path =~ qr{\.\w+\.(\w+)$})[0];
            my $handler = $context->app->template_handlers->{$ext};
            if ($handler) {
                $handler->($path_abs, $context);
            }
        }
    }
    
    sub helpers {
        my %names;
        for my $name (qw/ param stash ctd include /) {
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

=head2 <% ctd() %>

Returns current template path.

=head2 <% include('./path/to/template.html.ep') %>

Include a template into current template. Note that the path must be relative to
current template directory.

=head2 <% param('key') %>

Returns request parameters for given key.

=head2 <% stash('key') %>

Returns stash value for given key.

=head1 METHODS

=head2 $instance->helpers()

Generates hash of built-in helper names and code refs.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

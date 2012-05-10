package MojoSimpleHTTPServer::TemplateHandler;
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::Cache;
use Mojo::Util qw/encode md5_sum/;
    
    ### --
    ### Accessor to template cache
    ### --
    sub cache {
        my ($self, $path, $mt) = @_;
        
        my $cache =
            $MojoSimpleHTTPServer::CONTEXT->app->stash->{'mshs.template_cache'}
                                                        ||= Mojo::Cache->new;
        
        my $key = md5_sum(encode('UTF-8', $path));
        if ($mt) {
            $cache->set($key => $mt);
        } else {
            $cache->get($key);
        }
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Context - Context

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 cache

=head1 METHODS

=head2 get_cache

Get template cache for given path

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
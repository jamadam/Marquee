package MojoSimpleHTTPServer::SSIHandler::EPL;
use strict;
use warnings;
use Mojo::Base 'MojoSimpleHTTPServer::SSIHandler';
use MojoSimpleHTTPServer::Cache;
use Mojo::Util qw/encode md5_sum/;
use Mojo::Template;

    __PACKAGE__->attr('template_cache' => sub {MojoSimpleHTTPServer::Cache->new});
    
    ### --
    ### Accessor to template cache
    ### --
    sub cache {
        my ($self, $path, $mt, $expire) = @_;
        
        my $cache = $self->template_cache;
        my $key = md5_sum(encode('UTF-8', $path));
        if ($mt) {
            $cache->set($key, $mt, $expire);
        } else {
            $cache->get($key);
        }
    }

    ### --
    ### EPL handler
    ### --
    sub render {
        my ($self, $path) = @_;
        
        my $context = $MSHS::CONTEXT;
        
        my $mt = $self->cache($path);
        
        if (! $mt) {
            $mt = Mojo::Template->new;
            $self->cache($path, $mt, sub {$_[0] < (stat($path))[9]});
        }
        
        my $output;
        
        if ($mt->compiled) {
            $output = $mt->interpret($self, $context);
        } else {
            $output = $mt->render_file($path, $self, $context);
        }
        
        return ref $output ? die $output : $output;
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::SSIHandler::EPL - EPL template handler

=head1 SYNOPSIS

    my $epl = MojoSimpleHTTPServer::SSIHandler::EPL->new;
    $epl->render('/path/to/template.html.ep');

=head1 DESCRIPTION

EPL handler.

=head1 ATTRIBUTES

L<MojoSimpleHTTPServer::SSIHandler::EPL> inherits all attributes from
L<MojoSimpleHTTPServer::SSIHandler> and implements the following new ones.

=head2 template_cache

    my $cache = $epl->template_cache;

=head1 METHODS

L<MojoSimpleHTTPServer::SSIHandler::EPL> inherits all methods from
L<MojoSimpleHTTPServer::SSIHandler> and implements the following new ones.

=head2 $instance->cache($path, $mt)

Get or set cache.

    $epl->cache('/path/to/template.html.ep', $mt);
    my $mt = $epl->cache('/path/to/template.html.ep');

=head2 $instance->render($path)

Renders given template and returns the result. If rendering fails, die with
L<Mojo::Exception>.

=head1 SEE ALSO

L<MojoSimpleHTTPServer::SSIHandler>, L<MojoSimpleHTTPServer>, L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

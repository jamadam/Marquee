package MojoSimpleHTTPServer::TemplateHandler::EPL;
use Mojo::Base -base;
    
    ### --
    ### EPL handler
    ### --
    sub render {
        my ($self, $path, $context) = @_;
        
        local $context->stash->{template_path} = $path;
        
        my $mt = Mojo::Template->new;
        
        $mt->render_file($path, $context);
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::TemplateHandler::EPL - EPL template handler

=head1 SYNOPSIS

    $app->add_handler(epl => MojoSimpleHTTPServer::TemplateHandler::EPL->new);

=head1 DESCRIPTION

EPL handler.

=head1 ATTRIBUTES

=head1 METHODS

=head2 $instance->render($path, $context)

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

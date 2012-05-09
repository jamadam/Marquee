package MojoSimpleHTTPServer::TemplateHandler::EP;
use Mojo::Base -base;
    
    ### --
    ### ep handler
    ### --
    sub render {
        my ($self, $path, $context) = @_;
        
        local $context->app->stash->{template_path} = $path;
        
        my $mt = Mojo::Template->new;

        # Be a bit more relaxed for helpers
        my $prepend = q/no strict 'refs'; no warnings 'redefine';/;

        # Helpers
        $prepend .= 'my $_H = shift;';
        my $helper = $context->app->helper;
        for my $name (sort keys %{$helper->funcs}) {
            if ($name =~ /^\w+$/) {
                $prepend .=
                "sub $name; *$name = sub {\$_H->funcs->{$name}->(\$_H, \@_)};";
            }
        }
        
        $prepend .= 'use strict;';
        for my $var (keys %{$context->app->stash}) {
            if ($var =~ /^\w+$/) {
                $prepend .= " my \$$var = stash '$var';";
            }
        }
        $mt->prepend($prepend);
        $mt->render_file($path, $helper, $context);
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::TemplateHandler::EP - EP template handler

=head1 SYNOPSIS

    $app->add_handler(ep => MojoSimpleHTTPServer::TemplateHandler::EP->new);

=head1 DESCRIPTION

EP handler.

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

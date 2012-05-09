package MojoSimpleHTTPServer::TemplateHandler::EP;
use strict;
use warnings;
use Mojo::Base 'MojoSimpleHTTPServer::TemplateHandler';
    
    ### --
    ### ep handler
    ### --
    sub render {
        my ($self, $path) = @_;
        
        my $context = $MojoSimpleHTTPServer::CONTEXT;
        my $helper = $context->app->helper;
        
        local $context->app->stash->{template_path} = $path;
        
        my $mt = $self->cache($path) || Mojo::Template->new;
        
        my $output;
        
        if ($mt->compiled) {
            $output = $mt->interpret($helper, $context);
        } else {
            # Be a bit more relaxed for helpers
            my $prepend = q/no strict 'refs'; no warnings 'redefine';/;
    
            # Helpers
            $prepend .= 'my $_H = shift;';
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
            $output = $mt->render_file($path, $helper, $context);
            
            $self->cache($path => $mt);
        }
        
        return ref $output ? die $output : $output;
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

=head2 $instance->render($path)

Renderes given template and returns the result. If rendering fails, die with
Mojo::Exception.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

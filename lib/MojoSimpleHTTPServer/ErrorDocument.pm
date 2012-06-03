package MojoSimpleHTTPServer::ErrorDocument;
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::Cache;
use Mojo::Util qw'encode';
    
    my %messages = (
        404 => 'File not found',
        500 => 'Internal server error',
        403 => 'Forbidden',
    );
    
    my $type = Mojolicious::Types->new->type('html');
    
    __PACKAGE__->attr('template', sub {
        MojoSimpleHTTPServer::asset('error_document.ep');
    });
    
    __PACKAGE__->attr('status_template' => sub {{}});
    
    ### --
    ### Serve error document
    ### --
    sub render {
        my ($self, $code, $message) = @_;
        
        my $context = $MojoSimpleHTTPServer::CONTEXT;
        my $tx = $context->tx;
        
        my $template;
        
        if ($context->app->under_development && ref $message) {
            $context->stash->set(
                'mshs.static_dir'   => 'static',
                'mshs.code'         => $code,
                'mshs.exception'      => $message,
            );
            $template = MojoSimpleHTTPServer::asset('debug_screen.ep');
        } else {
            if (ref $message) {
                $context->stash->set(
                    'mshs.static_dir'   => 'static',
                    code                => $code,
                    message             => $messages{$code},
                );
            } else {
                $context->stash->set(
                    'mshs.static_dir'   => 'static',
                    code                => $code,
                    message             => $message || $messages{$code},
                );
            }
        }
        
        $template ||= ($self->status_template)->{$code} || $self->template;
        
        my $body =
            MojoSimpleHTTPServer::SSIHandler::EP->new->render_traceable($template);
        
        $tx->res->code($code);
        $tx->res->body(encode('UTF-8', $body));
        $tx->res->headers->content_type($type);
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::ErrorDocument - ErrorDocument

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

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

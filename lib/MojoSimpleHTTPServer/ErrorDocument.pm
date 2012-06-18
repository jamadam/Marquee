package MojoSimpleHTTPServer::ErrorDocument;
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::Cache;
use Mojo::Util qw'encode';
    
    my %messages = (
        404 => 'File Not Found',
        500 => 'Internal Server Error',
        403 => 'Forbidden',
    );
    
    my $type = Mojolicious::Types->new->type('html');
    
    __PACKAGE__->attr('template', sub {
        MojoSimpleHTTPServer->asset('error_document.html.ep');
    });
    
    __PACKAGE__->attr('status_template' => sub {{}});
    
    ### --
    ### Serve error document
    ### --
    sub serve {
        my ($self, $code, $message) = @_;
        
        $message ||= $messages{$code};
        
        my $context     = $MSHS::CONTEXT;
        my $tx          = $context->tx;
        my $stash       = $context->stash;
        my $template    = ($self->status_template)->{$code} || $self->template;
        my $ep          = $context->app->ssi_handlers->{ep};
        
        if ($context->app->under_development) {
            my $snapshot = $stash->clone;
            $ep->add_function(snapshot => sub {$snapshot});
            $stash->set(
                static_dir  => 'static',
                code        => $code,
                message     =>
                    ref $message ? $message : Mojo::Exception->new($message),
            );
            $template = MojoSimpleHTTPServer->asset('debug_screen.html.ep');
        } else {
            $stash->set(
                static_dir  => 'static',
                code        => $code,
            );
            $stash->set(message => ref $message ? $messages{$code} : $message);
        }
        
        $tx->res->code($code);
        $tx->res->body(encode('UTF-8', $ep->render_traceable($template)));
        $tx->res->headers->content_type($type);
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::ErrorDocument - ErrorDocument

=head1 SYNOPSIS

    my $error_doc = MojoSimpleHTTPServer::ErrorDocument->new;
    $error_doc->render(404, 'File not found');

=head1 DESCRIPTION

L<MojoSimpleHTTPServer::ErrorDocument> represents error document.

=head1 ATTRIBUTES

=head2 template

    $error_doc->template('/path/to/template.html.ep');

=head2 status_template

    $error_doc->status_template->{404} = '/path/to/template.html.ep';

=head1 METHODS

=head2 $instance->serve($status_code, $message)

Serves error document.

    $error_doc->serve(404, 'File not found');

=head1 SEE ALSO

L<MojoSimpleHTTPServer>, L<Mojolicious>

=cut

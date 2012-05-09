package MojoSimpleHTTPServer::Helper;
use strict;
use warnings;
use Mojo::Base -base;
use File::Basename 'dirname';
use Data::Dumper;

    __PACKAGE__->attr(funcs => sub {{}});
    
    ### --
    ### Add helper
    ### --
    sub add_helper {
        my ($self, $name, $cb) = @_;
        $self->funcs->{$name} = $cb;
        return $self;
    }
    
    ### --
    ### load preset
    ### --
    sub load_preset {
        my ($self) = @_;
        
        $self->add_helper(param => sub {
            shift;
            $MojoSimpleHTTPServer::CONTEXT->tx->req->param($_[0]);
        });
        
        $self->add_helper(stash => sub {
            shift;
            $MojoSimpleHTTPServer::CONTEXT->app->stash(@_);
        });
        
        $self->add_helper(ctd => sub {
            shift->_ctd;
        });
        
        $self->add_helper(dumper => sub {
            shift;
            Data::Dumper->new([@_])->Indent(1)->Terse(1)->Dump;
        });
        
        $self->add_helper(to_abs => sub {
            shift->_to_abs(@_);
        });
        
        $self->add_helper(include => sub {
            my ($self, $path) = @_;
            
            my $path_abs = $self->_to_abs($path);
            
            if (-f $path_abs) {
                my $context = $MojoSimpleHTTPServer::CONTEXT;
                my $ext = ($path =~ qr{\.\w+\.(\w+)$})[0];
                my $handler = $context->app->template_handlers->{$ext};
                if ($handler) {
                    $handler->render($path_abs, $context);
                }
            }
        });
        
        return $self;
    }
    
    ### --
    ### abs
    ### --
    sub _to_abs {
        my ($self, $path) = @_;
        
        my $path_abs = dirname($self->_ctd). '/'. $path;
        
        return $path_abs;
    }
    
    ### --
    ### Current template path
    ### --
    sub _ctd {
        my $self = shift;
        $MojoSimpleHTTPServer::CONTEXT->app->stash->{'mshs.template_path'};
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

=head2 <% to_abs() %>

Generate absolute path with given relative one

=head1 METHODS

=head2 $instance->add_helper($name, $code_ref)

Adds helper

=head2 $instance->load_preset()

Loads preset helpers.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

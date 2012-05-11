package MojoSimpleHTTPServer::SSIHandler::EP;
use strict;
use warnings;
use Mojo::Base 'MojoSimpleHTTPServer::SSIHandler::EPL';
use File::Basename 'dirname';

    ### --
    ### Function definitions for inside template
    ### --
    __PACKAGE__->attr(funcs => sub {{}});
    
    ### --
    ### Add helper
    ### --
    sub add_function {
        my ($self, $name, $cb) = @_;
        $self->funcs->{$name} = $cb;
        return $self;
    }
    
    ### --
    ### Constractor
    ### --
    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->load_funcs;
    }
    
    ### --
    ### load preset
    ### --
    sub load_funcs {
        my ($self) = @_;
        
        $self->funcs->{app} = sub {
            shift;
            $MojoSimpleHTTPServer::CONTEXT->app;
        };
        
        $self->funcs->{param} = sub {
            shift;
            $MojoSimpleHTTPServer::CONTEXT->tx->req->param($_[0]);
        };
        
        $self->funcs->{stash} = sub {
            shift;
            $MojoSimpleHTTPServer::CONTEXT->stash->(@_);
        };
        
        $self->funcs->{ctd} = sub {
            shift->_ctd;
        };
        
        $self->funcs->{dumper} = sub {
            shift;
            Data::Dumper->new([@_])->Indent(1)->Terse(1)->Dump;
        };
        
        $self->funcs->{to_abs} = sub {
            shift->_to_abs(@_);
        };
        
        $self->funcs->{include} = sub {
            my ($self, $path) = @_;
            
            $MojoSimpleHTTPServer::CONTEXT->app->render_ssi(
                                                        $self->_to_abs($path));
        };
        
        $self->funcs->{override} = sub {
            my ($self, $name, $value) = @_;
            my $stash = $MojoSimpleHTTPServer::CONTEXT->stash->();
            $stash->{$name} = $value;
        };
        
        $self->funcs->{placeholder} = sub {
            my ($self, $name, $defalut) = @_;
            my $block =
                $MojoSimpleHTTPServer::CONTEXT->stash->($name) || $defalut;
            return $block->() || '';
        };
        
        $self->funcs->{extends} = sub {
            my ($self, $path, $block) = @_;
            
            my $app = $MojoSimpleHTTPServer::CONTEXT->app;
            
            local $MojoSimpleHTTPServer::CONTEXT->{stash} =
                                $MojoSimpleHTTPServer::CONTEXT->{stash}->clone;
            
            $block->();
            
            $app->render_ssi($self->_to_abs($path));
        };
        
        return $self;
    }
    
    ### --
    ### ep handler
    ### --
    sub render {
        my ($self, $path) = @_;
        
        if (! $self->cache($path)) {
            my $mt = Mojo::Template->new;
            
            # Be a bit more relaxed for helpers
            my $prepend = q/no strict 'refs'; no warnings 'redefine';/;
    
            # Helpers
            $prepend .= 'my $_H = shift;';
            for my $name (sort keys %{$self->funcs}) {
                if ($name =~ /^\w+$/) {
                    $prepend .=
                    "sub $name; *$name = sub {\$_H->funcs->{$name}->(\$_H, \@_)};";
                }
            }
        
            my $context = $MojoSimpleHTTPServer::CONTEXT;
            
            $prepend .= 'use strict;';
            for my $var (keys %{$context->stash->()}) {
                if ($var =~ /^\w+$/) {
                    $prepend .= " my \$$var = stash '$var';";
                }
            }
            $mt->prepend($prepend);
            
            $self->cache($path => $mt);
        }
        
        return $self->SUPER::render($path);
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
        $MojoSimpleHTTPServer::CONTEXT->stash->('mshs.template_path');
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::SSIHandler::EP - EP template handler

=head1 SYNOPSIS

    $app->add_handler(ep => MojoSimpleHTTPServer::SSIHandler::EP->new);

=head1 DESCRIPTION

EP handler.

=head1 ATTRIBUTES

=head1 METHODS

=head2 $instance->render($path)

Renders given template and returns the result. If rendering fails, die with
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

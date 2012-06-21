package MojoSimpleHTTPServer::SSIHandler;
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::Cache;
use Mojo::Util qw/encode md5_sum/;

    ### --
    ### Constructor
    ### --
    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->init;
        return $self;
    }
    
    ### --
    ### Get current template name recursively
    ### --
    sub current_template {
        my ($self, $index) = @_;
        
        $index ||= 0;
        
        my $route = $MSHS::CONTEXT->stash->{'mshs.template_path'};
        
        while ($index-- > 0) {
            $route = $route->[1] || return;
        }
        
        return $route->[0];
    }
    
    ### --
    ### initialize
    ### --
    sub init {
        ### Can override by sub classes
    }
    
    ### --
    ### render
    ### --
    sub render {
        die "Class ". (ref $_[0]) . " must implements render method";
    }
    
    ### --
    ### traceably render
    ### --
    sub render_traceable {
        my ($self, $path, $cb) = @_;
        
        my $stash = $MSHS::CONTEXT->stash;
        
        local $stash->{'mshs.template_path'} =
                                        [$path, $stash->{'mshs.template_path'}];
        
        return $cb ? $cb->() : $self->render($path);
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::SSIHandler - SSI handler base class

=head1 SYNOPSIS

    package MojoSimpleHTTPServer::SSIHandler::EPL;
    use Mojo::Base 'MojoSimpleHTTPServer::SSIHandler';
    
    sub render {
        my ($self, $path) = @_;
        
        ...;
        
        return $out;
    }
    
    sub init {
        ...
    }

=head1 DESCRIPTION

This is a SSI handler base class to be inherited by handler classes. The sub
class is MUST implement C<render> method.

=head1 METHODS

=head2 MojoSimpleHTTPServer::SSIHandler->new;

Constructor.

=head2 MojoSimpleHTTPServer::SSIHandler->current_template;

Detects current template recursively.

    my $current_template = MojoSimpleHTTPServer::SSIHandler->current_template;
    my $parent_template = MojoSimpleHTTPServer::SSIHandler->current_template(1);

=head2 $instance->init;

Initializes plugin on instantiation stage.

=head2 $instance->render;

Renders templates. The sub classes MUST override(implement) the method.
    
    sub render {
        my ($self, $path) = @_;
        
        ...;
        
        return $out;
    }

=head2 $instance->render_traceable;

Traceably renders templates by stacking template names recursively.

=head1 SEE ALSO

L<MojoSimpleHTTPServer::SSIHandler::EPL>,
L<MojoSimpleHTTPServer::SSIHandler::EP>, L<MojoSimpleHTTPServer>, L<Mojolicious>

=cut

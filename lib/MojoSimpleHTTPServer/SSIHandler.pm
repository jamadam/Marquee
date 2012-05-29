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
        $MojoSimpleHTTPServer::CONTEXT->stash->()
                                        ->{'mshs.template_path'}->[$index || 0];
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
    
    sub render_traceable {
        my ($self, $path, $cb) = @_;
        
        my $stack = $MojoSimpleHTTPServer::CONTEXT
                                    ->stash->()->{'mshs.template_path'} ||= [];
        
        unshift(@$stack, $path);
        
        my $ret = $cb ? $cb->() : $self->render($path);
        
        shift(@$stack);
        
        return $ret;
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Context - Context

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 MojoSimpleHTTPServer::SSIHandler->new;

Constructor.

=head2 MojoSimpleHTTPServer::SSIHandler->init;

Initializes plugins.

=head2 MojoSimpleHTTPServer::SSIHandler->render;

Renders templates.

=head2 MojoSimpleHTTPServer::SSIHandler->render_traceable;

Traceably renders templates by stacking template names recursively.

=head2 MojoSimpleHTTPServer::SSIHandler->current_template;

Detects current template recursively.

=head1 METHODS

=head2 new

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

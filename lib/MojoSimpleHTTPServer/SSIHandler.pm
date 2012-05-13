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
    ### render wrapper
    ### --
    sub render_traceable {
        my $stack = $MojoSimpleHTTPServer::CONTEXT
                                    ->stash->()->{'mshs.template_path'} ||= [];
        unshift(@$stack, $_[1]);
        my $ret = shift->render(@_);
        shift(@$stack);
        
        return $ret;
    }
    
    ### --
    ### Get current template name recursively
    ### --
    sub current_template {
        $MojoSimpleHTTPServer::CONTEXT->stash->()->{'mshs.template_path'}->[0];
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::Context - Context

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 cache

=head1 METHODS

=head2 get_cache

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

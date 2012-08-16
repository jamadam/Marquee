package Marquee::SSIHandler;
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::Cache;
use Mojo::Util qw/encode md5_sum/;

__PACKAGE__->attr(log => sub {
    if (my $c = Marquee->c) {
        $c->app->log;
    }
});

### --
### Get current template name recursively
### --
sub current_template {
    my ($self, $index) = @_;
    
    $index ||= 0;
    
    my $route = Marquee->c->stash->{'mrqe.template_path'};
    
    while ($index-- > 0) {
        $route = $route->[1] || return;
    }
    
    return $route->[0];
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
    
    my $stash = Marquee->c->stash;
    
    local $stash->{'mrqe.template_path'} =
                                    [$path, $stash->{'mrqe.template_path'}];
    
    return $cb ? $cb->() : $self->render($path);
}

1;

__END__

=head1 NAME

Marquee::SSIHandler - SSI handler base class

=head1 SYNOPSIS

    package Marquee::SSIHandler::EPL;
    use Mojo::Base 'Marquee::SSIHandler';
    
    sub render {
        my ($self, $path) = @_;
        
        ...;
        
        return $out;
    }

=head1 DESCRIPTION

This is a SSI handler base class to be inherited by handler classes. The sub
class is MUST implement C<render> method.

=head1 ATTRIBUTES

L<Marquee::SSIHandler> implements the following attributes.

=head2 app

Marquee app instance.

    $ep->app($app);

=head2 log

C<Mojo::Log> instance. Defaults to C<$app-E<gt>log> if exists.

=head1 CLASS METHODS

L<Marquee::SSIHandler> implements the following class methods.

=head2 Class->new

Constructor.

=head2 Class->current_template

Detects current template recursively.

    my $current_template = Marquee::SSIHandler->current_template;
    my $parent_template = Marquee::SSIHandler->current_template(1);

=head1 INSTANCE METHODS

L<Marquee::SSIHandler> implements the following instance methods.

=head2 $instance->render

Renders templates. The sub classes MUST override(implement) the method.
    
    sub render {
        my ($self, $path) = @_;
        
        ...;
        
        return $out;
    }

=head2 $instance->render_traceable

Traceably renders templates by stacking template names recursively.

=head1 SEE ALSO

L<Marquee::SSIHandler::EPL>,
L<Marquee::SSIHandler::EP>, L<Marquee>, L<Mojolicious>

=cut

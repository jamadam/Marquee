package MojoSimpleHTTPServer::Hooks;
use strict;
use warnings;
use Mojo::Base 'Mojo::EventEmitter';
    
    ### --
    ### Emit events as chained hooks
    ### --
    sub emit_chain {
        my ($self, $name, @args) = @_;
        
        my $wrapper;
        for my $cb (@{$self->subscribers($name)}) {
            my $next = $wrapper;
            $wrapper = sub { $cb->($next, @args) };
        }
        $wrapper->();
        
        return $self;
    }

1;

=head1 NAME

MojoSimpleHTTPServer::Hooks - Hooks manager

=head1 SYNOPSIS

    use MojoSimpleHTTPServer::Hooks;
    
    my $hook = MojoSimpleHTTPServer::Hooks->new;
    
    $hook->on(name => sub {
        my ($next, @args) = @_;
        ### pre-process
        $next->(@args);
        ### post-process
    });
    
    $hook->emit_chain('name');

=head1 DESCRIPTION

L<Mojolicious::Hooks> is the Hook manager of L<MojoSimpleHTTPServer>.

=head1 METHODS

L<Mojolicious::Hooks> inherits all methods from L<Mojo::EventEmitter> and
implements the following new ones.

=head2 C<emit_chain>

  $plugins = $plugins->emit_chain('foo');
  $plugins = $plugins->emit_chain(foo => 123);

Emit events as chained hooks. Note that the hook order is reverse to
Mojolicious::Plugins.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut

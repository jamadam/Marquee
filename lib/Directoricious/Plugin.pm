package Directoricious::Plugin;
use strict;
use warnings;
use Mojo::Base 'Mojo::EventEmitter';
    
    sub emit_chain {
        my ($self, $name, @args) = @_;
      
        my $wrapper;
        for my $cb (reverse @{$self->subscribers($name)}) {
            my $next = $wrapper;
            $wrapper = sub { $cb->($next, @args) };
        }
        $wrapper->();
      
        return $self;
    }

1;

package Directoricious::Controller;
use strict;
use warnings;
use Mojo::Base -base;
    
    __PACKAGE__->attr('app');
    __PACKAGE__->attr('tx');

    sub new {
        my ($class, $app, $tx) = @_;
        return $class->SUPER::new->app($app)->tx($tx);
    }

1;

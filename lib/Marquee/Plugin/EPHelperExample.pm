package Marquee::Plugin::EPHelperExample;
use strict;
use warnings;
use Mojo::Base 'Marquee::Plugin';
use List::Util qw{min};

### --
### Register the plugin into app
### --
sub register {
    my ($self, $app) = @_;
    
    # Commify a number
    $app->ssi_handlers->{ep}->add_function(commify => sub {
        my ($ep, $num) = @_;
        
        if ($num) {
            while($num =~ s/(.*\d)(\d\d\d)/$1,$2/){};
            return $num;
        }
        if ($num eq '0') {
            return 0;
        }
        return;
    });
    
    # Mininum value out of given array
    $app->ssi_handlers->{ep}->add_function(min => sub {
        my ($ep, @array) = @_;
        if (ref $array[0] && ref $array[0] eq 'ARRAY') {
            @array = @{$array[0]};
        }
        return List::Util::min(@array);
    });
    
    # Maximum value out of given array
    $app->ssi_handlers->{ep}->add_function(max => sub {
        my ($ep, @array) = @_;
        if (ref $array[0] && ref $array[0] eq 'ARRAY') {
            @array = @{$array[0]};
        }
        return List::Util::max(@array);
    });
    
    # Replace string
    $app->ssi_handlers->{ep}->add_function(replace => sub {
        my ($ep, $str, $search, $replace) = @_;
        if (ref $search && ref $search eq 'Regexp') {
            $str =~ s{$search}{$replace}g;
        } else {
            $str =~ s{\Q$search\E}{$replace}g;
        }
        return $str;
    });
    
}

1;

__END__

=head1 NAME

Marquee::Plugin::Router - Router [EXPERIMENTAL]

=head1 SYNOPSIS
    
    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/index\.html})->to(sub {
            ### DO SOMETHING
        });
        $r->route(qr{^/special\.html})->to(sub {
            ### DO SOMETHING
        });
        $r->route(qr{^/capture/(.+)-(.+)\.html})->to(sub {
            my ($a, $b) = @_;
            ### DO SOMETHING
        });
        $r->route(qr{^/rare/})->via('get')->to(sub {
            ### DO SOMETHING
        });
        $r->route(qr{^/default})->to(sub {
            ### DO SOMETHING
        });
    });

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 route

L<Marquee::Plugin::Router::Route> instance.

=head1 METHODS

=head2 $instance->register($app, $routes)

=head1 SEE ALSO

L<Marquee::Plugin::Router::Route>, L<Marquee>,
L<Mojolicious>

=cut

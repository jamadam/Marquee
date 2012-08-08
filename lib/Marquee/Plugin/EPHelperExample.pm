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

Marquee::Plugin::EPHelperExample - EPヘルパーの定義例

=head1 SYNOPSIS

    <%= commify($price) %>
    <%= min(@prices) %>
    <%= max(@prices) %>
    <%= replace($string, '::', '/') %>
    <%= replace($string, qr/\s/, '') %>

=head1 DESCRIPTION

これはEPテンプレート関数を追加するサンプルプラグインです。

=head1 METHODS

=head2 $instance->register($app, $routes)

=head1 SEE ALSO

L<Marquee::SSIHandler::EP>, L<Marquee>, L<Mojolicious>

=cut

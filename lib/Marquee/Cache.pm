package Marquee::Cache;
use strict;
use warnings;
use Mojo::Base -base;
    
    __PACKAGE__->attr('max_keys');
    
    my $ATTR_CACHE      = 1;
    my $ATTR_STACK      = 2;
    
    sub get {
        if (my $cache = $_[0]->{$ATTR_CACHE}->{$_[1]}) {
            if ($cache->[2]) {
                for my $code (@{$cache->[2]}) {
                    if ($code->($cache->[1])) {
                        delete $_[0]->{$ATTR_CACHE}->{$_[1]};
                        $_[0]->vacuum;
                        return;
                    }
                }
            }
            $cache->[0];
        }
    }
    
    sub vacuum {
        @{$_[0]->{$ATTR_STACK}} =
                    grep {$_[0]->{$ATTR_CACHE}->{$_}} @{$_[0]->{$ATTR_STACK}};
    }
    
    sub set {
        my ($self, $key, $value, $expire) = @_;
        
        my $max_keys    = $self->max_keys || 100;
        my $cache       = $self->{$ATTR_CACHE} ||= {};
        my $stack       = $self->{$ATTR_STACK} ||= [];
        
        while (@$stack >= $max_keys) {
            delete $cache->{shift @$stack};
        }
        
        if (delete $cache->{$key}) {
            $self->vacuum;
        }
        
        push @$stack, $key;
        
        $cache->{$key} = [
            $value,
            time,
            (ref $expire eq 'CODE') ? [$expire] : $expire
        ];
    }

1;

__END__

=head1 NAME

Marquee::Cache - Cache

=head1 SYNOPSIS

    use Marquee::Cache;
    
    $cache = Marquee::Cache->new;
    $cache->max_keys(2);
    $cache->set(foo => 'bar');
    $cache->get('foo');
    $cache->set(baz => 'yada', sub {
        my $cached_time = shift;
        return $cached_time < (stat $file)[9];
    });

=head1 DESCRIPTION

Simple cache manager with expire feature.

=head1 METHODS

=head2 Marquee::Cache->new

=head2 $instance->get($name)

Get cache value for given name.

=head2 $instance->set($name => $data)

Set cache values with given name and data.

    $cache->set(key, $data);
    $cache->set(key, $data, sub {...});
    $cache->set(key, $data, [sub {...}, sub {...}]);

=head2 $instance->vacuum()

Fixes mismatches between the cache table and stack table.

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

package Marquee::Cache;
use strict;
use warnings;
use Mojo::Base -base;
use feature 'signatures';
no warnings "experimental::signatures";

has 'max_keys';

my $ATTR_CACHE      = 1;
my $ATTR_STACK      = 2;

sub get($self, $key) {
    if (my $cache = $self->{$ATTR_CACHE}->{$key}) {
        if ($cache->[2] && $cache->[2]->($cache->[1])) {
            delete $self->{$ATTR_CACHE}->{$key};
            $self->_vacuum;
            return;
        }
        $cache->[0];
    }
}

sub _vacuum($self) {
    @{$self->{$ATTR_STACK}} =
                grep {$self->{$ATTR_CACHE}->{$_}} @{$self->{$ATTR_STACK}};
}

sub set($self, $key, $value, $expire=undef) {
    
    my $max_keys    = $self->{max_keys} || 100;
    my $cache       = $self->{$ATTR_CACHE} ||= {};
    my $stack       = $self->{$ATTR_STACK} ||= [];
    
    while (@$stack >= $max_keys) {
        delete $cache->{shift @$stack};
    }
    
    $self->_vacuum if (delete $cache->{$key});
    
    push @$stack, $key;
    
    $cache->{$key} = [$value, time, $expire];
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
    $cache->set(baz => 'yada', sub($cached_time) {
        return $cached_time < (stat $file)[9];
    });

=head1 DESCRIPTION

Simple cache manager with expire feature.

=head1 ATTRIBUTES

L<Marquee::Cache> implements the following attributes.

=head2 C<max_keys>

Max keys per instance.

    $cache->max_key(200);

=head1 INSTANCE METHODS

L<Marquee::Cache> implements the following instance methods.

=head2 C<get>

Get cache value for given name.

    my $data = $cache->get('foo');

=head2 C<set>

Set cache values with given name and data. By 3rd argument, you can set a
condition to expire the cache.

    $cache->set(key, $data);
    $cache->set(key, $data, sub($ts) {...});
    $cache->set(key, $data, [sub($ts) {...}, sub($ts) {...}]);

The coderef gets the cache timestamp in seconds since the epoch and can
return true for expire.

    my $expire = sub($ts) {
        return (time() - $ts > 86400)
    };

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

use strict;
use warnings;
use utf8;
use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Test::More;
use MojoSimpleHTTPServer::Stash;

    use Test::More tests => 5;

    my $stash = MojoSimpleHTTPServer::Stash->new(a => 'b', c => 'd');
    is_deeply $stash->(), {a => 'b', c => 'd'};
    
    $stash->(e => 'f');
    is_deeply $stash->(), {a => 'b', c => 'd', e => 'f'};
    
    $stash->(e => 'g');
    is_deeply $stash->(), {a => 'b', c => 'd', e => 'g'};
    
    my $clone = $stash->clone(h => 'i');
    is_deeply $clone->(), {a => 'b', c => 'd', e => 'g', h => 'i'};
    is_deeply $stash->(), {a => 'b', c => 'd', e => 'g'};

__END__

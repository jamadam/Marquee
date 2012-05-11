use strict;
use warnings;
use utf8;
use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Test::More;
use MojoSimpleHTTPServer::Stash;

    use Test::More tests => 12;

    my $stash = MojoSimpleHTTPServer::Stash->new(a => 'b', c => 'd');
    is_deeply $stash->(), {a => 'b', c => 'd'};
    
    $stash->(e => 'f');
    is_deeply $stash->(), {a => 'b', c => 'd', e => 'f'};
    
    $stash->(e => 'g');
    is_deeply $stash->(), {a => 'b', c => 'd', e => 'g'};
    
    my $clone = $stash->clone(e => 'h', i => 'j');
    is_deeply $clone->(), {a => 'b', c => 'd', e => 'h', i => 'j'};
    is_deeply $stash->(), {a => 'b', c => 'd', e => 'g'};
    
    is $stash->('a'), 'b';
    is $stash->('c'), 'd';
    is $stash->('e'), 'g';
    is $clone->('a'), 'b';
    is $clone->('c'), 'd';
    is $clone->('e'), 'h';
    is $clone->('i'), 'j';

__END__

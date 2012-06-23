use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), '../lib';
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';
use Test::More;
use Marquee::Stash;

    use Test::More tests => 12;

    my $stash = Marquee::Stash->new(a => 'b', c => 'd');
    is_deeply $stash->get(), {a => 'b', c => 'd'};
    
    $stash->set(e => 'f');
    is_deeply $stash->get(), {a => 'b', c => 'd', e => 'f'};
    
    $stash->set(e => 'g');
    is_deeply $stash->get(), {a => 'b', c => 'd', e => 'g'};
    
    my $clone = $stash->clone(e => 'h', i => 'j');
    is_deeply $clone->get(), {a => 'b', c => 'd', e => 'h', i => 'j'};
    is_deeply $stash->get(), {a => 'b', c => 'd', e => 'g'};
    
    is $stash->get('a'), 'b';
    is $stash->get('c'), 'd';
    is $stash->get('e'), 'g';
    is $clone->get('a'), 'b';
    is $clone->get('c'), 'd';
    is $clone->get('e'), 'h';
    is $clone->get('i'), 'j';

__END__

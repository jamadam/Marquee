use strict;
use warnings;
use feature 'signatures';
no warnings "experimental::signatures";
use Marquee::Types;

use Test::More tests => 4;

my $types = Marquee::Types->new;
$types->type(foo => 'text/foo');
is $types->type('foo'), 'text/foo';
$types->type(foo => 'text/foo; baz');
is $types->type('foo'), 'text/foo; baz';

is_deeply $types->detect('application/json;q=9'), ['json'];
is_deeply $types->detect('text/html, application/json;q=9', 1), ['json', 'htm', 'html'];

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 32;

use_ok 'MojoSimpleHTTPServer::Cache';

my $cache;

$cache = MojoSimpleHTTPServer::Cache->new;
$cache->max_keys(2);
$cache->set(foo => 'bar');
is $cache->get('foo'), 'bar', 'right result';
$cache->set(bar => 'baz');
is $cache->get('foo'), 'bar', 'right result';
is $cache->get('bar'), 'baz', 'right result';
$cache->set(baz => 'yada');
is $cache->get('foo'), undef,  'no result';
is $cache->get('bar'), 'baz',  'right result';
is $cache->get('baz'), 'yada', 'right result';
$cache->set(yada => 23);
is $cache->get('foo'),  undef,  'no result';
is $cache->get('bar'),  undef,  'no result';
is $cache->get('baz'),  'yada', 'right result';
is $cache->get('yada'), 23,     'right result';

$cache = MojoSimpleHTTPServer::Cache->new;
$cache->max_keys(3);
$cache->set(foo => 'bar');
is $cache->get('foo'), 'bar', 'right result';
$cache->set(bar => 'baz');
is $cache->get('foo'), 'bar', 'right result';
is $cache->get('bar'), 'baz', 'right result';
$cache->set(baz => 'yada');
is $cache->get('foo'), 'bar',  'right result';
is $cache->get('bar'), 'baz',  'right result';
is $cache->get('baz'), 'yada', 'right result';
$cache->set(yada => 23);
is $cache->get('foo'),  undef,  'no result';
is $cache->get('bar'),  'baz',  'right result';
is $cache->get('baz'),  'yada', 'right result';
is $cache->get('yada'), 23,     'right result';

$cache = MojoSimpleHTTPServer::Cache->new;
$cache->max_keys(10000);
$cache->set(foo => 'bar', sub{1});
is $cache->get('foo'), undef, 'has expired';

$cache = MojoSimpleHTTPServer::Cache->new;
$cache->max_keys(10000);
$cache->set(foo => 'bar', sub{
    my $ts = shift;
    is time - $ts, 1, '1 sec passed';
});
sleep(1);
is $cache->get('foo'), undef, 'has expired';

$cache = MojoSimpleHTTPServer::Cache->new();
is eval {$cache->get('a')} ,undef, 'non exist key';

# rewriting doesn't increase stack

$cache = MojoSimpleHTTPServer::Cache->new();
$cache->set(a => 'b');
$cache->set(a => 'c');
is keys %{$cache->{1}}, 1;
is scalar @{$cache->{2}}, 1;

# expired cache is vacuumed

$cache->set('b', 'd', sub {1});
is keys %{$cache->{1}}, 2;
is scalar @{$cache->{2}}, 2;
is $cache->get('b'), undef;
is keys %{$cache->{1}}, 1;
is scalar @{$cache->{2}}, 1;

#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec::Functions qw'catdir rel2abs splitdir';
use lib catdir(dirname(__FILE__), 'lib');
use lib catdir(dirname(__FILE__), 'examples/official-site/lib');
use MarqueeOfficial;

$ENV{MOJO_HOME} = rel2abs(dirname(__FILE__));

my $app = MarqueeOfficial->new(domain => 'http://mrqe.biz', locale => 'ja');
#$app->under_development(1);
$app->config(hypnotoad => {
    listen => ['http://*:8003'],
    pid_file => './official-site-ja.pid',
});
$app->start;

#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';

use Marquee;

my $app = Marquee->new;
$app->document_root(join '/', File::Spec->splitdir(dirname(__FILE__)), 'public_html');
$app->default_file('index.html');
$app->plugin('AutoIndex');
$app->start;

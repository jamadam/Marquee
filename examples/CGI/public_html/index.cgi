#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), '../lib';
use Marquee;

$ENV{MOJO_HOME} = File::Spec->rel2abs(dirname(__FILE__));

my $app = Marquee->new;
$app->document_root($app->home);
$app->log_file(File::Spec->rel2abs(dirname(__FILE__). "../log/Marquee.log");
$app->default_file('index.html');
$app->plugin('AutoIndex');
$app->start;

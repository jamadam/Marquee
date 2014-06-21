#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use FindBin;
use lib '../lib';
use Marquee;

my $app = Marquee->new;
$app->document_root("./");
$app->log_file("$FindBin::Bin/../log/Marquee.log");
$app->default_file('index.html');
$app->auto_index(1);
$app->start;

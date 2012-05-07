#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), 'lib';

use MojoSimpleHTTPServer;

my $app = MojoSimpleHTTPServer->new;
$app->document_root(join '/', File::Spec->splitdir(dirname(__FILE__)), 'public_html');
$app->default_file('index.html');
$app->auto_index(1);
$app->start;

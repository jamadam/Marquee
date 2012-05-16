#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), '../lib';
use MojoSimpleHTTPServer;

    my $app = MojoSimpleHTTPServer->new;
    $app->document_root("./");
    $app->log_file("$FindBin::Bin/../log/MojoSimpleHTTPServer.log");
    $app->default_file('index.html');
    $app->auto_index(1);
	$app->start;

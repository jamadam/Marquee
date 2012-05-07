#!/usr/bin/perl -w
use strict;
use warnings;
use utf8;
use FindBin;
use lib '../lib';
use MojoSimpleHTTPServer;

    my $app = MojoSimpleHTTPServer->new;
    $app->document_root("./");
    $app->log_file("$FindBin::Bin/../log/MojoSimpleHTTPServer.log");
    $app->default_file('index.html');
    $app->auto_index(1);
	$app->start;

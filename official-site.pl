#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';

use Marquee;

$ENV{MOJO_HOME} = File::Spec->rel2abs(dirname(__FILE__));

my $officical_domain = 'http://marquee.jamadam.com';

my $app = Marquee->new;

#$app->under_development(1);
$app->document_root($app->home->rel_dir('.'));
my $pod = $app->plugin(PODViewer => {no_route => 1, paths => ['./lib']});
my $md  = $app->plugin(Markdown => {no_route => 1});

$app->plugin(Router => sub {
    my $r = shift;
    $r->route(qr{^/(.+\.md)?$})->to(sub {
        $md->serve_markdown($app->search_static(shift || 'readme.md'));
        
        my $res = Marquee->c->tx->res;
        my $dom = $res->dom;
        $dom->find("a[href^=$officical_domain/]")->each(sub {
            my $e = shift;
            my $org = $e->attrs('href');
            $org =~ s{^\Q$officical_domain\E}{};
            $e->attrs('href', $org);
        });
        $res->body($dom);
    });
    $r->route(qr{^/perldoc/(.+)})->to(sub {
        $pod->serve_pod_by_name(shift);
    });
});

$app->config(hypnotoad => {listen => ['http://*:8002']});
$app->start;

use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), '../lib';
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;

use Test::More tests => 59;

my $app;
my $t;

{
    package MyApp;
    use Mojo::Base 'Marquee';
}

$app = MyApp->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$app->plugin(Router => sub {
    my $r = shift;
    $r->route(qr{^/index\.html})->to(sub {
        MyApp->context->app->serve_dynamic("$FindBin::Bin/public_html/index2.txt.ep");
        is $_[0], undef;
    });
    $r->route(qr{^/special\.html})->to(sub {
        MyApp->context->app->serve_static("$FindBin::Bin/public_html/index.txt");
    });
    $r->route(qr{^/capture/(.+)-(.+)\.html})->to(sub {
        my ($a, $b) = @_;
        is $a, 'foo';
        is $b, 'bar';
    });
    $r->route(qr{^/rare/})->via('get')->to(sub {
        MyApp->context->tx->res->code(200);
        MyApp->context->tx->res->body('rare');
    });
    $r->route(qr{^/rare2/})->via('get', 'head')->to(sub {
        MyApp->context->tx->res->code(200);
        MyApp->context->tx->res->body('rare');
    });
    $r->route(qr{^/default})->to(sub {
        MyApp->context->tx->res->code(200);
        MyApp->context->tx->res->body('default');
    });
});
$t = Test::Mojo->new($app);

$t->get_ok('/index.html')
    ->status_is(200)
    ->header_is('Content-Type', 'text/plain')
    ->header_is('Content-Length', 14)
    ->content_is('dynamicdynamic');

# twice

$t->get_ok('/index.html')
    ->status_is(200)
    ->header_is('Content-Type', 'text/plain')
    ->header_is('Content-Length', 14)
    ->content_is('dynamicdynamic');

# static

$t->get_ok('/dir1/index.html')
    ->status_is(200)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->header_is('Content-Length', 15)
    ->content_is('dir1/index.html');

$t->get_ok('/special.html')
    ->status_is(200)
    ->header_is('Content-Type', 'text/plain')
    ->header_is('Content-Length', 20)
    ->content_is('static <%= time() %>');

$t->get_ok('/capture/foo-bar.html');

$t->get_ok('/default.html')
    ->status_is(200)
    ->content_is('default');

$t->get_ok('/rare/')
    ->status_is(200)
    ->content_is('rare');

$t->head_ok('/rare/')
    ->status_is(404)
    ->element_exists_not('body#debugScreen');

$t->get_ok('/rare2/')
    ->status_is(200)
    ->content_is('rare');

$t->head_ok('/rare2/')
    ->status_is(200);

# bridge

$app = MyApp->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$app->plugin(Router => sub {
    my $r = shift;
    my $bridge = $r->bridge(sub {
        return 0;
    });
    $bridge->route(qr{^/index\.html})->to(sub {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->body('index.html for bridge');
        $res->headers->content_type('text/html;charset=UTF-8');
    });
    $r->route(qr{^/index\.html})->to(sub {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->body('index.html');
        $res->headers->content_type('text/html;charset=UTF-8');
    });
    my $bridge2 = $r->bridge(sub {
        my $tx = shift;
        return $tx->req->headers->user_agent =~ qr{iPhone};
    });
    $bridge2->route(qr{^/index2\.html})->to(sub {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->body('index2.html for iPhone');
        $res->headers->content_type('text/html;charset=UTF-8');
    });
    $r->route(qr{^/index2\.html})->to(sub {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->body('index2.html');
        $res->headers->content_type('text/html;charset=UTF-8');
    });
    $r->route(qr{^/index3\.html})->add_cond(sub {shift->req->headers->user_agent =~ qr{iPhone}})->to(sub {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->body('index3.html for iPhone');
        $res->headers->content_type('text/html;charset=UTF-8');
    });
    $r->route(qr{^/index3\.html})->to(sub {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->body('index3.html');
        $res->headers->content_type('text/html;charset=UTF-8');
    });
});
$t = Test::Mojo->new($app);

$t->get_ok('/index.html')
    ->status_is(200)
    ->header_is('Content-Length', 10)
    ->content_is('index.html');
$t->get_ok('/index2.html')
    ->status_is(200)
    ->header_is('Content-Length', 11)
    ->content_is('index2.html');
$t->get_ok('/index2.html', {'User-Agent' => 'iPhone'})
    ->status_is(200)
    ->header_is('Content-Length', 22)
    ->content_is('index2.html for iPhone');
$t->get_ok('/index3.html')
    ->status_is(200)
    ->header_is('Content-Length', 11)
    ->content_is('index3.html');
$t->get_ok('/index3.html', {'User-Agent' => 'iPhone'})
    ->status_is(200)
    ->header_is('Content-Length', 22)
    ->content_is('index3.html for iPhone');

__END__

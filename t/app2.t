use strict;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;

use Test::More tests => 82;

my $app;
my $t;

{
    package MyApp;
    use Mojo::Base 'Marquee';
}

$app = MyApp->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
{
    my $r = $app->route;
    $r->route(qr{^/index\.html})->to(sub() {
        MyApp->c->app->dynamic->serve("$FindBin::Bin/public_html/index2.txt.ep");
        is $_[0], undef;
    });
    $r->route(qr{^/special\.html})->to(sub() {
        MyApp->c->app->static->serve("$FindBin::Bin/public_html/index.txt");
    });
    $r->route(qr{^/capture/(.+)-(.+)})->to(sub($a, $b) {
        MyApp->c->res->code(200);
        MyApp->c->res->body("$a-$b");
    });
    $r->route(qr{^/capture2/(.+)?-(.+)})->to(sub($a, $b) {
        MyApp->c->res->code(200);
        $a = defined $a ? $a : '';
        MyApp->c->res->body("$a-$b");
    });
    $r->route(qr{^/capture3/(.+)?})->to(sub($a) {
        MyApp->c->res->code(200);
        $a = defined $a ? $a : '';
        MyApp->c->res->body("$a");
    });
    $r->route(qr{^/rare/})->via('get')->to(sub() {
        MyApp->c->res->code(200);
        MyApp->c->res->body('rare');
    });
    $r->route(qr{^/rare2/})->via('get', 'head')->to(sub() {
        MyApp->c->res->code(200);
        MyApp->c->res->body('rare');
    });
    $r->route(qr{^/default})->to(sub() {
        MyApp->c->res->code(200);
        MyApp->c->res->body('default');
    });
    $r->route(qr{^/serve1})->to(sub() {
        MyApp->c->serve('router1.html');
    });
    $r->route(qr{^/serve1-2})->to(sub() {
        MyApp->c->serve;
    });
    $r->route(qr{^/serve2})->to(sub() {
        MyApp->c->serve('router2.html');
    });
    $r->route(qr{^/serve3})->to(sub() {
        MyApp->c->serve('router3.html');
    });
    $r->route(qr{^/router4.html})->to(sub() {
        # not served
    });
    $r->route(qr{^/router5.html})->viax('post')->to(sub() {
        MyApp->c->serve('router5.html');
    });
    $r->route(qr{^/json.json})->to(sub() {
        MyApp->c->res->code(200);
        MyApp->c->res->body(Mojo::JSON::encode_json({a => 1}));
    });
}
$t = Test::Mojo::DOM->new($app);

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

$t->get_ok('/capture/foo-bar')
    ->content_is('foo-bar');

$t->get_ok('/capture2/-bar')
    ->content_is('-bar');

$t->get_ok('/capture3/bar')
    ->content_is('bar');

$t->get_ok('/capture3/')
    ->content_is('');

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

$t->get_ok('/serve1/')
    ->status_is(200)
    ->text_is('filename', 'router1.html.ep')
    ->text_is('test1', 'ok');

$t->get_ok('/serve1-2/')
    ->status_is(200)
    ->text_is('filename', 'router1.html.ep')
    ->text_is('test1', 'ok');

$t->get_ok('/serve2/')
    ->status_is(200)
    ->text_is('filename', 'router2.html.ep')
    ->text_is('test1', 'ok');

$t->get_ok('/serve3/')
    ->status_is(200)
    ->text_is('filename', 'router3.html');

$t->get_ok('/router4.html')
    ->status_is(404)
    ->text_is('title', '404 File Not Found');

$t->post_ok('/router5.html')
    ->status_is(200);

$t->get_ok('/router5.html')
    ->status_is(404);

$t->get_ok('/json.json')
    ->status_is(200)
    ->header_is('Content-Type', 'application/json')
    ->content_is(q!{"a":1}!);

# bridge

$app = MyApp->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
{
    my $r = $app->route;
    my $bridge = $r->bridge(sub($c) {
        return 0;
    });
    $bridge->route(qr{^/index\.html})->to(sub() {
        my $res = Marquee->c->res;
        $res->code(200);
        $res->body('index.html for bridge');
    });
    $r->route(qr{^/index\.html})->to(sub() {
        my $res = Marquee->c->res;
        $res->code(200);
        $res->body('index.html');
    });
    my $bridge2 = $r->bridge(sub($c) {
        return $c->req->headers->user_agent =~ qr{iPhone};
    });
    $bridge2->route(qr{^/index2\.html})->to(sub() {
        my $res = Marquee->c->res;
        $res->code(200);
        $res->body('index2.html for iPhone');
    });
    $r->route(qr{^/index2\.html})->to(sub() {
        my $res = Marquee->c->res;
        $res->code(200);
        $res->body('index2.html');
    });
};
$t = Test::Mojo::DOM->new($app);

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


__END__

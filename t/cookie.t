use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Test::Mojo::DOM;
use Marquee;
use Mojo::Date;

use Test::More tests => 79;

my $app;
my $t;
my $t2;
$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->default_file('index.html');
{
    my $r = $app->route;
    $r->route(qr{^/session_cookie/2})->to(sub {
        my $req     = Marquee->c->req;
        my $res     = Marquee->c->res;
        my $session = $req->cookie('session');
        my $value   = $session ? $session->value : 'missing';
        $res->body("Session is $value!");
        $res->code(200);
    });
    $r->route(qr{^/session_cookie})->to(sub {
        my $res = Marquee->c->res;
        $res->body('Cookie set!');
        $res->code(200);
        $res->cookies(
            Mojo::Cookie::Response->new(
              path  => '/session_cookie',
              name  => 'session',
              value => '23'
            )
        );
    });
}

$t = Test::Mojo->new($app);

# GET /session_cookie
$t->get_ok('/session_cookie')
    ->status_is(200)
    ->header_is('Set-Cookie', 'session=23; path=/session_cookie')
    ->content_is('Cookie set!');

# GET /session_cookie/2
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is 23!');

# GET /session_cookie/2 (retry)
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is 23!');

# GET /session_cookie/2 (session reset)
$t->reset_session;
ok !$t->tx, 'session reset';
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is missing!');

### cookie by context methods

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->default_file('index.html');
{
    my $r = $app->route;
    $r->route(qr{^/session_cookie/2})->to(sub {
        my $res     = Marquee->c->res;
        my $session = Marquee->c->cookie('session');
        my $value   = $session ? $session : 'missing';
        $res->body("Session is $value!");
        $res->code(200);
    });
    $r->route(qr{^/session_cookie})->to(sub {
        my $res = Marquee->c->res;
        $res->body('Cookie set!');
        $res->code(200);
        Marquee->c->cookie('session', '23', {path  => '/session_cookie'});
    });
};

$t = Test::Mojo->new($app);

# GET /session_cookie
$t->get_ok('/session_cookie')
    ->status_is(200)
    ->header_is('Set-Cookie', 'session=23; path=/session_cookie')
    ->content_is('Cookie set!');

# GET /session_cookie/2
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is 23!');

# GET /session_cookie/2 (retry)
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is 23!');

# GET /session_cookie/2 (session reset)
$t->reset_session;
ok !$t->tx, 'session reset';
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is missing!');

### signed cookie by context methods

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->default_file('index.html');
$app->secrets(['aaaaaaaaaaaaaa']);
{
    my $r = $app->route;
    $r->route(qr{^/session_cookie/2})->to(sub {
        my $res     = Marquee->c->res;
        my $session = Marquee->c->signed_cookie('session');
        my $value   = $session ? $session : 'missing';
        $res->body("Session is $value!");
        $res->code(200);
    });
    $r->route(qr{^/session_cookie})->to(sub {
        my $res = Marquee->c->res;
        $res->body('Cookie set!');
        $res->code(200);
        Marquee->c->signed_cookie('session', '23', {path  => '/session_cookie'});
    });
}

$t = Test::Mojo->new($app);

# GET /session_cookie
$t->get_ok('/session_cookie')
    ->status_is(200)
    ->header_is('Set-Cookie', 'session=23--d53c3020cb6eb007b28f3ef32c15d8d5d20a3047; path=/session_cookie')
    ->content_is('Cookie set!');

# GET /session_cookie/2
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is 23!');

# GET /session_cookie/2 (retry)
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is 23!');

$app->secrets(['new-secret', 'aaaaaaaaaaaaaa']);

# GET /session_cookie/2 (retry after secret rotated)
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is 23!');

$app->secrets(['new-secret2', 'new-secret']);

# GET /session_cookie/2 (retry after secret outdated)
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is missing!');

$app->secrets(['new-secret', 'aaaaaaaaaaaaaa']);

# GET /session_cookie/2 (retry after secret resumed)
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is 23!');

# GET /session_cookie/2 (session reset)
$t->reset_session;
ok !$t->tx, 'session reset';
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is missing!');

### session data

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->default_file('index.html');
$app->secrets(['aaaaaaaaaaaaaa']);
{
    my $r = $app->route;
    $r->route(qr{^/session_cookie/2})->to(sub {
        my $res     = Marquee->c->res;
        my $session = Marquee->c->session;
        my $value   = $session->{test} || 'missing';
        $res->body("Session is $value!");
        $res->code(200);
    });
    $r->route(qr{^/session_cookie/3})->to(sub {
        my $res = Marquee->c->res;
        $res->body('Session deleted!');
        $res->code(200);
        Marquee->c->session(undef);
    });
    $r->route(qr{^/session_cookie})->to(sub {
        my $res = Marquee->c->res;
        $res->body('Session set!');
        $res->code(200);
        Marquee->c->session({test => 'session test'});
    });
}

$t = Test::Mojo->new($app);
$t2 = Test::Mojo->new($app);

# GET /session_cookie
$t->get_ok('/session_cookie')
    ->status_is(200)
    ->header_like('Set-Cookie', qr{^mrqe=eyJ0ZXN0Ijoic2Vzc2lvbiB0ZXN0In0---164ff366836b4cb8a3617acf1a43164cc4319667;})
    ->content_is('Session set!');

# GET /session_cookie/2
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is session test!');

# GET /session_cookie/2 (stranger)
$t2->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is missing!');

# GET /session_cookie/2 (retry)
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is session test!');

# GET /session_cookie/2 (session reset)
$t->reset_session;
ok !$t->tx, 'session reset';
$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is missing!');

$t->get_ok('/session_cookie')
    ->status_is(200)
    ->header_like('Set-Cookie', qr{^mrqe=eyJ0ZXN0Ijoic2Vzc2lvbiB0ZXN0In0---164ff366836b4cb8a3617acf1a43164cc4319667;})
    ->content_is('Session set!');

$t->get_ok('/session_cookie/3')->status_is(200)
    ->header_is('Set-Cookie', 'mrqe=; expires=Thu, 01 Jan 1970 00:00:01 GMT; path=/; HttpOnly')
    ->content_is('Session deleted!');

$t->get_ok('/session_cookie/2')->status_is(200)
    ->content_is('Session is missing!');
    
__END__

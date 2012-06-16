package Template_Basic;
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
use MojoSimpleHTTPServer;
use Mojo::Date;
    
    use Test::More tests => 70;

    my $app;
    my $t;
    my $t2;
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $app->default_file('index.html');

    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/session_cookie/2})->to(sub {
            my $req     = $MSHS::CONTEXT->tx->req;
            my $res     = $MSHS::CONTEXT->tx->res;
            my $session = $req->cookie('session');
            my $value   = $session ? $session->value : 'missing';
            $res->body("Session is $value!");
            $res->code(200);
        });
        $r->route(qr{^/session_cookie})->to(sub {
            my $res = $MSHS::CONTEXT->tx->res;
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
    });

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
    
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $app->default_file('index.html');

    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/session_cookie/2})->to(sub {
            my $req     = $MSHS::CONTEXT->tx->req;
            my $res     = $MSHS::CONTEXT->tx->res;
            my $session = $MSHS::CONTEXT->cookie('session');
            my $value   = $session ? $session : 'missing';
            $res->body("Session is $value!");
            $res->code(200);
        });
        $r->route(qr{^/session_cookie})->to(sub {
            my $res = $MSHS::CONTEXT->tx->res;
            $res->body('Cookie set!');
            $res->code(200);
            $MSHS::CONTEXT->cookie('session', '23', {path  => '/session_cookie'});
        });
    });

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
    
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $app->default_file('index.html');
    $app->secret('aaaaaaaaaaaaaa');
    
    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/session_cookie/2})->to(sub {
            my $req     = $MSHS::CONTEXT->tx->req;
            my $res     = $MSHS::CONTEXT->tx->res;
            my $session = $MSHS::CONTEXT->signed_cookie('session');
            my $value   = $session ? $session : 'missing';
            $res->body("Session is $value!");
            $res->code(200);
        });
        $r->route(qr{^/session_cookie})->to(sub {
            my $res = $MSHS::CONTEXT->tx->res;
            $res->body('Cookie set!');
            $res->code(200);
            $MSHS::CONTEXT->signed_cookie('session', '23', {path  => '/session_cookie'});
        });
    });

    $t = Test::Mojo->new($app);
    
    # GET /session_cookie
    $t->get_ok('/session_cookie')
        ->status_is(200)
        ->header_is('Set-Cookie', 'session=23--4b29072a4de04717618b2ec10e2e60be; path=/session_cookie')
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
    
    ### session data
    
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $app->default_file('index.html');
    $app->secret('aaaaaaaaaaaaaa');
    
    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/session_cookie/2})->to(sub {
            my $req     = $MSHS::CONTEXT->tx->req;
            my $res     = $MSHS::CONTEXT->tx->res;
            my $session = $MSHS::CONTEXT->session;
            my $value   = $session->{test} || 'missing';
            $res->body("Session is $value!");
            $res->code(200);
        });
        $r->route(qr{^/session_cookie/3})->to(sub {
            my $res = $MSHS::CONTEXT->tx->res;
            $res->body('Session deleted!');
            $res->code(200);
            $MSHS::CONTEXT->session(undef);
        });
        $r->route(qr{^/session_cookie})->to(sub {
            my $res = $MSHS::CONTEXT->tx->res;
            $res->body('Session set!');
            $res->code(200);
            $MSHS::CONTEXT->session({test => 'session test'});
        });
    });

    $t = Test::Mojo->new($app);
    $t2 = Test::Mojo->new($app);
    
    # GET /session_cookie
    $t->get_ok('/session_cookie')
        ->status_is(200)
        ->header_like('Set-Cookie', qr{^mshs=eyJ0ZXN0Ijoic2Vzc2lvbiB0ZXN0In0---9a77f38057310a620345c9c300fc2ea1;})
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
        ->header_like('Set-Cookie', qr{^mshs=eyJ0ZXN0Ijoic2Vzc2lvbiB0ZXN0In0---9a77f38057310a620345c9c300fc2ea1;})
        ->content_is('Session set!');
    
    $t->get_ok('/session_cookie/3')->status_is(200)
        ->header_is('Set-Cookie', 'mshs=; expires=Thu, 01 Jan 1970 00:00:01 GMT; path=/; HttpOnly')
        ->content_is('Session deleted!');
    
    $t->get_ok('/session_cookie/2')->status_is(200)
        ->content_is('Session is missing!');
    
__END__

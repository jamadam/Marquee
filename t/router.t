use strict;
use warnings;
use utf8;
use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;
    
    use Test::More tests => 66;

    my $app;
    my $t;
    
    {
        package MyApp;
        use Mojo::Base 'MojoSimpleHTTPServer';
    }
    
    $app = MyApp->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    $app->plugin(Router => [
        qr{^/index\.html} => sub {
            MyApp->context->app->serve_dynamic("$FindBin::Bin/public_html/index2.txt");
            is $_[0], undef;
        },
        qr{^/special\.html} => sub {
            MyApp->context->app->serve_static("$FindBin::Bin/public_html/index.txt");
        },
        qr{^/capture/(.+)-(.+)\.html} => sub {
            my ($a, $b) = @_;
            is $a, 'foo';
            is $b, 'bar';
        },
        qr{^/rare/} => {method => 'get'}, sub {
            MyApp->context->tx->res->code(200);
            MyApp->context->tx->res->body('rare');
        },
        qr{^/default} => sub {
            MyApp->context->tx->res->code(200);
            MyApp->context->tx->res->body('default');
        },
    ]);
    
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
        ->status_is(404);
    
    ### another syntax of the plugin
    
    $app = MyApp->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/index\.html})->to(sub {
            MyApp->context->app->serve_dynamic("$FindBin::Bin/public_html/index2.txt");
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
        ->status_is(404);

__END__

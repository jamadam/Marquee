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
    
    use Test::More tests => 55;

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
            MyApp->context->app->serve_dynamic("$FindBin::Bin/public_html/index2.txt.ep");
            is $_[0], undef;
        });
        
        $r->route(qr{^/index\.html})->to(sub {
            MyApp->context->app->serve_static("$FindBin::Bin/public_html/index.txt");
            is $_[0], undef;
        });
    });
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/index.html')
        ->status_is(200)
        ->header_is('Content-Type', 'text/plain')
        ->header_is('Content-Length', 20)
        ->content_is('static <%= time() %>');
    
    ### Basic Auth
    
    $app = Marquee->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/Marquee.log");
    
    $app->plugin(Router => sub {
        my $r = shift;
        
        my $auth = $r->basic_auth('Secret Area' => sub {
            $_[0] eq 'user' && $_[1] eq 'pass';
        });
        
        $auth->route(qr{^/index\.html})->to(sub {
            Marquee->c->app->serve_dynamic("$FindBin::Bin/public_html/index2.txt.ep");
            is $_[0], undef;
        });
    });
    
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/index.html')
        ->status_is(401)
        ->header_is('www-authenticate', 'Basic realm=Secret Area');
    
    $t->get_ok('/index.html', {Authorization => "Basic dXNlcjpwYXNzMg=="})
        ->status_is(401)
        ->header_is('www-authenticate', 'Basic realm=Secret Area');
    
    $t->get_ok('/index.html', {Authorization => "Basic dXNlcjpwYXNz"})
        ->status_is(200)
        ->content_is('dynamicdynamic');

__END__

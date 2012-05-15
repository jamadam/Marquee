use strict;
use warnings;
use utf8;
use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;
    
    use Test::More tests => 15;

    my $app;
    my $t;
    
    {
        package MyApp;
        use Mojo::Base 'MojoSimpleHTTPServer';
    }
    
    $app = MyApp->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    $app->plugin(Router => {
        qr{^/index\.html} => sub {
            MyApp->context->app->serve_dynamic("$FindBin::Bin/public_html/index2.txt");
        },
        qr{^/special\.html} => sub {
            MyApp->context->app->serve_static("$FindBin::Bin/public_html/index.txt");
        },
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

__END__

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
    
    $app->load_plugin(Router => {
        qr/index\.html/ => sub {
            MyApp->context->app->serve_static("$FindBin::Bin/public_html/index.txt");
        },
        qr/special\.html/ => sub {
            MyApp->context->app->serve_static("$FindBin::Bin/public_html/index.txt");
        },
    });
    
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/index.html')
        ->status_is(200)
        ->header_is('Content-Type', 'text/plain')
        ->header_is('Content-Length', 20)
        ->content_is('static <%= time() %>');
    
    # twice
    
    $t->get_ok('/index.html')
        ->status_is(200)
        ->header_is('Content-Type', 'text/plain')
        ->header_is('Content-Length', 20)
        ->content_is('static <%= time() %>');
    
    $t->get_ok('/special.html')
        ->status_is(200)
        ->header_is('Content-Type', 'text/plain')
        ->header_is('Content-Length', 20)
        ->content_is('static <%= time() %>');

__END__

use strict;
use warnings;
use utf8;
use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;
    
    use Test::More tests => 21;

    my $app;
    my $t;
    
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    eval {
        $app->around_method_hook(serve_static => sub {});
    };
    ok $@, 'not accest';
    
    $app = MyApp->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    $app->around_method_hook(serve_static => sub {
        my ($app, $next, @args) = @_;
        $next->(@args);
        my $org = $MojoSimpleHTTPServer::CONTEXT->tx->res->body;
        $MojoSimpleHTTPServer::CONTEXT->tx->res->body($org.'mod');
        return $app;
    });
    
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/index.txt')
        ->status_is(200)
        ->content_type_is('text/plain')
        ->header_is('Content-Length', 23)
        ->content_is('static <%= time() %>mod');
    
    $app->around_method_hook(serve_static => sub {
        my ($app, $next, @args) = @_;
        $next->(@args);
        my $org = $MojoSimpleHTTPServer::CONTEXT->tx->res->body;
        $MojoSimpleHTTPServer::CONTEXT->tx->res->body($org.'mod2');
        return $app;
    });
    
    $t->get_ok('/index.txt')
        ->status_is(200)
        ->content_type_is('text/plain')
        ->header_is('Content-Length', 27)
        ->content_is('static <%= time() %>modmod2');
    
    $app = MyApp2->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    $app->around_method_hook(serve_static => sub {
        my ($app, $next, @args) = @_;
        $next->(@args);
        my $org = $MojoSimpleHTTPServer::CONTEXT->tx->res->body;
        $MojoSimpleHTTPServer::CONTEXT->tx->res->body($org.'mod');
        return $app;
    });

    $t = Test::Mojo->new($app);
    
    $t->get_ok('/index.txt')
        ->status_is(200)
        ->content_type_is('text/plain')
        ->header_is('Content-Length', 23)
        ->content_is('static <%= time() %>mod');
    
    $app->around_method_hook(serve_static => sub {
        my ($app, $next, @args) = @_;
        $next->(@args);
        my $org = $MojoSimpleHTTPServer::CONTEXT->tx->res->body;
        $MojoSimpleHTTPServer::CONTEXT->tx->res->body($org.'mod2');
        return $app;
    });
    
    $t->get_ok('/index.txt')
        ->status_is(200)
        ->content_type_is('text/plain')
        ->header_is('Content-Length', 27)
        ->content_is('static <%= time() %>modmod2');

package MyApp;
use Mojo::Base 'MojoSimpleHTTPServer';

    sub serve_static {
        shift->SUPER::serve_static(@_);
    }

package MyApp2;
use Mojo::Base 'MojoSimpleHTTPServer';
    
__END__

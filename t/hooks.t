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
    
    use Test::More tests => 17;

    my $app;
    my $t;
    
    $app = MyApp->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    $app->hook(around_static => my $hook1 = sub {
        my ($next, @args) = @_;
        $next->(@args);
        my $org = $MSHS::CONTEXT->tx->res->body;
        $MSHS::CONTEXT->tx->res->body($org.'mod');
        return $app;
    });
    
    $app->hook(around_static => my $hook2 = sub {
        my ($next, @args) = @_;
        $next->(@args);
        my $org = $MSHS::CONTEXT->tx->res->body;
        $MSHS::CONTEXT->tx->res->body($org.'mod2');
        return $app;
    });
    
    is $app->hooks->subscribers('around_static')->[1], $hook1, 'right hook order';
    is $app->hooks->subscribers('around_static')->[2], $hook2, 'right hook order';
    
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/index.txt')
        ->status_is(200)
        ->content_type_is('text/plain')
        ->header_is('Content-Length', 27)
        ->content_is('static <%= time() %>modmod2');
    
    $app = MyApp2->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    $app->hook(around_static => sub {
        my ($next, @args) = @_;
        $next->(@args);
        my $org = $MSHS::CONTEXT->tx->res->body;
        $MSHS::CONTEXT->tx->res->body($org.'mod');
        return $app;
    });

    $t = Test::Mojo->new($app);
    
    $t->get_ok('/index.txt')
        ->status_is(200)
        ->content_type_is('text/plain')
        ->header_is('Content-Length', 23)
        ->content_is('static <%= time() %>mod');
    
    $app->hook(around_static => sub {
        my ($next, @args) = @_;
        $next->(@args);
        my $org = $MSHS::CONTEXT->tx->res->body;
        $MSHS::CONTEXT->tx->res->body($org.'mod2');
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

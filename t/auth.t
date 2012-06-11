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
use MojoSimpleHTTPServer;

    use Test::More tests => 10;

    my $app;
    my $t;
    
    ### another syntax of the plugin
    
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
        
    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/index\.html})->to(sub {
            MSHS->context->app->serve_dynamic("$FindBin::Bin/public_html/index2.txt.ep");
            is $_[0], undef;
        });
    });
    
    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/index\.html})->basic_auth('Secret Area' => sub {
            $_[0] eq 'user' && $_[1] eq 'pass'
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

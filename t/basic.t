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
    
    use Test::More tests => 117;
    
    {
        use Mojo::Transaction::HTTP;
        my $app = MojoSimpleHTTPServer->new;
        my $tx = Mojo::Transaction::HTTP->new;
        $app->document_root("$FindBin::Bin/public_html");
        $app->_init;
        local $MSHS::CONTEXT = MojoSimpleHTTPServer::Context->new(app => $app, tx => $tx);
        is $app->search_template('index.html'), "$FindBin::Bin/public_html/index.html.ep";
        is $app->search_template('./index.html'), "$FindBin::Bin/public_html/index.html.ep";
        is $app->search_template("$FindBin::Bin/public_html/index.html"), "$FindBin::Bin/public_html/index.html.ep";
    }

    my $app;
    my $t;
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $app->default_file('index.html');

    $t = Test::Mojo->new($app);
    
    $t->get_ok('/dir1')
        ->status_is(301)
        ->header_is('Content-Length', 0)
        ->header_like(Location => qr{/dir1/$});
    $t->get_ok('/static')
        ->status_is(301)
        ->header_is('Content-Length', 0)
        ->header_like(Location => qr{/static/$});
    $t->get_ok('/nonexists.html')
        ->status_is(404)
        ->element_exists_not('body#debugScreen')
        ->content_like(qr'404 file not found'i);
    $t->get_ok('/')
        ->status_is(200)
        ->content_type_is('text/html;charset=UTF-8')
        ->header_is('Content-Length', 25)
        ->content_like(qr{index.html.ep \d+\n});
    $t->get_ok('/index.html.ep')
        ->status_is(403)
        ->content_type_is('text/html;charset=UTF-8')
        ->element_exists_not('body#debugScreen')
        ->content_like(qr'403 forbidden'i);
    $t->get_ok('/index.html')
        ->status_is(200)
        ->content_type_is('text/html;charset=UTF-8')
        ->header_is('Content-Length', 25)
        ->content_like(qr{index.html.ep \d+\n});
    $t->get_ok('/index.txt')
        ->status_is(200)
        ->content_type_is('text/plain')
        ->header_is('Content-Length', 20)
        ->content_is(qq{static <%= time() %>});
    $t->get_ok('/dir1/')
        ->status_is(200)
        ->content_type_is('text/html;charset=UTF-8')
        ->header_is('Content-Length', 15)
        ->content_is(qq{dir1/index.html});
    $t->get_ok('/dir1/index.html')
        ->status_is(200)
        ->content_type_is('text/html;charset=UTF-8')
        ->header_is('Content-Length', 15)
        ->content_is(qq{dir1/index.html});
    $t->get_ok('/dir1/dynamic.html')
        ->status_is(200)
        ->content_type_is('text/html;charset=UTF-8')
        ->header_is('Content-Length', 29)
        ->content_like(qr{dir1/dynamic.html \d+\n});
    $t->get_ok('/dir1/dynamic.json')
        ->status_is(200)
        ->content_type_is('application/json')
        ->header_is('Content-Length', 18)
        ->content_is(qq{{"dynamic":"json"}});
    $t->get_ok('/dir1/static.json')
        ->status_is(200)
        ->content_type_is('application/json')
        ->header_is('Content-Length', 17)
        ->content_is(qq{{"static":"json"}});
    $t->get_ok('/dynamic.txt')
        ->status_is(200)
        ->content_type_is('text/plain')
        ->header_is('Content-Length', 19)
        ->content_like(qr{dynamic \d+\n});
    $t->get_ok('/index.unknown')
        ->status_is(200)
        ->header_is('Content-Type', undef)
        ->header_is('Content-Length', 14)
        ->content_is('unknown format');
    $t->get_ok('/index4.html.pub')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=UTF-8')
        ->header_is('Content-Length', 15)
        ->content_is('index4.html.pub');
    $t->get_ok('/..%2f/basic.t')
        ->status_is(404)
        ->element_exists_not('body#debugScreen');
    $t->get_ok('/dir1/..%2f/..%2f/basic.t')
        ->status_is(404);
    $t->get_ok('/dir1/.%2findex.html')
        ->status_is(200)
        ->content_type_is('text/html;charset=UTF-8')
        ->header_is('Content-Length', 15)
        ->content_is(qq{dir1/index.html});
    
    # auto escape activation
    
    $t->get_ok('/auto_escape1.html')
        ->content_is('&amp;');
    $t->get_ok('/auto_escape2.html')
        ->content_is('<');
    
    ### stash
    
    $app->stash->set(baz => 'BAZ');
    
    $t->get_ok('/stash.html')
        ->status_is(200)
        ->text_is('filename', 'stash.html.ep')
        ->text_is('test1', 'BAZ');
    
    ### adding template handler tests
    
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    {
        package _TestHandler;
        use Mojo::Base 'MojoSimpleHTTPServer::SSIHandler';
        sub render {return $_[1]}
    }
    {
        package _Test2Handler;
        use Mojo::Base 'MojoSimpleHTTPServer::SSIHandler';
        sub render {return 'rendered'}
    }
    
    $app->add_handler(test => _TestHandler->new);
    $app->add_handler(test2 => _Test2Handler->new);
    
    $t = Test::Mojo->new($app);

    $t->get_ok('/index2.html')
        ->status_is(200)
        ->content_is("$FindBin::Bin/public_html/index2.html.test");
    $t->get_ok('/index3.html')
        ->status_is(200)
        ->element_exists_not('body#debugScreen')
        ->content_is("rendered");
    $t->get_ok('/index2.html.test')
        ->status_is(403)
        ->element_exists_not('body#debugScreen')
        ->content_like(qr"403 Forbidden"i);
    $t->get_ok('/index3.html.test2')
        ->status_is(403)
        ->content_like(qr"403 Forbidden"i);
    
    ### if-modified-since
    
    my $mtime = Mojo::Date->new((stat "$FindBin::Bin/public_html/index.txt")[9]);
    $t->get_ok('/index.txt')
        ->status_is(200)
        ->header_is('Content-Length', 20)
        ->header_is('Last-Modified', $mtime);
    $t->get_ok('/index.txt', {'If-Modified-Since' => $mtime})
        ->status_is(304)
        ->header_is('Content-Length', 0);
    
    ### add mime type
    
    $app->types->type('unknown' => 'text/unknown');
    
    $t->get_ok('/index.unknown')
        ->status_is(200)
        ->header_is('Content-Type', 'text/unknown');

__END__

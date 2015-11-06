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
use Test::Path 'path_is';
use Marquee;
use Mojo::Date;
use Mojo::Transaction::HTTP;
use Mojo::URL;

use Test::More tests => 154;

{
    my $app = Marquee->new;
    my $tx = Mojo::Transaction::HTTP->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->_init;
    local $Marquee::CONTEXT = Marquee::Context->new(app => $app, tx => $tx);
    $tx->req->url(Mojo::URL->new('http://localhost/path/'));
    is $app->to_abs('http://example.com/foo/?a=b'), 'http://example.com/foo/?a=b';
    is $app->to_abs('/foo/'), 'http://localhost/foo/';
    is $app->to_abs('foo/'), 'http://localhost/path/foo/';
    is $app->to_abs('./foo/'), 'http://localhost/path/foo/';
    is $app->to_abs('../foo/'), 'http://localhost/foo/';
    is $app->to_abs('foo/?a=b'), 'http://localhost/path/foo/?a=b';
    $tx->req->url(Mojo::URL->new('http://user:pass@localhost/path/'));
    is $app->to_abs('http://example.com/foo/?a=b'), 'http://example.com/foo/?a=b';
    is $app->to_abs('/foo/'), 'http://localhost/foo/';
    is $app->to_abs('foo/'), 'http://localhost/path/foo/';
    is $app->to_abs('./foo/'), 'http://localhost/path/foo/';
    is $app->to_abs('../foo/'), 'http://localhost/foo/';
    is $app->to_abs('foo/?a=b'), 'http://localhost/path/foo/?a=b';
}

{
    my $app = Marquee->new;
    my $tx = Mojo::Transaction::HTTP->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->_init;
    local $Marquee::CONTEXT = Marquee::Context->new(app => $app, tx => $tx);
    path_is $app->dynamic->search('index.html'), "$FindBin::Bin/public_html/index.html.ep";
    path_is $app->dynamic->search('./index.html'), "$FindBin::Bin/public_html/index.html.ep";
    path_is $app->dynamic->search("$FindBin::Bin/public_html/index.html"), "$FindBin::Bin/public_html/index.html.ep";
}

my $app;
my $t;

# undefined default_file

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$t = Test::Mojo->new($app);

$t->get_ok('/')
    ->status_is(404);
$t->get_ok('/dir1/')
    ->status_is(404);

# basic

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
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
    ->status_is(400)
    ->element_exists_not('body#debugScreen');
$t->get_ok('/dir1/..%2f/..%2f/basic.t')
    ->status_is(400);
$t->get_ok('/dir1/.%2findex.html')
    ->status_is(200)
    ->content_type_is('text/html;charset=UTF-8')
    ->header_is('Content-Length', 15)
    ->content_is(qq{dir1/index.html});
$t->get_ok('/jquery.1.10.1.js')
    ->status_is(200)
    ->header_is('Content-Type', 'application/javascript');
$t->get_ok('/serve.json')
    ->status_is(200)
    ->header_is('Content-Type', 'application/json')
    ->content_is(q!{"a":1}!);

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

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

{
    package _TestHandler;
    use Mojo::Base 'Marquee::SSIHandler';
    sub render {return $_[1]}
}
{
    package _Test2Handler;
    use Mojo::Base 'Marquee::SSIHandler';
    sub render {return 'rendered'}
}

$app->dynamic->add_handler(test => _TestHandler->new);
$app->dynamic->add_handler(test2 => _Test2Handler->new);

$t = Test::Mojo->new($app);

$t->get_ok('/index2.html')
    ->status_is(200);
path_is $t->tx->res->body, "$FindBin::Bin/public_html/index2.html.test";
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

### path base

{
    local $ENV{'MOJO_HOME'} = "$FindBin::Bin/public_html";
    local $ENV{'DOCUMENT_ROOT'} = canonpath($FindBin::Bin);
    $app = Marquee->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/Marquee.log");
    $t = Test::Mojo->new($app);
    $t->get_ok('/path_base.html');
    path_is $app->home, "$FindBin::Bin/public_html";
    path_is $ENV{'MARQUEE_BASE_PATH'}, "/public_html";
}
{
    local $ENV{'MARQUEE_BASE_PATH'} = '/base/';
    $app = Marquee->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/Marquee.log");
    $app->default_file('index.html');
    
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/path_base.html')
        ->status_is(200)
        ->text_is('test1', '/base/a/b/c')
        ->text_is('test2', '/base/a/b/c')
        ->text_is('test3', '/base/a/b/c');
}

### model

{
    package MyApp::Model;
    use strict;
    use warnings;
    
    sub new {
        my ($class) = @_;
        return bless {
            foo => 'FOO',
            bar => 'BAR',
            baz => 'BAZ',
        }, $class;
    }
    
    sub retrieve {
        return $_[0]->{$_[1]};
    }
}

{
    package MyApp;
    use Mojo::Base 'Marquee';
    
    has model => sub {MyApp::Model->new};
    
    sub new {
        my $self = shift->SUPER::new(@_);
        $self->stash->set(model => $self->model);
        return $self;
    }
}

$app = MyApp->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$t = Test::Mojo->new($app);

$t->get_ok('/model.html')
    ->status_is(200)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->header_is('Content-Length', 54)
    ->text_is('filename', 'model.html.ep')
    ->text_is('test1', 'FOO');


__END__

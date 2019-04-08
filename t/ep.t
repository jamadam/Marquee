use strict;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Test::Mojo::DOM;
use Test::Path qw'path_is path_like';
use Marquee;
use Mojo::Date;
use Marquee::SSIHandler::EP;

use Test::More;

### add_function

my $ep = Marquee::SSIHandler::EP->new;

eval {
    $ep->add_function(myfunc => sub() {});
};

is ref $ep->funcs->{myfunc}, 'CODE';
is $@, '';

SKIP: {
    if ($] < 5.016) {
        skip('because the perl version is older than 5.016', 2);
    }
    eval {
        $ep->add_function(time => sub() {});
    };
    
    is $ep->funcs->{time}, undef;
    like $@, qr{Can't modify built-in function time};
}

eval {
    $ep->add_function(add_function => sub() {});
};

is ref $ep->funcs->{add_function}, 'CODE';
is $@, '';

eval {
    $ep->add_function('a b c' => sub() {});
};

is ref $ep->funcs->{'a b c'}, '';
like $@, qr'Function name must be';

my $app;
my $t;

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->default_file('index.html');

eval {
    $app->dynamic->handlers->{ep}->add_function('redefine' => sub() {});
    $app->dynamic->handlers->{ep}->add_function('redefine' => sub() {});
};

is $@, '';

$t = Test::Mojo::DOM->new($app);

# param

$t->get_ok('/ep/helper.html?foo=bar')
    ->status_is(200)
    ->content_is('bar');

### iter
$t->get_ok('/ep/iter.html')
    ->status_is(200)
    ->text_is('test1 .test0', '0')
    ->text_is('test1 .test1', '1')
    ->text_is('test1 .test2', '2')
    ->text_is('test3 .testfoo', 'FOO')
    ->text_is('test3 .testbar', 'BAR')
    ->text_is('test3 .testbaz', 'BAZ')
    ->text_is('test4 .test0', 'FOO')
    ->text_is('test4 .test1', 'BAR')
    ->text_is('test4 .test2', 'BAZ');

# sub template inclusion
$t->get_ok('/ep/include.html');
$t->status_is(200);
$t->text_is('filename', '/ep/include.html.ep');
path_like $t->tx->res->dom->at('current_template')->text, qr'public_html/ep/include.html.ep$';
path_like $t->tx->res->dom->at('current_template2')->text, qr'public_html/ep/include.html.ep$';
$t->text_is('test1 filename', '/ep/include_sub.html.ep');
path_like $t->tx->res->dom->at('test1 current_template')->text, qr'public_html/ep/include_sub.html.ep$';
$t->text_is('test2 filename', '/ep/include_sub2/1.html.ep');
path_like $t->tx->res->dom->at('test2 current_template')->text, qr'public_html/ep/include_sub2/1.html.ep$';
path_like $t->tx->res->dom->at('test2 parent_template')->text, qr'/ep/include.html.ep$';
$t->text_is('test2 parent_template2', '');
$t->text_is('test2 test1 filename', '/ep/include_sub2/2.html.ep');
path_like $t->tx->res->dom->at('test2 test1 current_template')->text, qr'public_html/ep/include_sub2/2.html.ep$';
path_like $t->tx->res->dom->at('test2 test2 filename')->text, qr'/ep/include_sub.html.ep$';
$t->text_is('test3 myarg', 'myarg value');
$t->text_is('test3 stash_leak', '');

# sub template inclusion with no ext

$t->get_ok('/ep/include_as.html');
$t->status_is(200);
$t->text_is('filename', '/ep/include_as.html.ep');
$t->text_is('test1 filename', '/ep/include_as_sub.html');
path_like $t->tx->res->dom->at('test1 current_template')->text, qr'public_html/ep/include_as_sub.html$';

### abs

$t->get_ok('/to_abs.html')
    ->status_is(200)
    ->text_is('filename', 'to_abs.html.ep')
    ->text_is('test1', 1)
    ->text_is('test2', 0);

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->stash->set('namespace_test' => 'global stash content');
$t = Test::Mojo::DOM->new($app);

### template extension

$t->get_ok('/ep/use_layout.html')
    ->status_is(200)
    ->dom_inspector(sub($t) {
        $t->at('title')->text_is('タイトル');
        $t->at('#main')->text_like(qr{\s*メインコンテンツdynamic\s*});
        $t->at('#main2')->text_like(qr{\s*DEFAULT MAIN2\s*});
        path_is $t->at('current_template1')->dom->[0]->text, "$FindBin::Bin/public_html/ep/use_layout.html.ep";
        $t->at('current_template2')->text_is("");
        path_is $t->at('use_layout current_template3')->dom->[0]->text, "$FindBin::Bin/public_html/ep/use_layout.html.ep";
        path_is $t->at('use_layout current_template4')->dom->[0]->text, "$FindBin::Bin/public_html/ep/layout/common.html.ep";
        path_is $t->at('use_layout current_template5')->dom->[0]->text, "$FindBin::Bin/public_html/ep/use_layout.html.ep";
        
        $t->at('use_layout current_template6')->text_is("");
        path_is $t->at('layout current_template1')->dom->[0]->text, "$FindBin::Bin/public_html/ep/layout/common.html.ep";
        path_is $t->at('layout #main2 current_template2')->dom->[0]->text, "$FindBin::Bin/public_html/ep/layout/common.html.ep";
        path_is $t->at('layout #main2 current_template3')->dom->[0]->text, "$FindBin::Bin/public_html/ep/layout/common.html.ep";
        path_is $t->at('layout #main2 current_template4')->dom->[0]->text, "$FindBin::Bin/public_html/ep/use_layout.html.ep";
        $t->at('layout #main2 current_template5')->text_is("");
        $t->at('layout #namespace_test')->text_like(qr{\s*global stash content\s*});
    });

ok ! exists $app->stash->{title};

### template extension(include_as)

$t->get_ok('/ep/use_layout2.html')
    ->status_is(200)
    ->dom_inspector(sub($t) {
        $t->at('title')->text_is('タイトル');
        $t->at('#main')->text_like(qr{\s*メインコンテンツdynamic\s*});
        $t->at('#main2')->text_like(qr{\s*DEFAULT MAIN2\s*});
        path_is $t->at('current_template1')->dom->[0]->text, "$FindBin::Bin/public_html/ep/use_layout2.html.ep";
        $t->at('current_template2')->text_is("");
        path_is $t->at('use_layout current_template3')->dom->[0]->text, "$FindBin::Bin/public_html/ep/use_layout2.html.ep";
        path_is $t->at('use_layout current_template4')->dom->[0]->text, "$FindBin::Bin/public_html/ep/layout/common2.html";
        path_is $t->at('use_layout current_template5')->dom->[0]->text, "$FindBin::Bin/public_html/ep/use_layout2.html.ep";
        $t->at('use_layout current_template6')->text_is("");
        path_is $t->at('layout current_template1')->dom->[0]->text, "$FindBin::Bin/public_html/ep/layout/common2.html";
        path_is $t->at('layout #main2 current_template2')->dom->[0]->text, "$FindBin::Bin/public_html/ep/layout/common2.html";
        path_is $t->at('layout #main2 current_template3')->dom->[0]->text, "$FindBin::Bin/public_html/ep/layout/common2.html";
        path_is $t->at('layout #main2 current_template4')->dom->[0]->text, "$FindBin::Bin/public_html/ep/use_layout2.html.ep";
        $t->at('layout #main2 current_template5')->text_is("");
        $t->at('layout #namespace_test')->text_like(qr{\s*global stash content\s*});
    });

ok ! exists $app->stash->{title};

### session

$t = Test::Mojo::DOM->new($app);
$t->get_ok('/ep/session.html');
$t->text_is(test1 => '');
$t->text_is(test2 => 'bar');
$t->get_ok('/ep/session.html');
$t->text_is(test1 => 'bar');
$t->text_is(test2 => 'bar');
$t = Test::Mojo::DOM->new($app);
$t->get_ok('/ep/session.html');
$t->text_is(test1 => '');
$t->text_is(test2 => 'bar');

done_testing();

__END__

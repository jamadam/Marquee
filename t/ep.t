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
use Marquee;
use Mojo::Date;
use Marquee::SSIHandler::EP;

use Test::More tests => 70;

### add_function

my $ep = Marquee::SSIHandler::EP->new;

eval {
    $ep->add_function(myfunc => sub {});
};

is ref $ep->funcs->{myfunc}, 'CODE';
is $@, '';

eval {
    $ep->add_function(time => sub {});
};

is $ep->funcs->{time}, undef;
like $@, qr{Can't modify built-in function time};

eval {
    $ep->add_function(add_function => sub {});
};

is ref $ep->funcs->{add_function}, 'CODE';
is $@, '';

eval {
    $ep->add_function('a b c' => sub {});
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
    $app->ssi_handlers->{ep}->add_function('redefine' => sub {});
    $app->ssi_handlers->{ep}->add_function('redefine' => sub {});
};

is $@, '';

$t = Test::Mojo->new($app);

# param

$t->get_ok('/helper.html?foo=bar')
    ->status_is(200)
    ->content_is('bar');

### iter

$t->get_ok('/iter.html')
    ->status_is(200)
    ->text_is('test1 .test0', '0')
    ->text_is('test1 .test1', '1')
    ->text_is('test1 .test2', '2')
    ->text_is('test2 .test0', '0')
    ->text_is('test2 .test1', '1')
    ->text_is('test2 .test2', '2')
    ->text_is('test3 .testfoo', 'FOO')
    ->text_is('test3 .testbar', 'BAR')
    ->text_is('test3 .testbaz', 'BAZ')
    ->text_is('test4 .test0', 'FOO')
    ->text_is('test4 .test1', 'BAR')
    ->text_is('test4 .test2', 'BAZ');

# sub template inclusion

$t->get_ok('/include.html')
    ->status_is(200)
    ->text_is('filename', 'include.html.ep')
    ->text_like('current_template', qr'public_html/include.html.ep$')
    ->text_like('current_template2', qr'public_html/include.html.ep$')
    ->text_is('test1 filename', 'include_sub.html.ep')
    ->text_like('test1 current_template', qr'public_html/include_sub.html.ep$')
    ->text_is('test2 filename', '/include_sub2/1.html.ep')
    ->text_like('test2 current_template', qr'public_html/include_sub2/1.html.ep$')
    ->text_like('test2 parent_template', qr'/include.html.ep$')
    ->text_is('test2 parent_template2', '')
    ->text_is('test2 test1 filename', '/include_sub2/2.html.ep')
    ->text_like('test2 test1 current_template', qr'public_html/include_sub2/2.html.ep$')
    ->text_like('test2 test2 filename', qr'include_sub.html.ep$')
    ->text_is('test3 myarg', 'myarg value')
    ->text_is('test3 stash_leak', '');

# sub template inclusion with no ext

$t->get_ok('/include_as.html')
    ->status_is(200)
    ->text_is('filename', 'include_as.html.ep')
    ->text_is('test1 filename', 'include_as_sub.html')
    ->text_like('test1 current_template', qr'public_html/include_as_sub.html$');

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

$t->get_ok('/use_layout.html')
    ->status_is(200)
    ->dom_inspector(sub {
        my $t = shift;
        $t->at('title')->text_is('タイトル');
        $t->at('#main')->text_is('メインコンテンツdynamic');
        $t->at('#main2')->text_is('DEFAULT MAIN2');
        $t->at('current_template1')->text_is("$FindBin::Bin/public_html/use_layout.html.ep");
        $t->at('current_template2')->text_is("");
        $t->at('use_layout current_template3')->text_is("$FindBin::Bin/public_html/use_layout.html.ep");
        $t->at('use_layout current_template4')->text_is("$FindBin::Bin/public_html/layout/common.html.ep");
        $t->at('use_layout current_template5')->text_is("$FindBin::Bin/public_html/use_layout.html.ep");
        $t->at('use_layout current_template6')->text_is("");
        $t->at('layout current_template1')->text_is("$FindBin::Bin/public_html/layout/common.html.ep");
        $t->at('layout #main2 current_template2')->text_is("$FindBin::Bin/public_html/layout/common.html.ep");
        $t->at('layout #main2 current_template3')->text_is("$FindBin::Bin/public_html/layout/common.html.ep");
        $t->at('layout #main2 current_template4')->text_is("$FindBin::Bin/public_html/use_layout.html.ep");
        $t->at('layout #main2 current_template5')->text_is("");
        $t->at('layout #namespace_test')->text_is("global stash content");
    });

ok ! exists $app->stash->{title};
    
__END__

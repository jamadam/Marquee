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

use Test::More tests => 97;

my $app;
my $t;

### auto index tests

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html_index");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->default_file('index.html');
$app->plugin('AutoIndex');
$t = Test::Mojo::DOM->new($app);

unlink("$FindBin::Bin/public_html_index/.DS_Store");
open(my $file, "> $FindBin::Bin/public_html_index/日本語.html");
close($file);

$t->get_ok('/')
    ->status_is(200)
    ->dom_inspector(sub {
        my $t = shift;
        $t->at('title')
            ->text_is('Index of /');
        
        {
            my $t = $t->at('tbody tr:nth-child(1)');
            my $file = "$FindBin::Bin/public_html_index/some_dir";
            $t->at('a')
                ->text_is('some_dir')
                ->attr_is('href', 'some_dir/')
                ->has_class('dir');
            $t->at('td:nth-child(2)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_timestamp($file));
            $t->at('td:nth-child(3)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_size($file));
        }
        
        {
            my $t = $t->at('tbody tr:nth-child(4)');
            my $file = "$FindBin::Bin/public_html_index/image.png";
            $t->at('a')
                ->text_is('image.png')
                ->attr_is('href', 'image.png')
                ->has_class('image');
            $t->at('td:nth-child(2)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_timestamp($file));
            $t->at('td:nth-child(3)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_size($file));
        }
        
        {
            my $t = $t->at('tbody tr:nth-child(9)');
            my $file = "$FindBin::Bin/public_html_index/日本語.html";
            $t->at('a')
                ->text_is('日本語.html')
                ->attr_is('href', '日本語.html')
                ->has_class('text');
            $t->at('td:nth-child(2)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_timestamp($file));
            $t->at('td:nth-child(3)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_size($file));
        }
    })
    ->content_like(qr{test3.html})
    ->content_unlike(qr{test3.html.ep})
    ->content_like(qr{test4.html.pub});

$t->get_ok('/some_dir/')
    ->status_is(200)
    ->dom_inspector(sub {
        my $t = shift;
        
        {
            my $t = $t->at('tbody tr:nth-child(1)');
            my $file = "$FindBin::Bin/public_html_index/";
            $t->at('a')
                ->text_is('..')
                ->attr_is('href', '../')
                ->has_class('dir');
            $t->at('td:nth-child(2)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_timestamp($file));
            $t->at('td:nth-child(3)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_size($file));
        }
        {
            my $t = $t->at('tbody tr:nth-child(2)');
            my $file = "$FindBin::Bin/public_html_index/test.html";
            $t->at('a')
                ->text_is('test.html')
                ->attr_is('href', 'test.html')
                ->has_class('text');
            $t->at('td:nth-child(2)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_timestamp($file));
            $t->at('td:nth-child(3)')
                ->text_is(Marquee::Plugin::AutoIndex::_file_size($file));
        }
    });

$t->get_ok('/some_dir2/')
    ->status_is(200)
    ->content_is(q{index file exists});
$t->get_ok('/some_dir3/file_list.css')
    ->status_is(200)
    ->content_is(q{file_list.css});
$t->get_ok('/static/site_file_list.css')
    ->status_is(200)
    ->content_like(qr{\@charset "UTF\-8"});
$t->get_ok('/some_dir/not_exists.html')
    ->status_is(404)
    ->element_exists_not('body#debugScreen');
$t->get_ok('/..%2f')
    ->status_is(404)
    ->element_exists_not('body#debugScreen');
$t->get_ok('/some_dir/..%2f..%2f')
    ->status_is(404)
    ->element_exists_not('body#debugScreen');
$t->get_ok('/some_dir/.%2f/')
    ->status_is(200)
    ->content_like(qr{test.html});

$t->get_ok('/?mode=tree')
    ->status_is(200)
    ->dom_inspector(sub {
        my $t = shift;
        $t->at('title')
            ->text_is('Index of /');
        
        {
            my $t = $t->at('#wrapper > ul li:nth-child(1)');
            my $file = "$FindBin::Bin/public_html_index/some_dir";
            $t->has_class('dir');
            $t->at('a')
                ->text_is('some_dir')
                ->attr_is('href', '/some_dir/?mode=tree')
                ->has_class('dir');
        }
        
        {
            my $t = $t->at('#wrapper > ul li:nth-child(2)');
            my $file = "$FindBin::Bin/public_html_index/image.png";
            $t->has_class_not('dir');
            $t->at('a')
                ->text_is('test.html')
                ->attr_is('href', '/some_dir/test.html');
        }
        
        {
            my $t = $t->at('#wrapper > ul li:nth-child(12)');
            my $file = "$FindBin::Bin/public_html_index/日本語.html";
            $t->at('a')
                ->text_is('日本語.html')
                ->attr_is('href', '/日本語.html');
        }
    })
    ->content_like(qr{test3.html})
    ->content_unlike(qr{test3.html.ep})
    ->content_like(qr{test4.html.pub});

$t->get_ok('/some_dir/?mode=tree')
    ->status_is(200)
    ->dom_inspector(sub {
        my $t = shift;
        
        {
            my $t = $t->at('#wrapper > ul li:nth-child(1)');
            my $file = "$FindBin::Bin/public_html_index/";
            $t->at('a')
                ->text_is('..')
                ->attr_is('href', '/some_dir/../?mode=tree')
                ->has_class('dir');
        }
        {
            my $t = $t->at('#wrapper > ul li:nth-child(2)');
            my $file = "$FindBin::Bin/public_html_index/test.html";
            $t->at('a')
                ->text_is('test.html')
                ->attr_is('href', '/some_dir/test.html');
        }
    });

$t->get_ok('/some_dir2/?mode=tree')
    ->status_is(200)
    ->content_is(q{index file exists});
$t->get_ok('/some_dir3/file_list.css?mode=tree')
    ->status_is(200)
    ->content_is(q{file_list.css});
$t->get_ok('/static/site_file_list.css?mode=tree')
    ->status_is(200)
    ->content_like(qr{\@charset "UTF\-8"});
$t->get_ok('/some_dir/not_exists.html?mode=tree')
    ->status_is(404)
    ->element_exists_not('body#debugScreen');
$t->get_ok('/..%2f?mode=tree')
    ->status_is(404)
    ->element_exists_not('body#debugScreen');
$t->get_ok('/some_dir/..%2f..%2f?mode=tree')
    ->status_is(404)
    ->element_exists_not('body#debugScreen');
$t->get_ok('/some_dir/.%2f/?mode=tree')
    ->status_is(200)
    ->content_like(qr{test.html});

unlink("$FindBin::Bin/public_html_index/日本語.html");

__END__

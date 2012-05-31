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
    
    use Test::More tests => 160;

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
    $t->get_ok('/nonexists.html')
        ->status_is(404)
        ->content_like(qr'404 file not found'i);
    $t->get_ok('/')
        ->status_is(200)
        ->content_type_is('text/html;charset=UTF-8')
        ->header_is('Content-Length', 25)
        ->content_like(qr{index.html.ep \d+\n});
    $t->get_ok('/index.html.ep')
        ->status_is(403)
        ->content_type_is('text/html;charset=UTF-8')
        ->header_is('Content-Length', 13)
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
    
    # auto escape activation
    
    $t->get_ok('/auto_escape1.html')
        ->content_is('&amp;');
    $t->get_ok('/auto_escape2.html')
        ->content_is('<');
    
    # helper
    $t->get_ok('/helper.html?foo=bar')
        ->status_is(200)
        ->content_is('bar');
    
    # sub template inclusion
    
    $t->get_ok('/include.html')
        ->status_is(200)
        ->text_is('filename', 'include.html.ep')
        ->text_like('current_template', qr'public_html/include.html.ep$')
        ->text_is('test1 filename', 'include_sub.html.ep')
        ->text_like('test1 current_template', qr'public_html/./include_sub.html.ep$')
        ->text_is('test2 filename', '/include_sub2/1.html.ep')
        ->text_like('test2 current_template', qr'public_html/./include_sub2/1.html.ep$')
        ->text_is('test2 test1 filename', '/include_sub2/2.html.ep')
        ->text_like('test2 test1 current_template', qr'public_html/./include_sub2/./2.html.ep$')
        ->text_is('test3 myarg', 'myarg value');
    
    ### abs
    
    $t->get_ok('/to_abs.html')
        ->status_is(200)
        ->text_is('filename', 'to_abs.html.ep')
        ->text_is('test1', 1)
        ->text_is('test2', 0);
    
    ### stash
    
    $app->stash->(baz => 'BAZ');
    
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
        ->content_is("rendered");
    $t->get_ok('/index2.html.test')
        ->status_is(403)
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
    
    ### auto index tests
    
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html_index");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
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
                    ->text_is('some_dir/')
                    ->attr_is('href', 'some_dir/')
                    ->has_class('dir');
                $t->at('td:nth-child(2)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_timestamp($file));
                $t->at('td:nth-child(3)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_size($file));
            }
            
            {
                my $t = $t->at('tbody tr:nth-child(4)');
                my $file = "$FindBin::Bin/public_html_index/image.png";
                $t->at('a')
                    ->text_is('image.png')
                    ->attr_is('href', 'image.png')
                    ->has_class('image');
                $t->at('td:nth-child(2)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_timestamp($file));
                $t->at('td:nth-child(3)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_size($file));
            }
            
            {
                my $t = $t->at('tbody tr:nth-child(9)');
                my $file = "$FindBin::Bin/public_html_index/日本語.html";
                $t->at('a')
                    ->text_is('日本語.html')
                    ->attr_is('href', '日本語.html')
                    ->has_class('text');
                $t->at('td:nth-child(2)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_timestamp($file));
                $t->at('td:nth-child(3)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_size($file));
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
                    ->text_is('../')
                    ->attr_is('href', '../')
                    ->has_class('dir');
                $t->at('td:nth-child(2)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_timestamp($file));
                $t->at('td:nth-child(3)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_size($file));
            }
            {
                my $t = $t->at('tbody tr:nth-child(2)');
                my $file = "$FindBin::Bin/public_html_index/test.html";
                $t->at('a')
                    ->text_is('test.html')
                    ->attr_is('href', 'test.html')
                    ->has_class('text');
                $t->at('td:nth-child(2)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_timestamp($file));
                $t->at('td:nth-child(3)')
                    ->text_is(MojoSimpleHTTPServer::Plugin::AutoIndex::_file_size($file));
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
        ->status_is(404);
    
    unlink("$FindBin::Bin/public_html_index/日本語.html");

__END__

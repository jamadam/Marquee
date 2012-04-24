package Template_Basic;
use strict;
use warnings;
use utf8;
use lib 'lib';
use Test::More;
use Test::Mojo;
use Directoricious;
use FindBin;
    
    use Test::More tests => 81;

    my $app;
    my $t;
    
    $app = Directoricious->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->auto_index(1);
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/dir1')
        ->status_is(301)
        ->header_like(Location => qr{/dir1/$});
    $t->get_ok('/nonexists.html')
        ->status_is(404);
    $t->get_ok('/')
        ->status_is(200)
        ->content_type_is('text/html;charset=UTF-8')
        ->content_like(qr{index.html.ep \d+\n});
    $t->get_ok('/index.html.ep')
        ->content_type_is('text/html;charset=UTF-8')
        ->status_is(403);
    $t->get_ok('/index.html')
        ->content_type_is('text/html;charset=UTF-8')
        ->status_is(200)
        ->content_like(qr{index.html.ep \d+\n});
    $t->get_ok('/index.txt')
        ->content_type_is('text/plain')
        ->status_is(200)
        ->content_is(qq{static <%= time() %>});
    $t->get_ok('/dir1/')
        ->content_type_is('text/html;charset=UTF-8')
        ->status_is(200)
        ->content_is(qq{dir1/index.html});
    $t->get_ok('/dir1/index.html')
        ->content_type_is('text/html;charset=UTF-8')
        ->status_is(200)
        ->content_is(qq{dir1/index.html});
    $t->get_ok('/dir1/dynamic.html')
        ->content_type_is('text/html;charset=UTF-8')
        ->status_is(200)
        ->content_like(qr{dir1/dynamic.html \d+\n});
    $t->get_ok('/dir1/dynamic.json')
        ->content_type_is('application/json')
        ->status_is(200)
        ->content_is(qq{{"dynamic":"json"}});
    $t->get_ok('/dir1/static.json')
        ->content_type_is('application/json')
        ->status_is(200)
        ->content_is(qq{{"static":"json"}});
    $t->get_ok('/dynamic.txt')
        ->content_type_is('text/plain')
        ->status_is(200)
        ->content_like(qr{dynamic \d+\n});
    
    ### adding template handler tests
    
    $app = Directoricious->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->auto_index(1);
    $app->template_handlers({
        test => sub {return $_[0]},
        test2 => sub {return 'rendered'},
    });
    $t = Test::Mojo->new($app);

	$t->get_ok('/index2.html')
        ->status_is(200)
        ->content_is("$FindBin::Bin/public_html/index2.html.test");
	$t->get_ok('/index3.html')
        ->status_is(200)
        ->content_is("rendered");
	$t->get_ok('/index2.html.test')
        ->status_is(403)
        ->content_like(qr"403 Forbidden");
	$t->get_ok('/index3.html.test2')
        ->status_is(403)
        ->content_like(qr"403 Forbidden");
    
    ### auto index tests
    
    $app = Directoricious->new;
    $app->document_root("$FindBin::Bin/public_html_index");
    $app->auto_index(1);
    $t = Test::Mojo->new($app);
    
	$t->get_ok('/')
		->status_is(200)
		->content_like(qr{<title>Index of /</title>})
		->content_like(qr{4B})
		->content_like(qr{1.6KB})
		->content_unlike(qr{<a class="dir" href="\./">})
		->content_like(qr{<a class="dir" href="some_dir/">some_dir/</a>})
		->content_like(qr{\d\d\d\d-\d\d-\d\d \d\d:\d\d})
		->content_like(qr{日本語})
		->content_like(qr{<a class="image" href="image.png">image.png</a>});
	
    $t->get_ok('/some_dir/')
		->status_is(200)
		->content_like(qr{<a class="dir" href="\.\./">\.\./</a>})
		->content_like(qr{test.html});
	$t->get_ok('/some_dir2/')
		->status_is(200)
		->content_is(q{index file exists});
	$t->get_ok('/some_dir3/file_list.css')
		->status_is(200)
		->content_is(q{file_list.css});
	$t->get_ok('/static/file_list.css')
		->status_is(200)
		->content_like(qr{\@charset "UTF\-8"});
	$t->get_ok('/some_dir/not_exists.html')
		->status_is(404);

__END__

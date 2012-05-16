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

    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $t = Test::Mojo::DOM->new($app);
    
    $t->get_ok('/use_layout.html')
        ->status_is(200)
        ->dom_inspector(sub {
            my $t = shift;
            $t->at('title')->text_is('タイトル');
            $t->at('#main')->text_is('メインコンテンツdynamic');
            $t->at('#main2')->text_is('DEFAULT MAIN2');
            $t->at('current_template1')->text_is("$FindBin::Bin/public_html/use_layout.html.ep");
            $t->at('current_template2')->text_is("$FindBin::Bin/public_html/use_layout.html.ep");
            $t->at('layout current_template1')->text_is("$FindBin::Bin/public_html/./layout/common.html.ep");
            $t->at('layout #main2 current_template2')->text_is("$FindBin::Bin/public_html/./layout/common.html.ep");
        });
    
    is exists $app->stash->()->{title}, '';

__END__

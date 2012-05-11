use strict;
use warnings;
use utf8;
use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;
use MojoSimpleHTTPServer;

    use Test::More tests => 6;

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
        });
    
    is exists $app->stash->()->{title}, '';

__END__

use strict;
use warnings;
use utf8;
use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;
use MojoSimpleHTTPServer;

    use Test::More tests => 11;

    my $app;
    my $t;

    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $t = Test::Mojo::DOM->new($app);
    
    $t->get_ok('/not_good.html')
        ->status_is(500)
        ->content_is('500 Internal server error');
    
    $t->get_ok('/not_good2.html')
        ->status_is(500)
        ->content_is('500 Internal server error');
    
    ### debug screen
    
    $app->under_development(1);
    
    $t->get_ok('/not_good.html')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=UTF-8')
        ->dom_inspector(sub {
            my $t = shift;
            $t->at('title')->text_is('Debug Screen');
            $t->at('#showcase pre')->text_like(qr{Global symbol "\$nonexitsts" requires explicit package name at (.+?)t/public_html/not_good.html.ep line 4\.});
            $t->at('#context tr:nth-child(1) td.key')->text_is('1.');
        });

__END__

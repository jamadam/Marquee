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
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/not_good.html')
        ->status_is(500)
        ->content_is('500 Internal server error');
    
    $t->get_ok('/not_good2.html')
        ->status_is(500)
        ->content_is('500 Internal server error');

__END__

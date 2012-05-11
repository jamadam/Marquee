use strict;
use warnings;
use utf8;
use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;
use MojoSimpleHTTPServer;

    use Test::More tests => 7;

    my $app;
    my $t;

    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/cache.html')
        ->status_is(200);
    $t->get_ok('/cache.html')
        ->status_is(200);
    
    my $cache = $app->ssi_handlers->{ep}->template_cache->{cache};
    is scalar keys %$cache, 1, 'right cache amount';
    my $mt = $cache->{(keys %$cache)[0]};
    is ref $mt, 'Mojo::Template';
    ok $mt->compiled;

__END__

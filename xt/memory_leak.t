use strict;
use warnings;
use Test::Memory::Cycle;
use Test::More;
use MojoSimpleHTTPServer;
use Test::Mojo;

use Test::More tests => 6;

{
    my $app = MojoSimpleHTTPServer->new;
    $app->document_root('./');
    $app->plugin('AutoIndex');
    my $t = Test::Mojo->new($app);
    $t->get_ok('/');
    memory_cycle_ok( $app );
    memory_cycle_ok( $t );
}

{
    my $app = MyApp->new;
    $app->document_root('./');
    $app->plugin('AutoIndex');
    $app->hook(around_static => sub {
        my ($next, @args) = @_;
        return $next->(@args);
    });
    $app->plugin(Router => {
        qr/index\.html/ => sub {
            MyApp->context->app->serve_static("");
        },
    });
    my $t = Test::Mojo->new($app);
    $t->get_ok('/');
    memory_cycle_ok( $app );
    memory_cycle_ok( $t );
}

package MyApp;
use Mojo::Base 'MojoSimpleHTTPServer';

__END__
use strict;
use warnings;
use Test::Memory::Cycle;
use Test::More;
use Marquee;
use Test::Mojo;

use Test::More tests => 6;

{
    my $app = Marquee->new;
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
    $app->route->route(qr/index\.html/)->to(sub {
        MyApp->context->app->serve_static("");
    });
    my $t = Test::Mojo->new($app);
    $t->get_ok('/');
    memory_cycle_ok( $app );
    memory_cycle_ok( $t );
}

package MyApp;
use Mojo::Base 'Marquee';

__END__
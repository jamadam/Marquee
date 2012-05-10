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
    $app->auto_index(1);
    my $t = Test::Mojo->new($app);
    $t->get_ok('/');
    memory_cycle_ok( $app );
    memory_cycle_ok( $t );
}

{
    my $app = MyApp->new;
    $app->document_root('./');
    $app->auto_index(1);
    $app->around_method_hook(serve_static => sub {
        my ($app, $next, @args) = @_;
        return $next->(@args);
    });
    my $t = Test::Mojo->new($app);
    $t->get_ok('/');
    memory_cycle_ok( $app );
    memory_cycle_ok( $t );
}

package MyApp;
use Mojo::Base 'MojoSimpleHTTPServer';

__END__
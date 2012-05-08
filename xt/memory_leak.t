use strict;
use warnings;
use Test::Memory::Cycle;
use Test::More;
use MojoSimpleHTTPServer;
use Test::Mojo;

use Test::More tests => 3;

my $app = MojoSimpleHTTPServer->new;
$app->document_root('./');
my $t = Test::Mojo->new($app);
$t->get_ok('/');
memory_cycle_ok( $app );
memory_cycle_ok( $t );

__END__
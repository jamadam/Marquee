use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw'catdir rel2abs splitdir';
use lib catdir(dirname(__FILE__), 'lib');
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), '../examples/official-site/lib');
use Test::More;
use Test::Mojo::DOM;
use Test::Path 'path_is';
use Marquee;
use Mojo::Date;
use Mojo::Transaction::HTTP;
use Mojo::URL;
use MarqueeOfficial;

use Test::More tests => 146;

my $app = MarqueeOfficial->new;
$app->under_development(1);
my $t = Test::Mojo->new($app);
$t->get_ok('/');
$t->status_is(200);
$t->header_is('Content-Type', 'text/html;charset=UTF-8');
$t->text_is('title', 'FOO');


__END__

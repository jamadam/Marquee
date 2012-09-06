use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use lib catdir(dirname(__FILE__), '../examples/official-site/lib');
use Test::More;
use Test::Mojo::DOM;
use Test::Path 'path_is';
use Marquee;
use Mojo::Date;
use Mojo::Transaction::HTTP;
use Mojo::URL;
use MarqueeOfficial;

use Test::More tests => 40;

$ENV{MOJO_HOME} = catdir(dirname(__FILE__), '..');

my $app;
my $t;

$app = MarqueeOfficial->new(domain => 'http://mrqe.biz');
$t = Test::Mojo::DOM->new($app);
$t->get_ok('/');
$t->status_is(200);
$t->header_is('Content-Type', 'text/html;charset=UTF-8');
$t->dom_inspector(sub {
    my $t = shift;
    $t->at('title')->text_is('Marquee - Markdown viewer');
    $t->at('#wrapper h2')->text_is('Marquee');
    $t->at('#wrapper p a')->attr_is('href', '/perldoc/Marquee');
    $t->at('#wrapper pre code')->has_class('prettyprint');
    $t->at('#wrapper p')->text_like(qr'yet another');
});

$t->get_ok('/perldoc/');
$t->status_is(200);
$t->header_is('Content-Type', 'text/html;charset=UTF-8');
$t->dom_inspector(sub {
    my $t = shift;
    $t->at('title')->text_is('Index of Modules - Pod viewer');
    $t->at('#wrapper h2')->text_is('INDEX OF MODULES');
    $t->at('#wrapper a')->attr_is('href', './Marquee');
    $t->at('#wrapper a')->text_is('Marquee');
    $t->at('#wrapper a:last-child')->text_is('Mojolicious::Command::marquee');
});

$t->get_ok('/perldoc/Marquee');
$t->status_is(200);
$t->header_is('Content-Type', 'text/html;charset=UTF-8');
$t->dom_inspector(sub {
    my $t = shift;
    $t->at('title')->text_is('Marquee - Yet another Mojolicious based web framework - Pod viewer');
});

### ja


$app = MarqueeOfficial->new(domain => 'http://mrqe.biz', locale => 'ja');
$t = Test::Mojo::DOM->new($app);
$t->get_ok('/');
$t->status_is(200);
$t->header_is('Content-Type', 'text/html;charset=UTF-8');
$t->dom_inspector(sub {
    my $t = shift;
    $t->at('title')->text_is('Marquee - Markdown viewer');
    $t->at('#wrapper h2')->text_is('Marquee');
    $t->at('#wrapper p a')->attr_is('href', '/perldoc/Marquee');
    $t->at('#wrapper pre code')->has_class('prettyprint');
    $t->at('#wrapper p')->text_like(qr'もうひとつの');
});

$t->get_ok('/perldoc/');
$t->status_is(200);
$t->header_is('Content-Type', 'text/html;charset=UTF-8');
$t->dom_inspector(sub {
    my $t = shift;
    $t->at('title')->text_is('Index of Modules - Pod viewer');
    $t->at('#wrapper h2')->text_is('INDEX OF MODULES');
    $t->at('#wrapper a')->attr_is('href', './Marquee');
    $t->at('#wrapper a')->text_is('Marquee');
    $t->at('#wrapper a:last-child')->text_is('Mojolicious::Command::marquee');
});

$t->get_ok('/perldoc/Marquee');
$t->status_is(200);
$t->header_is('Content-Type', 'text/html;charset=UTF-8');
$t->dom_inspector(sub {
    my $t = shift;
    $t->at('title')->text_is('Marquee - もうひとつのMojoliciousベースのウェブフレームワーク - Pod viewer');
});


__END__

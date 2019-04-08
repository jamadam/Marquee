use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Test::Mojo::DOM;
use Test::Path 'path_is';
use Marquee;
use Mojo::Date;
use Mojo::Transaction::HTTP;
use Mojo::URL;
use Mojo::ByteStream 'b';

use Test::More tests => 10;

my $app;
my $t;

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$t = Test::Mojo::DOM->new($app);

my $yatta = 'やった';
my $yatta_utf8 = b($yatta)->encode('UTF-8')->to_string;

$t->get_ok('/charset/utf8.txt')
    ->status_is(200)
    ->content_type_is('text/plain')
    ->header_is('Content-Length', 9)
    ->content_is('やった');

$t->get_ok('/charset/utf8_dynamic.html')
    ->status_is(200)
    ->content_type_is('text/html;charset=UTF-8')
    ->header_is('Content-Length', 22)
    ->content_is('utf8_dynamicやった'. "\n");

__END__

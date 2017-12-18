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
use Marquee;
use Mojo::ByteStream 'b';

use Test::More tests => 33;

my $yatta = 'やった';
my $yatta_utf8 = b($yatta)->encode('UTF-8')->to_string;

my $app;
my $t;

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->default_file('index.html');
$app->plugin('ETag');

$t = Test::Mojo->new($app);

$t->get_ok('/etag/ascii.txt')
    ->status_is(200)
    ->header_is('Content-Type', 'text/plain')
    ->header_is('Content-Length', 5)
    ->header_is('ETag', '5b7f33be48f19c25e1af2f96cffc569f')
    ->content_is('ascii');

$t->get_ok('/etag/ascii.txt', {'If-None-Match' => '5b7f33be48f19c25e1af2f96cffc569f'})
    ->status_is(304)
    ->header_is('Content-Type', 'text/plain')
    ->header_is('ETag', '5b7f33be48f19c25e1af2f96cffc569f')
    ->content_is('');

$t->get_ok('/etag/utf8.txt')
    ->status_is(200)
    ->header_is('Content-Type', 'text/plain')
    ->header_is('Content-Length', 9)
    ->header_is('ETag', '1d6aaa2d0a9ee370574a82a2a7aa5f03')
    ->content_is('やった');

$t->get_ok('/etag/utf8.txt', {'If-None-Match' => '1d6aaa2d0a9ee370574a82a2a7aa5f03'})
    ->status_is(304)
    ->header_is('Content-Type', 'text/plain')
    ->header_is('ETag', '1d6aaa2d0a9ee370574a82a2a7aa5f03')
    ->content_is('');

$t->get_ok('/etag/utf8.html')
    ->status_is(200)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->header_is('Content-Length', 10)
    ->header_is('ETag', '07caa18dd24f49358b08d539f0828551')
    ->content_is("やった\n");

$t->get_ok('/etag/utf8.html', {'If-None-Match' => '07caa18dd24f49358b08d539f0828551'})
    ->status_is(304)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->header_is('ETag', '07caa18dd24f49358b08d539f0828551')
    ->content_is('');

__END__

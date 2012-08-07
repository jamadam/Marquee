use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), '../lib';
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;
use Marquee;

use Test::More tests => 21;

my $app;
my $t;

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$app->plugin(Auth => [
    qr{^/auth/auth\.html} => 'Secret Area2' => sub {
        $_[0] eq 'user' && $_[1] eq 'pass';
    },
    qr{^/auth/auth2\.html} => sub {
        $_[0] eq 'user2' && $_[1] eq 'pass2';
    },
]);

$t = Test::Mojo->new($app);

$t->get_ok('/index.txt')
    ->status_is(200)
    ->content_is("static <%= time() %>");

$t->get_ok('/auth/auth.html')
    ->status_is(401)
    ->header_is('www-authenticate', 'Basic realm=Secret Area2');

$t->get_ok('/auth/auth.html', {Authorization => "Basic dXNlcjpwYXNzMg=="})
    ->status_is(401)
    ->header_is('www-authenticate', 'Basic realm=Secret Area2');

$t->get_ok('/auth/auth.html', {Authorization => "Basic dXNlcjpwYXNz"})
    ->status_is(200)
    ->content_is("auth.html.ep dynamic\n");

$t->get_ok('/auth/auth2.html')
    ->status_is(401)
    ->header_is('www-authenticate', 'Basic realm=Secret Area');

$t->get_ok('/auth/auth2.html', {Authorization => "Basic dXNlcjpwYXNz"})
    ->status_is(401)
    ->header_is('www-authenticate', 'Basic realm=Secret Area');

$t->get_ok('/auth/auth2.html', {Authorization => "Basic dXNlcjI6cGFzczI="})
    ->status_is(200)
    ->content_is("/auth/auth2.html");

__END__

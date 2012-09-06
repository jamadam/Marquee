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
use Mojo::Date;
use Marquee;
use File::Path 'rmtree';

use Test::More tests => 21;

my $app;
my $t;

BEGIN {
    mkdir(catdir(dirname(__FILE__), 'auth_log'));
}
END {
    rmtree(catdir(dirname(__FILE__), 'auth_log'));
}

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$app->plugin(Router => sub {
    my $r = shift;
    $r->route(qr{^/})->to(sub {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->headers->content_type($app->types->type('html'));
        $res->body('index.html');
    });
    $r->route(qr{^/admin/})->to(sub {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->headers->content_type($app->types->type('html'));
        $res->body('/admin/ passed');
    });
    $r->route(qr{^/admin/index})->to(sub {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->headers->content_type($app->types->type('html'));
        $res->body('/admin/index passed');
    });
});

$app->plugin(AuthPretty => [
    qr{^/admin/} => 'Secret Area' => sub {
        my ($username, $password) = @_;
        return $username eq 'jamadam' && $password eq 'pass';
    },
] => catdir(dirname(__FILE__), 'auth_log'));

$t = Test::Mojo->new($app);

$t->get_ok('/')
    ->status_is(200)
    ->content_is('index.html');

$t->get_ok('/admin/')
    ->status_is(200)
    ->text_is('title', 'Secret Area');

$t->get_ok('/admin/index')
    ->status_is(200)
    ->text_is('title', 'Secret Area');

$t->post_form_ok('/admin/', {username => 'jamadam', password => 'pass'})
    ->status_is(301)
    ->header_like('Set-Cookie', qr'pretty_auth=.+?--.+?')
    ->header_is('Location', '/admin/');

$t->get_ok('/admin/')
    ->status_is(200)
    ->text_is('title', 'Secret Area');

$t->get_ok('/admin/', {Cookie => {}})
    ->status_is(200)
    ->content_is('/admin/ passed');

$t->get_ok('/admin/index', {Cookie => {}})
    ->status_is(200)
    ->content_is('/admin/index passed');

__END__

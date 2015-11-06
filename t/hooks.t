use strict;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;

use Test::More tests => 19;

my $app;
my $t;

{
    package MyApp;
    use Mojo::Base 'Marquee';
}

{
    package MyApp2;
    use Mojo::Base 'Marquee';
}

$app = MyApp->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$app->hook(around_static => my $hook1 = sub($next, @args) {
    $next->(@args);
    my $org = Marquee->c->res->body;
    Marquee->c->res->body($org.'mod');
    return $app;
});

$app->hook(around_static => my $hook2 = sub($next, @args) {
    $next->(@args);
    my $org = Marquee->c->res->body;
    Marquee->c->res->body($org.'mod2');
    return $app;
});

is $app->hooks->subscribers('around_static')->[1], $hook1, 'right hook order';
is $app->hooks->subscribers('around_static')->[2], $hook2, 'right hook order';

$t = Test::Mojo->new($app);

$t->get_ok('/index.txt')
    ->status_is(200)
    ->content_type_is('text/plain')
    ->header_is('Content-Length', 27)
    ->content_is('static <%= time() %>modmod2');

$app = MyApp2->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$app->hook(around_static => sub($next, @args) {
    $next->(@args);
    my $org = Marquee->c->res->body;
    Marquee->c->res->body($org.'mod');
    return $app;
});

$t = Test::Mojo->new($app);

$t->get_ok('/index.txt')
    ->status_is(200)
    ->content_type_is('text/plain')
    ->header_is('Content-Length', 23)
    ->content_is('static <%= time() %>mod');

$app->hook(around_static => sub($next, @args) {
    $next->(@args);
    my $org = Marquee->c->res->body;
    Marquee->c->res->body($org.'mod2');
    return $app;
});

$t->get_ok('/index.txt')
    ->status_is(200)
    ->content_type_is('text/plain')
    ->header_is('Content-Length', 27)
    ->content_is('static <%= time() %>modmod2');

### Should not run hook for dynamic if the path not found

$app->hook(around_dynamic => sub($next, @args) {
    ok 0, 'not to run';
    $next->();
});

$t->get_ok('/index2.html')
    ->status_is(404);
    
__END__

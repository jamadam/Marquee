use strict;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Marquee;
use Mojo::Date;
use Test::Mojo;

plan skip_all => 'CSS::Sass required for this test!'
  unless eval 'use CSS::Sass; 1';

my $app;
my $t;

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->default_file('index.html');
eval {
    my $scss = $app->plugin('Scss');
};
if ($@) {
    plan skip_all => $@;
}
$app->_init();

$t = Test::Mojo->new($app);

$t->get_ok('/scss/test1.css')
    ->status_is(200)
    ->header_is('Content-Type', 'text/css');

is(Mojo::Date->new($t->tx->res->headers->last_modified)->epoch, ts('test1.css'));

css_equals($t->tx->res->body, <<'EOF');
#test1.css {
    color:#fff;
}
EOF

$t->get_ok('/scss/test2.css')
    ->status_is(200)
    ->header_is('Content-Type', 'text/css');

css_equals($t->tx->res->body, <<'EOF');
#test2.scss {
    color: #fff;
}
EOF

is(Mojo::Date->new($t->tx->res->headers->last_modified)->epoch, ts('test2.scss'));

$t->get_ok('/scss/test3.css')
    ->status_is(200)
    ->header_is('Content-Type', 'text/css');

css_equals($t->tx->res->body, <<'EOF');
#test3.css {
    color:#fff;
}
EOF

is(Mojo::Date->new($t->tx->res->headers->last_modified)->epoch, ts('test3.css'));

$t->get_ok('/scss/test4.css')
    ->status_is(200)
    ->header_is('Content-Type', 'text/css');

css_equals($t->tx->res->body, <<'EOF');
#test2.scss {
    color: #fff;
}
#test2.scss #test3 {
    color: #fff;
}
EOF

$t->get_ok('/scss/notfound.css')
    ->status_is(404);

sub css_equals($got, $expected, $discription) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return is(shorten($got), shorten($expected), $discription);
}

sub shorten($css) {
    $css =~ s!\s*(\:|\{|\})\s*!$1!g;
    return $css;
}

sub ts($file) {
    my $ts = (stat $app->static->search('./scss/'. $file))[9];
    return $ts;
}

done_testing();

__END__

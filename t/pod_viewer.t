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

use Test::More tests => 27;

my $app;
my $t;

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->plugin('PODViewer' => {paths => [catdir(dirname(__FILE__), '../lib')]});

$t = Test::Mojo::DOM->new($app);

# basic

{
    use Mojo::Transaction::HTTP;
    my $app = Marquee->new;
    $app->document_root("$FindBin::Bin/public_html");
    Marquee->c(Marquee::Context->new(app => $app, tx => Mojo::Transaction::HTTP->new));
    my $pv = Marquee::Plugin::PODViewer->new;
    $app->_init;
    $pv->serve_pod(<<EOF);
=head1 a

=head1 b

=head1 c

=head1 a

=head1 b1

=head1 b

EOF
    
    my $t = Test::Mojo::DOM::Inspector->new(Marquee->c->res->dom);
    $t->at('ul li:nth-child(1) a')->attr_is('href', '#a');
    $t->at('ul li:nth-child(2) a')->attr_is('href', '#b');
    $t->at('ul li:nth-child(3) a')->attr_is('href', '#c');
    $t->at('ul li:nth-child(4) a')->attr_is('href', '#a1');
    $t->at('ul li:nth-child(5) a')->attr_is('href', '#b1');
    $t->at('ul li:nth-child(6) a')->attr_is('href', '#b2');
}

# basic

$t->get_ok('/perldoc/Marquee')
    ->status_is(200)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->text_is('title', 'Marquee - Yet another Mojolicious based web framework - Pod viewer')
    ->text_is('a[name=COPYRIGHT_AND_LICENSE]', 'COPYRIGHT AND LICENSE');

# deep namespace

$t->get_ok('/perldoc/Marquee/SSIHandler')
    ->status_is(200)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->text_is('title', 'Marquee::SSIHandler - SSI handler base class - Pod viewer')
    ->element_exists('a[name=SEE_ALSO]')
    ->dom_inspector(sub {
        my $t = shift;
        $t->at('#auto_detected_see_also *:nth-child(2)')->text_is('Marquee');
        $t->at('#auto_detected_see_also *:nth-child(3)')->text_is('Marquee::SSIHandler::EP');
        $t->at('#auto_detected_see_also *:nth-child(4)')->text_is('Marquee::SSIHandler::EPL');
        $t->at('#auto_detected_see_also *:nth-child(2)')->attr_is('href', '/perldoc/Marquee');
        $t->at('#auto_detected_see_also *:nth-child(3)')->attr_is('href', '/perldoc/Marquee/SSIHandler/EP');
        $t->at('#auto_detected_see_also *:nth-child(4)')->attr_is('href', '/perldoc/Marquee/SSIHandler/EPL');
    });

# other lib path

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->plugin('PODViewer', {no_see_also => 1, paths => [catdir(dirname(__FILE__), '../lib')]});

$t = Test::Mojo::DOM->new($app);

$t->get_ok('/perldoc/Marquee/SSIHandler')
    ->status_is(200)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->text_is('title', 'Marquee::SSIHandler - SSI handler base class - Pod viewer')
    ->element_exists('a[name=SEE_ALSO]');
    

__END__

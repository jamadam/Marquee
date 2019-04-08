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

use Test::More tests => 10;

{
    package SubClass;
    use Mojo::Base 'Marquee';
    use Test::More;
    use feature 'signatures';
    no warnings "experimental::signatures";
    
    sub dispatch($self, @args) {
        $self->SUPER::dispatch(@args);
        is(Marquee->c, SubClass->c, 'right namespace');
    }
}
{
    package SubClass2;
    use Mojo::Base qw{Marquee};
    use feature 'signatures';
    no warnings "experimental::signatures";
    
    sub dispatch($self) {
        $self->SUPER::dispatch;
        $self->c->res->body('overridden');
    }
}

my $app;
my $t;

$app = SubClass->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$app->default_file('index.html');
$t = Test::Mojo::DOM->new($app);

$t->get_ok('/dir1/index.html')
    ->status_is(200)
    ->content_type_is('text/html;charset=UTF-8')
    ->header_is('Content-Length', 15)
    ->content_is(qq{dir1/index.html});

$app = SubClass2->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");

$t = Test::Mojo::DOM->new($app);

$t->get_ok('/index.txt')
    ->status_is(200)
    ->header_is('Content-Length', 10)
    ->content_is("overridden");

__END__

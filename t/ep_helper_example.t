use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Marquee;

use Test::More tests => 18;

my $app = Marquee->new;
$app->plugin('EPHelperExample');

is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, '0'), '0';
is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, '1'), '1';
is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, '10'), '10';
is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, '100'), '100';
is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, '1000'), '1,000';
is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, '10000'), '10,000';
is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, '100000'), '100,000';
is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, '1000000'), '1,000,000';
is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, '1,000'), '1,000';
is $app->dynamic->handlers->{ep}->funcs->{commify}->(undef, undef, 'abc'), 'abc';

is $app->dynamic->handlers->{ep}->funcs->{min}->(undef, undef, [3,1,2,6,5]), '1';
is $app->dynamic->handlers->{ep}->funcs->{min}->(undef, undef, 3,1,2,6,5), '1';

is $app->dynamic->handlers->{ep}->funcs->{max}->(undef, undef, [3,1,2,6,5]), '6';
is $app->dynamic->handlers->{ep}->funcs->{max}->(undef, undef, 3,1,2,6,5), '6';

is $app->dynamic->handlers->{ep}->funcs->{replace}->(undef, undef, 'test test', 'es', 'zz'), 'tzzt tzzt';
is $app->dynamic->handlers->{ep}->funcs->{replace}->(undef, undef, 'test test', '.st', ''), 'test test';
is $app->dynamic->handlers->{ep}->funcs->{replace}->(undef, undef, 'test test', qr/.st/, ''), 't t';
is $app->dynamic->handlers->{ep}->funcs->{replace}->(undef, undef, 'test teSt', qr/.st/i, ''), 't t';

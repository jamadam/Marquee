use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), '../lib';
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';
use Test::More;
use Marquee;

use Test::More tests => 17;

my $app = Marquee->new;
$app->plugin('EPHelperExample');

is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, '0'), '0';
is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, '1'), '1';
is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, '10'), '10';
is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, '100'), '100';
is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, '1000'), '1,000';
is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, '10000'), '10,000';
is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, '100000'), '100,000';
is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, '1000000'), '1,000,000';
is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, '1,000'), '1,000';
is $app->ssi_handlers->{ep}->funcs->{commify}->(undef, 'abc'), 'abc';

is $app->ssi_handlers->{ep}->funcs->{min}->(undef, [3,1,2,6,5]), '1';
is $app->ssi_handlers->{ep}->funcs->{min}->(undef, 3,1,2,6,5), '1';

is $app->ssi_handlers->{ep}->funcs->{max}->(undef, [3,1,2,6,5]), '6';
is $app->ssi_handlers->{ep}->funcs->{max}->(undef, 3,1,2,6,5), '6';

is $app->ssi_handlers->{ep}->funcs->{replace}->(undef, 'test test', 'es', 'zz'), 'tzzt tzzt';
is $app->ssi_handlers->{ep}->funcs->{replace}->(undef, 'test test', '.st', ''), 'test test';
is $app->ssi_handlers->{ep}->funcs->{replace}->(undef, 'test test', qr/.st/, ''), 't t';
#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';

$ENV{MOJO_HOME} = File::Spec->rel2abs(dirname(__FILE__));

my $app = OfficialSite->new;
$app->under_development(1);
$app->start;

package OfficialSite;
use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec;
use Mojo::Base 'Marquee';
use feature 'signatures';
no warnings 'experimental::signatures';

sub new($class, @args) {
    my $self = $class->SUPER::new(@args);
    
    $self->document_root($self->home->rel_file('.'));
    $self->default_file('index.html');
    $self->log_file(File::Spec->rel2abs(dirname(__FILE__). "/log/Marquee.log"));
    
    my $r = $self->route;
    $r->route(qr{^/admin/})->to(sub() {
        my $res = Marquee->c->tx->res;
        $res->code(200);
        $res->headers->content_type($app->types->type('html'));
        $res->body('passed');
    });
    
    $self->plugin(AuthPretty => [
        qr{^/admin/} => 'Secret Area' => sub($username,$password) {
            return $username eq 'jamadam' && $password eq 'pass';
        },
    ] => File::Spec->rel2abs(dirname(__FILE__). "/log/auth_pretty"));
    
    return $self;
}

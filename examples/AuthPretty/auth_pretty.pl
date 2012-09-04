#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;

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
use Mojo::Base 'Marquee';

    sub new {
        my $self = shift->SUPER::new(@_);
        
        $self->document_root($self->home->rel_dir('.'));
        $self->default_file('index.html');
        
        $self->plugin(Router => sub {
            my $r = shift;
            
            $r->route(qr{^/admin/})->to(sub {
                my $res = Marquee->c->tx->res;
                $res->code(200);
                $res->headers->content_type($app->types->type('html'));
                $res->body('passed');
            });
        });
        
        $self->plugin(AuthPretty => [
            qr{^/admin/} => 'Secret Area' => sub {
                my ($username, $password) = @_;
                return $username eq 'jamadam' && $password eq 'pass';
            },
        ] => "$FindBin::Bin/auth_log/");
        
        return $self;
    }

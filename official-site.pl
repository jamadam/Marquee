#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';

$ENV{MOJO_HOME} = File::Spec->rel2abs(dirname(__FILE__));

my $app = OfficialSite->new(domain => 'http://mrqe.biz');
#$app->under_development(1);
$app->config(hypnotoad => {listen => ['http://*:8002']});
$app->start;

package OfficialSite;
use strict;
use warnings;
use utf8;
use Mojo::Base 'Marquee';

    sub new {
        my $self = shift->SUPER::new(@_);
        
        my $pod = $self->plugin(PODViewer => {no_route => 1, paths => ['./lib']});
        my $md  = $self->plugin(Markdown => {no_route => 1});
        $self->document_root($self->home->rel_dir('.'));
        
        $self->plugin(Router => sub {
            my $r = shift;
            
            $r->route(qr{^/(.+\.md)?$})->to(sub {
                $md->serve_markdown($self->search_static(shift || 'readme.md'));
                $self->strip_domain;
            });
            
            $r->route(qr{^/perldoc/(.*)})->to(sub {
                if (my $name = shift) {
                    $pod->serve_pod_by_name($name);
                } else {
                    $pod->serve_index;
                }
            });
        });
        
        return $self;
    }
    
    sub strip_domain {
        my ($self) = @_;
        
        my $domain = $self->{domain};
        
        my $res = Marquee->c->tx->res;
        my $dom = $res->dom;
        $dom->find("a[href^=$domain/]")->each(sub {
            my $e = shift;
            my $org = $e->attrs('href');
            $org =~ s{^\Q$domain\E}{};
            $e->attrs('href', $org);
        });
        $res->body($dom);
    }

package MarqueeOfficial;
use strict;
use warnings;
use utf8;
use Mojo::Base 'Marquee';

    has 'domain' => '';
    has 'locale' => '';
    
    sub new {
        my $self = shift->SUPER::new(@_);
        
        my $lib = $self->locale ? './docs/localize/'. $self->locale. '/lib' : './lib';
        my $pod = $self->plugin(PODViewer => {no_route => 1, paths => [$lib]});
        my $md  = $self->plugin(Markdown => {no_route => 1});
        $self->document_root($self->home);
        
        $self->plugin(Router => sub {
            my $r = shift;
            
            $r->route(qr{^/(.+\.md)?$})->to(sub {
                my $filename = shift || 'readme.md';
                if ($self->locale) {
                    $filename = "docs/localize/". $self->locale. '/'. $filename;
                }
                $md->serve_markdown($self->search_static(shift || $filename));
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
        $dom->find("img[src^=$domain/]")->each(sub {
            my $e = shift;
            my $org = $e->attrs('src');
            $org =~ s{^\Q$domain\E}{};
            $e->attrs('src', $org);
        });
        $res->body($dom);
    }

1;

package MarqueeOfficial;
use strict;
use warnings;
use utf8;
use Mojo::Base 'Marquee';
use Mojo::Util qw'encode';

    has 'domain' => '';
    has 'locale' => '';
    
    sub new {
        my $self = shift->SUPER::new(@_);
        
        my $lib = $self->locale ? './docs/localize/'. $self->locale. '/lib' : './lib';
        my $pod = $self->plugin(PODViewer => {no_route => 1, paths => [$lib]});
        my $md  = $self->plugin(Markdown => {no_route => 1});
        $self->document_root($self->home);
        
        my $r = $self->route;
        
        $r->route(qr{^/(.+\.md)?$})->to(sub {
            my $filename = shift || 'readme.md';
            if ($self->locale) {
                $filename = "docs/localize/". $self->locale. '/'. $filename;
            }
            $md->serve_markdown($self->static->search($filename));
            $self->strip_domain;
        });
        
        $r->route(qr{^/perldoc/(.*)})->to(sub {
            if (my $name = shift) {
                $pod->serve_pod_by_name($name);
            } else {
                $pod->serve_index;
            }
        });
        
        $self->static->maxage(604800);
        
        $self->plugin('ETag');
        
        return $self;
    }
    
    sub strip_domain {
        my ($self) = @_;
        
        my $domain = $self->{domain};
        
        my $res = Marquee->c->tx->res;
        my $dom = $res->dom;
        $dom->find("a[href^=$domain/]")->each(sub {
            my $e = shift;
            my $org = $e->attr('href');
            $org =~ s{^\Q$domain\E}{};
            $e->attr('href', $org);
        });
        $dom->find("img[src^=$domain/]")->each(sub {
            my $e = shift;
            my $org = $e->attr('src');
            $org =~ s{^\Q$domain\E}{};
            $e->attr('src', $org);
        });
        $res->body(encode('UTF-8', $dom));
    }

1;

package MarqueeOfficial;
use strict;
use warnings;
use utf8;
use Mojo::Base 'Marquee';
use feature 'signatures';
no warnings "experimental::signatures";
use Mojo::Util qw'encode';

has 'domain' => '';
has 'locale' => '';

sub new($class, @args) {
    my $self = $class->SUPER::new(@args);
    my $lib = $self->locale ? './docs/localize/'. $self->locale. '/lib' : './lib';
    my $pod = $self->plugin(PODViewer => {no_route => 1, paths => [$lib]});
    my $md  = $self->plugin(Markdown => {no_route => 1});
    $self->document_root($self->home);
    
    my $r = $self->route;
    
    $r->route(qr{^/(.+\.md)?$})->to(sub($filename) {
        $filename ||= 'readme.md';
        if ($self->locale) {
            $filename = "docs/localize/". $self->locale. '/'. $filename;
        }
        $md->serve_markdown($self->static->search($filename));
        $self->strip_domain;
    });
    
    $r->route(qr{^/perldoc/(.*)})->to(sub($name) {
        if ($name) {
            $pod->serve_pod_by_name($name);
        } else {
            $pod->serve_index;
        }
    });
    
    $self->static->maxage(604800);
    
    $self->plugin('ETag');
    
    return $self;
}

sub strip_domain($self) {
    my $domain = $self->{domain};
    my $res = Marquee->c->tx->res;
    my $dom = $res->dom;
    $dom->find("a[href^=$domain/]")->each(sub($e, $) {
        my $org = $e->attr('href');
        $org =~ s{^\Q$domain\E}{};
        $e->attr('href', $org);
    });
    $dom->find("img[src^=$domain/]")->each(sub($e, $) {
        my $org = $e->attr('src');
        $org =~ s{^\Q$domain\E}{};
        $e->attr('src', $org);
    });
    $res->body(encode('UTF-8', $dom));
}

1;

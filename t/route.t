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
use Mojo::Message::Request;
use Mojo::Transaction;
use Marquee::Plugin::Router::Route;
use Data::Dumper;
use Marquee;
use Marquee::Context;
use Test::More tests => 27;
{
    my $route = Marquee::Plugin::Router::Route->new;
    $route->route('/1')->to(my $cb0 = \sub {});
    is_deeply($route->aggregate->data->[0], ['/1', undef, $cb0]);
    $route->route('/2')->to(my $cb1 = \sub {});
    is_deeply($route->aggregate->data->[0], ['/1', undef, $cb0]);
    is_deeply($route->aggregate->data->[1], ['/2', undef, $cb1]);
    $route->route('/3')->to(my $cb2 = \sub {});
    is_deeply($route->aggregate->data->[0], ['/1', undef, $cb0]);
    is_deeply($route->aggregate->data->[1], ['/2', undef, $cb1]);
    is_deeply($route->aggregate->data->[2], ['/3', undef, $cb2]);
}

# via

{
    my $route = Marquee::Plugin::Router::Route->new;
    $route->route('/1')->via('get')->to(my $cb0 = \sub {});
    is($route->aggregate->data->[0][1][0]->(gen_context('get')), 1);
    is($route->aggregate->data->[0][1][0]->(gen_context('post')), '');
    $route->route('/2')->via('get', 'post')->to(my $cb1 = \sub {});
    is($route->aggregate->data->[0][1][0]->(gen_context('get')), 1);
    is($route->aggregate->data->[0][1][0]->(gen_context('post')), '');
    is($route->aggregate->data->[1][1][0]->(gen_context('get')), 1);
    is($route->aggregate->data->[1][1][0]->(gen_context('post')), 1);
    is($route->aggregate->data->[1][1][0]->(gen_context('put')), '');
}

# viax

{
    my $route = Marquee::Plugin::Router::Route->new;
    $route->route('/1')->viax('get')->to(my $cb0 = \sub {});
    is($route->aggregate->data->[0][1][0]->(gen_context('get')), 1);
    is($route->aggregate->data->[0][1][0]->(gen_context('post')), '');
    is($route->aggregate->data->[1][1][0]->(gen_context('get')), '');
    is($route->aggregate->data->[1][1][0]->(gen_context('post')), 1);
    $route->route('/2')->viax('get', 'post')->to(my $cb1 = \sub {});
    is($route->aggregate->data->[0][1][0]->(gen_context('get')), 1);
    is($route->aggregate->data->[0][1][0]->(gen_context('post')), '');
    is($route->aggregate->data->[1][1][0]->(gen_context('get')), '');
    is($route->aggregate->data->[1][1][0]->(gen_context('post')), 1);
    is($route->aggregate->data->[2][1][0]->(gen_context('get')), 1);
    is($route->aggregate->data->[2][1][0]->(gen_context('post')), 1);
    is($route->aggregate->data->[2][1][0]->(gen_context('put')), '');
    is($route->aggregate->data->[3][1][0]->(gen_context('get')), '');
    is($route->aggregate->data->[3][1][0]->(gen_context('post')), '');
    is($route->aggregate->data->[3][1][0]->(gen_context('put')), 1);
}

sub gen_context {
    my $method = shift;
    my $req = Mojo::Message::Request->new->method($method);
    my $tx = Mojo::Transaction->new->req($req);
    return Marquee::Context->new(tx => $tx, app => Marquee->new);
}

__END__

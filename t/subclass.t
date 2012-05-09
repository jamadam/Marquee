use strict;
use warnings;
use utf8;
use FindBin;
use lib 'lib', "$FindBin::Bin/lib";
use Test::More;
use Test::Mojo::DOM;
use Mojo::Date;
    
    use Test::More tests => 10;

    my $app;
    my $t;
    
    $app = SubClass->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $app->default_file('index.html');
    $app->auto_index(1);
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/dir1/index.html')
        ->status_is(200)
        ->content_type_is('text/html;charset=UTF-8')
        ->header_is('Content-Length', 15)
        ->content_is(qq{dir1/index.html});

    $app = SubClass2->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    
    $t = Test::Mojo->new($app);

    $t->get_ok('/index.txt')
        ->status_is(200)
        ->header_is('Content-Length', 10)
        ->content_is("overridden");

package SubClass;
use Mojo::Base 'MojoSimpleHTTPServer';
use Test::More;

    our $CONTEXT = MojoSimpleHTTPServer::Context->new; # do nothing
    
    sub dispatch {
        shift->SUPER::dispatch(@_);
        is(MojoSimpleHTTPServer->context, SubClass->context, 'right namespace');
    }

package SubClass2;
use Mojo::Base qw{MojoSimpleHTTPServer};

sub dispatch {
    my ($self) = @_;
    $self->SUPER::dispatch;
    $self->context->tx->res->body('overridden');
}

__END__

package Template_Basic;
use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), '../lib';
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';
use Test::More;
use Test::Mojo::DOM;
use MojoSimpleHTTPServer;
use Mojo::Date;
use MojoSimpleHTTPServer::SSIHandler::EP;

    use Test::More tests => 1;
    
    ### add_function
    
    my $ep = MojoSimpleHTTPServer::SSIHandler::EP->new;
    $ep->add_function(myfunc => sub {});
    is ref $ep->funcs->{myfunc}, 'CODE';
    
    eval {
        $ep->add_function(time => sub {});
    };
    
    is $@, q{Can't modify core function time};

__END__

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

    use Test::More tests => 8;
    
    ### add_function
    
    my $ep = MojoSimpleHTTPServer::SSIHandler::EP->new;
    eval {
        $ep->add_function(myfunc => sub {});
    };
    
    is ref $ep->funcs->{myfunc}, 'CODE';
    is $@, '';
    
    eval {
        $ep->add_function(time => sub {});
    };
    
    is $ep->funcs->{time}, undef;
    like $@, qr{Can't modify built-in function time};
    
    eval {
        $ep->add_function(add_function => sub {});
    };
    
    is ref $ep->funcs->{add_function}, 'CODE';
    is $@, '';
    
    eval {
        $ep->add_function('a b c' => sub {});
    };
    
    is ref $ep->funcs->{'a b c'}, '';
    like $@, qr'Function name must be';
    
__END__

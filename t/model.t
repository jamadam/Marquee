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
use Mojo::Date;
    
    use Test::More tests => 6;

    my $app;
    my $t;
    
    $app = MyApp->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/Marquee.log");
    $app->stash->set(model => $app->model);
    
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/model.html')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=UTF-8')
        ->header_is('Content-Length', 54)
        ->text_is('filename', 'model.html.ep')
        ->text_is('test1', 'FOO');

package MyApp;
use Mojo::Base 'Marquee';
    
    INIT {
        __PACKAGE__->attr(model => sub {MyApp::Model->new});
    }

package MyApp::Model;
use strict;
use warnings;
    
    sub new {
        my ($class) = @_;
        return bless {
            foo => 'FOO',
            bar => 'BAR',
            baz => 'BAZ',
        }, $class;
    }
    
    sub retrieve {
        return $_[0]->{$_[1]};
    }

__END__

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
use MojoSimpleHTTPServer;

    use Test::More tests => 21;

    my $app;
    my $t;
    
    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $app->plugin('PODViewer');
    
    $t = Test::Mojo::DOM->new($app);
    
    # basic
    
    $t->get_ok('/perldoc/MojoSimpleHTTPServer')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=UTF-8')
        ->text_is('title', 'MojoSimpleHTTPServer - Simple HTTP server with Server-side include')
        ->text_is('a[name=COPYRIGHT_AND_LICENSE]', 'COPYRIGHT AND LICENSE');
    
    # deep namespace
    
    $t->get_ok('/perldoc/MojoSimpleHTTPServer/SSIHandler')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=UTF-8')
        ->text_is('title', 'MojoSimpleHTTPServer::SSIHandler - SSI handler base class')
        ->element_exists('a[name=SEE_ALSO]')
        ->dom_inspector(sub {
            my $t = shift;
            $t->at('#auto_detected_see_also *:nth-child(2)')->text_is('MojoSimpleHTTPServer');
            $t->at('#auto_detected_see_also *:nth-child(3)')->text_is('MojoSimpleHTTPServer::SSIHandler::EP');
            $t->at('#auto_detected_see_also *:nth-child(4)')->text_is('MojoSimpleHTTPServer::SSIHandler::EPL');
            $t->at('#auto_detected_see_also *:nth-child(2)')->attr_is('href', '/perldoc/MojoSimpleHTTPServer');
            $t->at('#auto_detected_see_also *:nth-child(3)')->attr_is('href', '/perldoc/MojoSimpleHTTPServer/SSIHandler/EP');
            $t->at('#auto_detected_see_also *:nth-child(4)')->attr_is('href', '/perldoc/MojoSimpleHTTPServer/SSIHandler/EPL');
        });
    
    # other lib path
    
    $t->get_ok('/perldoc/perl')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=UTF-8')
        ->text_is('title', 'perl - Practical Extraction and Report Language')
        ->element_exists('a[name=SEE_ALSO]');

__END__
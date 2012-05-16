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

    use Test::More tests => 50;

    my $app;
    my $t;

    $app = MojoSimpleHTTPServer->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/MojoSimpleHTTPServer.log");
    $t = Test::Mojo::DOM->new($app);
    
    $t->get_ok('/not_good.html')
        ->status_is(500)
        ->content_is('500 Internal server error');
    
    $t->get_ok('/not_good2.html')
        ->status_is(500)
        ->content_is('500 Internal server error');
    
    ### debug screen
    
    $app->under_development(1);
    
    $t->get_ok('/not_good.html')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=UTF-8')
        ->dom_inspector(sub {
            my $t = shift;
            $t->at('title')->text_is('Debug Screen');
            $t->at('#showcase pre')->text_like(qr{Global symbol "\$nonexitsts" requires explicit package name at (.+?)t/public_html/not_good.html.ep line 4\.});
            $t->at('#context tr:nth-child(1) td.key')->text_is('1.');
            $t->at('#context tr:nth-child(1) td.value pre')->content_xml_is('&lt;filename&gt;not_good.html.ep&lt;/filename&gt;');
            $t->at('#context tr:nth-child(2) td.key')->text_is('2.');
            $t->at('#context tr:nth-child(2) td.value pre')->content_xml_is('');
            $t->at('#context tr:nth-child(3) td.key')->text_is('3.');
            $t->at('#context tr:nth-child(3) td.value pre')->content_xml_is('');
            $t->at('#context tr:nth-child(4) td.key')->text_is('4.');
            $t->at('#context tr:nth-child(4) td.value pre')->content_xml_is('&lt;test1&gt;&lt;%= $nonexitsts =%&gt;&lt;/test1&gt;');
            
            ### request
            
            $t->at('#request tr:nth-child(1) td.key')->content_xml_is('Method:');
            $t->at('#request tr:nth-child(1) td.value pre')->content_xml_is('GET');
            $t->at('#request tr:nth-child(2) td.key')->content_xml_is('URL:');
            $t->at('#request tr:nth-child(2) td.value pre')->content_xml_is('/not_good.html');
            $t->at('#request tr:nth-child(3) td.key')->content_xml_is('Base URL:');
            $t->at('#request tr:nth-child(3) td.value pre')->content_xml_like(qr'^http://localhost:');
            $t->at('#request tr:nth-child(4) td.key')->content_xml_is('Parameters:');
            $t->at('#request tr:nth-child(4) td.value pre')->content_xml_is("{}\n");
            $t->at('#request tr:nth-child(4) td.key')->content_xml_is('Parameters:');
            $t->at('#request tr:nth-child(4) td.value pre')->content_xml_is("{}\n");
            $t->at('#request tr:nth-child(5) td.key')->content_xml_is('Stash:');
            $t->at('#request tr:nth-child(5) td.value pre')->content_xml_is("{}\n");
            
            ### more
            
            $t->at('#more tr:nth-child(1) td.key')->content_xml_is('Perl:');
            $t->at('#more tr:nth-child(1) td.value pre')->content_xml_like(qr'^v\d+\.\d+');
            $t->at('#more tr:nth-child(2) td.key')->content_xml_is('MSHS:');
            $t->at('#more tr:nth-child(2) td.value pre')->content_xml_like(qr'^\d+\.\d+');
            
            ### others
            
            $t->at('#trace .value')->element_exists;
        });
    
    ### stash
    
    $app->stash->(test => 'value');
    
    $t->get_ok('/template_error.html')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=UTF-8')
        ->dom_inspector(sub {
            my $t = shift;
            $t->at('#request tr:nth-child(5) td.key')->content_xml_is('Stash:');
            $t->at('#request tr:nth-child(5) td.value pre')->content_xml_is("{\n  &#39;test&#39; =&gt; &#39;value&#39;\n}\n");
        });
    
    ### error in included template
    
    $t->get_ok('/template_error.html')
        ->status_is(200)
        ->header_is('Content-Type', 'text/html;charset=UTF-8')
        ->dom_inspector(sub {
            my $t = shift;
            $t->at('title')->text_is('Debug Screen');
            $t->at('#showcase pre')->text_like(qr{Global symbol "\$nonexist" requires explicit package name at (.+)/t/public_html/./template_error/1.html.ep line 2.});
            $t->at('#context tr:nth-child(1) td.key')->text_is('1.');
            $t->at('#context tr:nth-child(1) td.value pre')->content_xml_is('&lt;filename&gt;/template_error/1.html.ep&lt;/filename&gt;');
            $t->at('#context tr:nth-child(2) td.key')->text_is('2.');
            $t->at('#context tr:nth-child(2) td.value pre')->content_xml_is('&lt;%= $nonexist %&gt;');
        });

__END__

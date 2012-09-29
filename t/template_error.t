use strict;
use warnings;
use utf8;
use FindBin;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Test::Mojo::DOM;
use Test::Path qw'path_is path_like';
use Mojo::Date;
use Marquee;

use Test::More tests => 83;

my $app;
my $t;

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->log_file("$FindBin::Bin/Marquee.log");
$t = Test::Mojo::DOM->new($app);

$t->get_ok('/not_good.html')
    ->status_is(500)
    ->element_exists_not('body#debugScreen')
    ->text_like('title', qr'500 Internal server error'i);

$t->get_ok('/not_good2.html')
    ->status_is(500)
    ->element_exists_not('body#debugScreen')
    ->text_like('title', qr'500 Internal server error'i);

### debug screen

$app->under_development(1);

### 404 on development mode

$t->get_ok('/not_found.html')
    ->status_is(404)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->element_exists('body#debugScreen')
    ->dom_inspector(sub {
        my $t = shift;
        $t->at('title')->text_is('Debug Screen');
        $t->at('#showcase pre')->text_is(q{File Not Found});
        
        ### request
        
        $t->at('#request tr:nth-child(1) td.key')->content_xml_is('Method:');
        $t->at('#request tr:nth-child(1) td.value pre')->content_xml_is('GET');
        $t->at('#request tr:nth-child(2) td.key')->content_xml_is('URL:');
        $t->at('#request tr:nth-child(2) td.value pre')->content_xml_is('/not_found.html');
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
        $t->at('#more tr:nth-child(2) td.key')->content_xml_is('Mojo:');
        $t->at('#more tr:nth-child(2) td.value pre')->content_xml_like(qr'^\d+\.\d+');
        $t->at('#more tr:nth-child(3) td.key')->content_xml_is('Marquee:');
        $t->at('#more tr:nth-child(3) td.value pre')->content_xml_like(qr'^\d+\.\d+');
        
        ### others
        
        $t->at('#trace .value')->element_exists;
    });

$t->get_ok('/not_good.html')
    ->status_is(500)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->element_exists('body#debugScreen')
    ->element_exists('#context .important')
    ->dom_inspector(sub {
        my $t = shift;
        $t->at('title')->text_is('Debug Screen');
        my $path = canonpath('t/public_html/not_good.html.ep');
        $t->at('#showcase pre')->text_like(qr{Global symbol "\$nonexitsts" requires explicit package name at (.+?)\Q$path\E line 4\.});
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
        $t->at('#more tr:nth-child(2) td.key')->content_xml_is('Mojo:');
        $t->at('#more tr:nth-child(2) td.value pre')->content_xml_like(qr'^\d+\.\d+');
        $t->at('#more tr:nth-child(3) td.key')->content_xml_is('Marquee:');
        $t->at('#more tr:nth-child(3) td.value pre')->content_xml_like(qr'^\d+\.\d+');
        
        ### others
        
        $t->at('#trace .value')->element_exists;
    });

### error in included template

$app->stash->set(test => 'value');

$t->get_ok('/template_error.html')
    ->status_is(500)
    ->header_is('Content-Type', 'text/html;charset=UTF-8')
    ->element_exists('body#debugScreen')
    ->element_exists('#context .important')
    ->dom_inspector(sub {
        my $t = shift;
        $t->at('#request tr:nth-child(5) td.key')->content_xml_is('Stash:');
        $t->at('#request tr:nth-child(5) td.value pre')->content_xml_is("{\n  &#39;test&#39; =&gt; &#39;value&#39;\n}\n");
        $t->at('title')->text_is('Debug Screen');
        my $path = canonpath('/t/public_html/template_error/1.html.ep');
        $t->at('#showcase pre')->text_like(qr{Global symbol "\$nonexist" requires explicit package name at (.+)\Q$path\E line 2.});
        $t->at('#context tr:nth-child(1) td.key')->text_is('1.');
        $t->at('#context tr:nth-child(1) td.value pre')->content_xml_is('&lt;filename&gt;/template_error/1.html.ep&lt;/filename&gt;');
        $t->at('#context tr:nth-child(2) td.key')->text_is('2.');
        $t->at('#context tr:nth-child(2) td.value pre')->content_xml_is('&lt;test1&gt;&lt;%= $nonexist %&gt;&lt;/test1&gt;');
    });

### don't leak debug message on production mode

$app = Marquee->new;
$app->document_root("$FindBin::Bin/public_html");
$app->hook(around_dispatch => sub {
    die 'hoge';
});

$t = Test::Mojo::DOM->new($app);

$t->get_ok('/');
$t->status_is(500);
$t->text_is('title', '500 Internal Server Error');


__END__

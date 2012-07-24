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
use Marquee;
use Mojo::Util qw/encode md5_sum/;

use Test::More tests => 26;

my $app;
my $t;

{
    $app = Marquee->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/Marquee.log");
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/cache.html')
        ->status_is(200);
    $t->get_ok('/cache.html')
        ->status_is(200);
    
    my $expected_key = md5_sum(encode('UTF-8', "$FindBin::Bin/public_html/cache.html.ep"));
    my $cache = $app->ssi_handlers->{ep}->template_cache;
    is scalar keys %{$cache->{1}}, 1, 'right cache amount';
    my $mt = $cache->get($expected_key);
    is ref $mt, 'Mojo::Template';
    ok $mt->compiled;
}

{
    $app = Marquee->new;
    $app->document_root("$FindBin::Bin/public_html");
    $app->log_file("$FindBin::Bin/Marquee.log");
    $t = Test::Mojo->new($app);
    
    $t->get_ok('/cache3.html')
        ->status_is(200);
    $t->get_ok('/cache3.html')
        ->status_is(200);
    
    my $expected_key = md5_sum(encode('UTF-8', "$FindBin::Bin/public_html/cache3.html.epl"));
    my $cache = $app->ssi_handlers->{epl}->template_cache;
    is scalar keys %{$cache->{1}}, 1, 'right cache amount';
    my $mt = $cache->get($expected_key);
    is ref $mt, 'Mojo::Template';
    ok $mt->compiled;
}

### Detect template update
{
    my $file;
    open($file, "> $FindBin::Bin/public_html/cache2.html.ep");
    print $file 'a';
    close($file);
    
    $t->get_ok('/cache2.html')
        ->status_is(200)
        ->content_is("a\n");
    
    sleep(1);
    
    open($file, "> $FindBin::Bin/public_html/cache2.html.ep");
    print $file 'b';
    close($file);
    
    $t->get_ok('/cache2.html')
        ->status_is(200)
        ->content_is("b\n");
    
    unlink("$FindBin::Bin/public_html/cache2.html.ep");
}

### Detect sub template update
{
    my $file;
    open($file, "> $FindBin::Bin/public_html/cache4_sub.html.ep");
    print $file 'a';
    close($file);
    
    $t->get_ok('/cache4.html')
        ->status_is(200)
        ->content_is("a\n");
    
    sleep(1);
    
    open($file, "> $FindBin::Bin/public_html/cache4_sub.html.ep");
    print $file 'b';
    close($file);
    
    $t->get_ok('/cache4.html')
        ->status_is(200)
        ->content_is("b\n");
    
    unlink("$FindBin::Bin/public_html/cache4_sub.html.ep");
}

__END__

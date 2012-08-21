use strict;
use warnings;

{
    my $app = MyApp->new;
    $app->document_root('./');
    warn $app->document_root;
    $app->plugin('AutoIndex');
    $app->start;
}

package MyApp;
use Mojo::Base 'Marquee';

__END__
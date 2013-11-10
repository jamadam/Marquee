#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Marquee;

my $namespace = 'FormValidatorLazy';

my $app = Marquee->new;
$app->secret('afewfweweuhu');
$app->document_root("$FindBin::Bin/public_form_validator_lazy");

my $r = $app->plugin('Router' => sub {
    my $r = shift;
    
    $r->route('/receptor1.html')->viax('post')->to(sub {
        Marquee->c->serve('receptor1.html');
    });
    
    $r->route('/receptor2.html')->viax('post')->to(sub {
        Marquee->c->serve('receptor2.html');
    });
});

$app->plugin(FormValidatorLazy => {
    namespace => $namespace,
    action => '/receptor1.html',
    blackhole => sub {
        Marquee->c->app->error_document->serve(400, $_[0]);
    },
});

$app->start;

1;

__END__

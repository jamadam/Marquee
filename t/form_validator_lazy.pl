#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Marquee;
use feature 'signatures';
no warnings "experimental::signatures";

my $namespace = 'FormValidatorLazy';

my $app = Marquee->new;
$app->secrets(['afewfweweuhu']);
$app->document_root("$FindBin::Bin/public_form_validator_lazy");

my $r = $app->plugin('Router' => sub($r) {
    
    $r->route('/receptor1.html')->viax('post')->to(sub() {
        Marquee->c->serve('receptor1.html');
    });
    
    $r->route('/receptor2.html')->viax('post')->to(sub() {
        Marquee->c->serve('receptor2.html');
    });
});

$app->plugin(FormValidatorLazy => {
    namespace => $namespace,
    action => '/receptor1.html',
    blackhole => sub($err) {
        Marquee->c->app->error_document->serve(400, $err);
    },
});

$app->start;

1;

__END__

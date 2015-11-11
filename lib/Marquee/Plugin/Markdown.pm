package Marquee::Plugin::Markdown;
use strict;
use warnings;
use Mojo::ByteStream 'b';
use Mojo::DOM;
use Mojo::Util qw'encode decode';
use Mojo::Base 'Marquee::Plugin';
use feature 'signatures';
no warnings "experimental::signatures";
use Text::Markdown 'markdown';
use File::Find;

sub register($self, $app, $conf={}) {
    
    push(@{$app->roots}, __PACKAGE__->Marquee::asset());
    
    if (! $conf->{no_route}) {
    
        my $r = $app->route;
        
        $r->route(qr{^/markdown/(.+\.md$)})->to(sub($name) {
            $self->serve_markdown($name)
        });
        $r->route(qr{^/markdown/(.*/)?$})->to(sub($name) {
            $self->serve_index(($name || ''));
        });
    }
}

sub serve_index($self, $path) {

    my $c   = Marquee->c;
    my $app = $c->app;
    
    $path = File::Spec->catdir($app->document_root, $path);
    
    my @found;
    
    find(sub {
        push(@found, $File::Find::name) if ($File::Find::name =~ qr{\.md$});
    }, $path);
    
    @found = sort {$a cmp $b} @found;
    
    $c->stash->set(
        static_dir  => 'static',
        files       => \@found,
    );
    
    $c->res->body(
        encode('UTF-8',
            $app->dynamic->handlers->{ep}->render_traceable(
                __PACKAGE__->Marquee::asset('markdown_index.html.ep')
            )
        )
    );
    $c->res->code(200);
    $c->res->headers->content_type($app->types->type('html'));
}

sub serve_markdown($self, $path) {
    
    my $c = Marquee->c;
    my $app = $c->app;
    
    open my $file, '<', $path or die "cannot open $path";
    my $html = markdown(decode('UTF-8', join('', <$file>)));
    my $dom = Mojo::DOM->new($html);
    
    $dom->find('pre code')->each(sub($e, $) {
        my $attr = $e->attr;
        my $class = $attr->{class};
        $attr->{class} = defined $class ? "$class prettyprint" : 'prettyprint';
    });
    
    my $title = 'Markdown Viewer';
    $dom->find('h1,h2,h3,h4,h5')->first(sub($e) {
        $title = $e->text;
    });

    Marquee->c->stash->set(
        title       => $title,
        static_dir  => 'static',
        markdown     => "$dom",
    );
    
    $c->res->body(
        encode('UTF-8',
            $app->dynamic->handlers->{ep}->render_traceable(
                __PACKAGE__->Marquee::asset('markdown.html.ep')
            )
        )
    );
    $c->res->code(200);
    $c->res->headers->content_type($app->types->type('html'));
}

1;

__END__

=head1 NAME

Marquee::Plugin::Markdown - Markdown renderer plugin

=head1 SYNOPSIS

    $app->plugin('Markdown');
    
    # on brower the following url for example will be available.
    #
    # http://localhost:3000/markdown/
    # http://localhost:3000/markdown/path/to/doc.md

=head1 DESCRIPTION

This is a plugin for Markdown Viewer server.

=head1 INSTANCE METHODS

L<Marquee::Plugin::Markdown> inherits all instance methods from
L<Marquee::Plugin> and implements the following new ones.

=head2 register

Register the plugin.

    $self->register($app);

=head2 serve_index

Serves index of markdown files.

    $plugin->serve_index;

=head2 serve_markdown

Parse markdown for given path and generate HTML. 

    $plugin->serve_markdown('/path/to/markdown.md');

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

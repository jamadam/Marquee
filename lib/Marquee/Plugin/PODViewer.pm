package Marquee::Plugin::PODViewer;
use strict;
use warnings;
use Mojo::Asset::File;
use Mojo::ByteStream 'b';
use Mojo::DOM;
use Mojo::Util 'url_escape';
use Pod::Simple::HTML;
use Pod::Simple::Search;
use Mojo::DOM;
use Mojo::Util qw'url_unescape encode decode';
use Mojo::Base 'Marquee::Plugin';

__PACKAGE__->attr('paths');
__PACKAGE__->attr('no_see_also');

# "This is my first visit to the Galaxy of Terror and I'd like it to be a
#  pleasant one."
sub register {
    my ($self, $app, $conf) = @_;
    
    push(@{$app->roots}, __PACKAGE__->Marquee::asset());
    
    $self->paths([map { $_, "$_/pods" } @INC]);
    $self->no_see_also($conf->{no_see_also} || 0);
    
    if (! $conf->{no_route}) {
        $app->plugin('Router' => sub {
            shift->route(qr{^/perldoc/(.+)})->to(sub {
                $self->serve_pod_by_name(shift)
            });
        });
    }
}

sub serve_pod {
    my ($self, $source) = @_;
    
    my $c   = Marquee->c;
    my $app = $c->app;
    
    my $html = _pod_to_html($source);
    
    # Rewrite links
    my $dom = Mojo::DOM->new($html);
    $dom->find('a[href]')->each(sub {
        my $attrs = shift->attrs;
        if ($attrs->{href} =~ s{^http\://search\.cpan\.org/perldoc\?}{
                $app->ssi_handlers->{ep}->url_for('/perldoc/')
            }e) {
            $attrs->{href} =~ s!%3A%3A!/!gi;
        }
    });

    # Rewrite code blocks for syntax highlighting
    $dom->find('pre')->each(sub {
        my $e = shift;
        return if $e->all_text =~ /^\s*\$\s+/m;
        my $attrs = $e->attrs;
        my $class = $attrs->{class};
        $attrs->{class} = defined $class ? "$class prettyprint" : 'prettyprint';
    });
    
    # Rewrite headers
    my @parts;
    $dom->find('h1, h2, h3')->each(sub {
        my $e = shift;
        my $anchor = my $text = $e->all_text;
        $anchor =~ s/\s+/_/g;
        $anchor = url_escape $anchor, '^A-Za-z0-9_';
        $anchor =~ s/\%//g;
        push @parts, [] if $e->type eq 'h1' || !@parts;
        push @{$parts[-1]}, $text, "#$anchor";
        $e->replace_content(qq{<a name="$anchor">$text</a>});
    });
    
    # Try to find a title
    my $title = 'Perldoc';
    $dom->find('h1 + p')->first(sub {
        $title = shift->text
    });
    
    Marquee->c->stash->set(
        title       => $title,
        parts       => \@parts,
        static_dir  => 'static',
        perldoc     => "$dom",
        see_also    => ! $self->no_see_also
            ? _detect_see_also(($title =~ qr{(^[a-zA-Z0-9:]+)})[0])
            : undef,
    );
    
    $c->res->body(
        encode('UTF-8',
            $app->ssi_handlers->{ep}->render_traceable(
                __PACKAGE__->Marquee::asset('perldoc.html.ep')
            )
        )
    );
    $c->res->code(200);
    $c->res->headers->content_type($app->types->type('html'));
}

sub serve_pod_by_name {
    my ($self, $module) = @_;
    
    $module =~ s!/!\:\:!g;
    
    my $c       = Marquee->c;
    my $app     = $c->app;
    my $path    = Pod::Simple::Search->new->find($module, @{$self->paths});
    
    if (! $path || ! -r $path) {
        return $app->serve_redirect("http://metacpan.org/module/$module");
    }
    
    open my $file, '<', $path;
    return $self->serve_pod(join '', <$file>);
}

sub _detect_see_also {
    my $module = shift;
    
    my $search = Pod::Simple::Search->new;
    my @relatives;
    
    if (my $parent = ($module =~ qr{(.+)::\w+$})[0]) {
        my $b = $search->limit_glob($parent)->survey;
        push(@relatives, keys %$b);
    }
    
    my $a = $search->limit_glob($module. '::*')->survey;
    push(@relatives, grep {$_ =~ qr{$module\::\w+$}} keys %$a);
    
    return \@relatives;
}

sub _pod_to_html {
    return unless defined(my $pod = shift);
  
    # Parser
    my $parser = Pod::Simple::HTML->new;
    $parser->force_title('');
    $parser->html_header_before_title('');
    $parser->html_header_after_title('');
    $parser->html_footer('');
  
    # Parse
    $parser->output_string(\(my $output));
    return $@ unless eval { $parser->parse_string_document($pod); 1 };
  
    # Filter
    $output =~ s!<a name='___top' class='dummyTopAnchor'\s*?></a>\n!!g;
    $output =~ s!<a class='u'.*?name=".*?"\s*>(.*?)</a>!$1!sg;
  
    return $output;
}

1;

=head1 NAME

Marquee::Plugin::PODRenderer - POD renderer plugin

=head1 SYNOPSIS

    $app->plugin('PODViewer');
    
    # on brower the following url for example will be available.
    #
    # http://localhost:3000/perldoc/LWP

=head1 DESCRIPTION

This is a plugin for POD Viewer server.

=head1 ATTRIBUTES

=head2 no_see_also

Disables auto detection of relative modules.

=head2 paths

A path to discover modules.

=head1 METHODS

=head2 $instance->register($app)

=head2 $instance->serve_pod($html)

=head2 $instance->serve_pod_by_name($module_name)

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

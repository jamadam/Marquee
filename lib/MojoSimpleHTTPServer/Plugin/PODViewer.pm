package MojoSimpleHTTPServer::Plugin::PODViewer;
use Mojo::Asset::File;
use Mojo::ByteStream 'b';
use Mojo::DOM;
use Mojo::Util 'url_escape';
use Pod::Simple::HTML;
use Pod::Simple::Search;
use Mojo::DOM;
use Mojo::Util qw'url_unescape encode decode';
use Mojo::Base 'MojoSimpleHTTPServer::Plugin';
    
    # "This is my first visit to the Galaxy of Terror and I'd like it to be a
    #  pleasant one."
    sub register {
        my ($self, $app, $conf) = @_;
        
        push(@{$app->roots}, __PACKAGE__->MojoSimpleHTTPServer::asset());
        
        my @PATHS = map { $_, "$_/pods" } @INC;
        
        $app->plugin('Router' => sub {
            shift->route(qr{^/perldoc/(.+)})->to(sub {
                my $module = shift;
                
                $module =~ s!/!\:\:!g;
                
                my $context = $MSHS::CONTEXT;
                my $tx      = $context->tx;
                my $app     = $context->app;
                my $path    = Pod::Simple::Search->new->find($module, @PATHS);
                
                if (! $path || ! -r $path) {
                    return $app->serve_redirect("http://metacpan.org/module/$module");
                }
                
                open my $file, '<', $path;
                my $html = _pod_to_html(join '', <$file>);
                
                # Rewrite links
                my $dom = Mojo::DOM->new("$html");
                $dom->find('a[href]')->each(sub {
                    my $attrs = shift->attrs;
                    if ($attrs->{href}
                        =~ s!^http\://search\.cpan\.org/perldoc\?!/perldoc/!) {
                        $attrs->{href} =~ s!%3A%3A!/!gi;
                    }
                });
            
                # Rewrite code blocks for syntax highlighting
                $dom->find('pre')->each(sub {
                    my $e = shift;
                    return if $e->all_text =~ /^\s*\$\s+/m;
                    my $attrs = $e->attrs;
                    my $class = $attrs->{class};
                    $attrs->{class}
                      = defined $class ? "$class prettyprint" : 'prettyprint';
                });
                
                # Rewrite headers
                my $url = $tx->req->url->clone;
                my @parts;
                $dom->find('h1, h2, h3')->each(sub {
                    my $e = shift;
                    my $anchor = my $text = $e->all_text;
                    $anchor =~ s/\s+/_/g;
                    $anchor = url_escape $anchor, '^A-Za-z0-9_';
                    $anchor =~ s/\%//g;
                    push @parts, [] if $e->type eq 'h1' || !@parts;
                    push @{$parts[-1]}, $text, $url->fragment($anchor)->to_abs;
                    $e->replace_content(
                        sprintf(qq{<a href="%s" id="%s" class="mojoscroll">%s</a>}, $url->fragment('toc')->to_abs, $anchor, $text)
                    );
                });
                
                # Try to find a title
                my $title = 'Perldoc';
                $dom->find('h1 + p')->first(sub {
                    $title = shift->text
                });
                
                $MSHS::CONTEXT->stash->set(
                    title       => $title,
                    parts       => \@parts,
                    static_dir  => 'static',
                    perldoc     => "$dom",
                    see_also    => _detect_see_also($module),
                );
                
                $tx->res->body(
                    encode('UTF-8',
                        MojoSimpleHTTPServer::SSIHandler::EP->new->render_traceable(
                            __PACKAGE__->MojoSimpleHTTPServer::asset('perldoc.html.ep')
                        )
                    )
                );
                $tx->res->code(200);
                $tx->res->headers->content_type($MSHS::CONTEXT->app->types->type('html'));
            });
        });
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
      
        # Block
        $pod = $pod->() if ref $pod eq 'CODE';
      
        # Parser
        my $parser = Pod::Simple::HTML->new;
        $parser->force_title('');
        $parser->html_header_before_title('');
        $parser->html_header_after_title('');
        $parser->html_footer('');
      
        # Parse
        $parser->output_string(\(my $output));
        return $@ unless eval { $parser->parse_string_document("$pod"); 1 };
      
        # Filter
        $output =~ s!<a name='___top' class='dummyTopAnchor'\s*?></a>\n!!g;
        $output =~ s!<a class='u'.*?name=".*?"\s*>(.*?)</a>!$1!sg;
      
        return $output;
    }

1;

=head1 NAME

MojoSimpleHTTPServer::Plugin::PODRenderer - POD renderer plugin

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 SEE ALSO

L<MojoSimpleHTTPServer>, L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

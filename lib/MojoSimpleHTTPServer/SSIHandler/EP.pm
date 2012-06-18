package MojoSimpleHTTPServer::SSIHandler::EP;
use strict;
use warnings;
use Mojo::Base 'MojoSimpleHTTPServer::SSIHandler::EPL';
use File::Basename 'dirname';
use Mojo::ByteStream;
use Mojo::Template;
use Carp;
    
    ### --
    ### Function definitions for inside template
    ### --
    __PACKAGE__->attr(funcs => sub {{}});
    
    ### --
    ### Check if the name exists as a subroutine
    ### --
    sub _func_exists {
        if ($_[0] =~ /\W/) {
            croak "Function name must be consitsts of [a-bA-B0-9]";
        }
        no warnings;
        my $package = __PACKAGE__. "::_SandBox";
        eval "{package $package; $_[0]()}";
        if ($@ !~ /Undefined subroutine/) {
            return 1;
        }
        no strict 'refs';
        %{$package.'::'} = ();
        return;
    };
    
    ### --
    ### Add function
    ### --
    sub add_function {
        my ($self, $name, $cb) = @_;
        
        if ($name =~ /\W/) {
            croak "Function name must be consitsts of [a-bA-B0-9]";
        }
        if (_func_exists($name)) {
            croak qq{Can't modify built-in function $name};
        }
        
        $self->funcs->{$name} = $cb;
        return $self;
    }
    
    ### --
    ### ep handler
    ### --
    sub render {
        my ($self, $path) = @_;
        
        my $context = $MSHS::CONTEXT;
        
        my $mt = $self->cache($path);
        
        if (! $mt) {
            $mt = Mojo::Template->new();
            $mt->auto_escape(1);
            
            # Be a bit more relaxed for helpers
            my $prepend = q/no strict 'refs'; no warnings 'redefine';/;
    
            # Helpers
            $prepend .= 'my $_H = shift; my $_F = $_H->funcs;';
            for my $name (sort keys %{$self->funcs}) {
                if ($name =~ /^\w+$/) {
                    $prepend .=
                    "sub $name; *$name = sub {\$_F->{$name}->(\$_H, \@_)};";
                }
            }
            
            $prepend .= 'use strict;';
            for my $var (keys %{$context->stash}) {
                if ($var =~ /^\w+$/) {
                    $prepend .= " my \$$var = stash '$var';";
                }
            }
            $mt->prepend($prepend);
            
            $self->cache($path, $mt, sub {$_[0] < (stat($path))[9]});
        }
        
        my $output;
        
        if ($mt->compiled) {
            $output = $mt->interpret($self, $context);
        } else {
            $output = $mt->render_file($path, $self, $context);
        }
        
        return ref $output ? die $output : $output;
    }
    
    ### --
    ### load preset
    ### --
    sub init {
        my ($self) = @_;
        
        $self->funcs->{app} = sub {
            shift;
            return $MSHS::CONTEXT->app;
        };
        
        $self->funcs->{param} = sub {
            shift;
            return $MSHS::CONTEXT->tx->req->param($_[0]);
        };
        
        $self->funcs->{stash} = sub {
            shift;
            my $stash = $MSHS::CONTEXT->stash;
            if ($_[0] && $_[1]) {
                return $stash->set(@_);
            } elsif (! $_[0]) {
                return $stash;
            } else {
                return $stash->{$_[0]};
            }
        };
        
        $self->funcs->{current_template} = sub {
            return shift->current_template(@_);
        };
        
        $self->funcs->{dumper} = sub {
            shift;
            return Data::Dumper->new([@_])->Indent(1)->Terse(1)->Dump;
        };
        
        $self->funcs->{to_abs} = sub {
            return shift->_to_abs(@_);
        };
        
        $self->funcs->{include} = sub {
            my ($self, $path, @args) = @_;
            
            my $c = $MSHS::CONTEXT;
            local $c->{stash} = $c->{stash}->clone;
            $c->{stash}->set(@args);
            return
                Mojo::ByteStream->new($c->app->render_ssi($self->_to_abs($path)));
        };
        
        $self->funcs->{iter} = sub {
            my $self    = shift;
            my $block   = pop;
            
            my $ret = '';
            
            if (! ref $_[0]) {
                my $idx = 0;
                for my $elem (@_) {
                    $ret .= $block->($elem, $idx++);
                }
            } elsif (ref $_[0] eq 'ARRAY') {
                my $idx = 0;
                for my $elem (@{$_[0]}) {
                    $ret .= $block->($elem, $idx++);
                }
            } elsif (ref $_[0] eq 'HASH') {
                for my $key (keys %{$_[0]}) {
                    $ret .= $block->($key, $_[0]->{$key});
                }
            }
            
            return Mojo::ByteStream->new($ret);
        };
        
        $self->funcs->{override} = sub {
            my ($self, $name, $value) = @_;
            my $path = $self->current_template;
            $MSHS::CONTEXT->stash->set(_ph_name($name) => sub {
                return $self->render_traceable($path, $value);
            });
            return;
        };
        
        $self->funcs->{placeholder} = sub {
            my ($self, $name, $defalut) = @_;
            my $block = $MSHS::CONTEXT->stash->{_ph_name($name)} || $defalut;
            return $block->() || '';
        };
        
        $self->funcs->{extends} = sub {
            my ($self, $path, $block) = @_;
            
            my $c = $MSHS::CONTEXT;
            
            local $c->{stash} = $c->{stash}->clone;
            
            $block->();
            
            return
                Mojo::ByteStream->new($c->app->render_ssi($self->_to_abs($path)));
        };
        
        return $self;
    }
    
    ### --
    ### Generate safe name for placeholder
    ### --
    sub _ph_name {
        return "MSHS.SSIHandler.EP.". shift;
    }
    
    ### --
    ### abs
    ### --
    sub _to_abs {
        my ($self, $path) = @_;
        
        if ($path =~ qr{^/(.+)}) {
            return File::Spec->catfile($MSHS::CONTEXT->app->document_root, $1);
        }
        
        return dirname($self->current_template). '/'. $path;
    }

1;

__END__

=head1 NAME

MojoSimpleHTTPServer::SSIHandler::EP - EP template handler

=head1 SYNOPSIS

    my $ep = MojoSimpleHTTPServer::SSIHandler::EP->new;
    $ep->render('/path/to/template.html.ep');

=head1 DESCRIPTION

EP handler. EP is a EPL.

=head1 ATTRIBUTES

L<MojoSimpleHTTPServer::SSIHandler::EP> inherits all attributes from
L<MojoSimpleHTTPServer::SSIHandler::EPL> and implements the following new ones.

=head2 funcs

A Hash ref that contains template functions.

    $ep->funcs->{some_func} = sub {...};

You can use C<add_function> method to add a function entry instead of the code
above.

=head1 FUNCTIONS

=head2 current_template()

Returns current template path.

    <% my $path = current_template(); %>

=head2 extends($path, $block)

Base template.

    <!doctype html>
    <html>
        <head>
            <title><%= placeholder 'title' => begin %>DEFAULT TITLE<% end %></title>
        </head>
        <body>
            <div id="main">
                <%= placeholder 'main' => begin %>
                    DEFAULT MAIN
                <% end %>
            </div>
            <div id="main2">
                <%= placeholder 'main2' => begin %>
                    DEFAULT MAIN2
                <% end %>
            </div>
        </body>
    </html>

Extended template.

    <%= extends './layout/common.html.ep' => begin %>
        <% override 'title' => begin %>
            title
        <% end %>
        <% override 'main' => begin %>
            <div>
                main content<%= time %>
            </div>
        <% end %>
    <% end %>

Extends template.

=head2 iter @array => $block

Array iterator with block.

    <%= iter @array => begin %>
        <% my $elem = shift; %>
        <%= $elem %>
    <% end %>

=head2 include('./path/to/template.html.ep', key => value)

Include a template into current template. The path can be relative to
current template directory or relative to document root if leading slashed.

    <%= include('./path/to/template.html.ep', key => value) %>

=head2 override($name, $block)

Override placeholder. See C<extends> method.

=head2 param('key')

Returns request parameters for given key.

    <% param('key') %>

=head2 placeholder($name, $default_block)

Set placeholder with default block. See C<extends> method.

=head2 stash('key')

Returns stash value for given key.

    <% stash('key') %>

=head2 to_abs()

Generate absolute path with given relative one

    <% to_abs('./path.css') %>

=head1 METHODS

L<MojoSimpleHTTPServer::SSIHandler::EP> inherits all methods from
L<MojoSimpleHTTPServer::SSIHandler::EPL> and implements the following new ones.

=head2 $instance->init

This method automatically called by constructor.

    $ep->init;

=head2 $instance->new

Constructor.

    my $ep = MojoSimpleHTTPServer::SSIHandler::EP->new;

=head2 $instance->add_function(name => sub {...})

    $ep->add_function(html_to_text => sub {
        my ($ep, $html) = @_;
        return Mojo::DOM->new($html)->all_text;
    });

in tempaltes...

    <%= html_to_text($html) %>

=head2 $instance->render($path)

Renders given template and returns the result. If rendering fails, die with
Mojo::Exception.

    $ep->render('/path/to/template.html.ep');

=head1 SEE ALSO

L<MojoSimpleHTTPServer::SSIHandler>, L<MojoSimpleHTTPServer>, L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

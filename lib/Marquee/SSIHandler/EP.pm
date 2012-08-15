package Marquee::SSIHandler::EP;
use strict;
use warnings;
use Mojo::Base 'Marquee::SSIHandler::EPL';
use File::Basename 'dirname';
use Mojo::ByteStream;
use Mojo::Template;
use Mojo::Path;
use Carp;

### --
### Function definitions for inside template
### --
__PACKAGE__->attr(funcs => sub {{}});

### --
### Constructor
### --
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->_init;
    return $self;
}

### --
### Add function
### --
sub add_function {
    my ($self, $name, $cb) = @_;
    
    if ($name =~ /\W/) {
        croak "Function name must be consitsts of [a-bA-B0-9]";
    }
    if ($] >= 5.016 && defined(&{"CORE::". $name})) {
        croak qq{Can't modify built-in function $name};
    }
    if ($self->funcs->{$name}) {
        $self->log->warn("Function $name will be redefined");
    }
    $self->funcs->{$name} = $cb;
    return $self;
}

### --
### ep handler
### --
sub render {
    my ($self, $path) = @_;
    
    my $c = Marquee->c;
    
    my $mt = $self->cache($path);
    
    if (! $mt) {
        $mt = Mojo::Template->new();
        $mt->auto_escape(1);
        
        # Be a bit more relaxed for helpers
        my $prepend = q/no strict 'refs'; no warnings 'redefine';/;

        # Helpers
        $prepend .= 'my $_H = shift; my $_F = $_H->funcs;';
        for my $name (keys %{$self->funcs}) {
            $prepend .= "sub $name; *$name = sub {\$_F->{$name}->(\$_H, \@_)};";
        }
        
        $prepend .= 'use strict;';
        for my $var (keys %{$c->stash}) {
            if ($var =~ /^\w+$/) {
                $prepend .= " my \$$var = stash '$var';";
            }
        }
        $mt->prepend($prepend);
        
        $self->cache($path, $mt, sub {$_[0] < (stat($path))[9]});
    }
    
    my $output;
    
    if ($mt->compiled) {
        $output = $mt->interpret($self, $c);
    } else {
        $output = $mt->render_file($path, $self, $c);
    }
    
    return ref $output ? die $output : $output;
}

### --
### load preset
### --
sub _init {
    my $self = shift;
    
    $self->funcs->{app} = sub {
        shift;
        return Marquee->c->app;
    };
    
    $self->funcs->{param} = sub {
        shift;
        return Marquee->c->req->param($_[0]);
    };
    
    $self->funcs->{stash} = sub {
        shift;
        my $stash = Marquee->c->stash;
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
        
        my $abs_path = $self->_to_abs($path);
        my $c = Marquee->c;
        
        if (my $abs_path = $c->app->search_static($abs_path)) {
            return Mojo::ByteStream->new(
                Encode::decode_utf8(
                    Mojo::Asset::File->new(path => $abs_path)->slurp));
        }
        
        if (my $abs_path = $c->app->search_template($abs_path)) {
            local $c->{stash} = $c->{stash}->clone;
            $c->{stash}->set(@args);
            return Mojo::ByteStream->new($c->app->render_ssi($abs_path));
        }
        
        die "$abs_path not found";
    };
    
    $self->funcs->{include_as} = sub {
        my ($self, $path, $handler, @args) = @_;
        
        my $abs_path = $self->_to_abs($path);
        my $c = Marquee->c;
        
        if (my $abs_path = $c->app->search_static($abs_path)
                                    || $c->app->search_template($abs_path)) {
            local $c->{stash} = $c->{stash}->clone;
            $c->{stash}->set(@args);
            return Mojo::ByteStream->new($c->app->render_ssi($abs_path, $handler));
        }
        
        die "$abs_path not found";
    };
    
    $self->funcs->{iter} = sub {
        my $self    = shift;
        my $block   = pop;
        
        my $ret = '';
        
        if (ref $_[0] eq 'ARRAY') {
            my $idx = 0;
            for my $elem (@{$_[0]}) {
                $ret .= $block->($elem, $idx++);
            }
        } elsif (ref $_[0] eq 'HASH') {
            for my $key (keys %{$_[0]}) {
                $ret .= $block->($key, $_[0]->{$key});
            }
        } else {
            my $idx = 0;
            for my $elem (@_) {
                $ret .= $block->($elem, $idx++);
            }
        }
        
        return Mojo::ByteStream->new($ret);
    };
    
    $self->funcs->{override} = sub {
        my ($self, $name, $value) = @_;
        my $path = $self->current_template;
        Marquee->c->stash->set(_ph_name($name) => sub {
            return $self->render_traceable($path, $value);
        });
        return;
    };
    
    $self->funcs->{url_for} = sub {
        return shift->url_for(@_);
    };
    
    $self->funcs->{placeholder} = sub {
        my ($self, $name, $defalut) = @_;
        my $block = Marquee->c->stash->{_ph_name($name)} || $defalut;
        return $block->() || '';
    };
    
    $self->funcs->{extends} = sub {
        my ($self, $path, $block) = @_;
        
        my $c = Marquee->c;
        
        local $c->{stash} = $c->{stash}->clone;
        
        $block->();
        
        return
            Mojo::ByteStream->new($c->app->render_ssi($self->_to_abs($path. '.ep')));
    };
    
    return $self;
}

### --
### Generate portable URL
### --
sub url_for {
    my ($self, $path) = @_;
    $path =~ s{^\.*/}{};
    my $abs = Mojo::Path->new($ENV{'MARQUEE_BASE_PATH'});
    $abs->trailing_slash(1);
    $abs->merge($path);
    $abs->leading_slash(1);
    return $abs;
}

### --
### Generate safe name for placeholder
### --
sub _ph_name {
    return "mrqe.SSIHandler.EP.". shift;
}

### --
### abs
### --
sub _to_abs {
    my ($self, $path) = @_;
    
    (my $root, $path) =
        ($path =~ qr{^/(.+)})
            ? (Marquee->c->app->document_root, $1)
            : (dirname($self->current_template), $path);
    
    return File::Spec->canonpath(File::Spec->catfile($root, $path));
}

1;

__END__

=head1 NAME

Marquee::SSIHandler::EP - EP template handler

=head1 SYNOPSIS

    my $ep = Marquee::SSIHandler::EP->new;
    $ep->render('/path/to/template.html.ep');

=head1 DESCRIPTION

L<Marquee::SSIHandler::EP> is a EP handler.

=head1 ATTRIBUTES

L<Marquee::SSIHandler::EP> inherits all attributes from
L<Marquee::SSIHandler::EPL> and implements the following new ones.

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

C<extends> function cooperates with C<placeholder> and C<override>,
provides template inheritance mechanism.

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

Extends the template.

    <%= extends './layout/common.html' => begin %>
        <% override 'title' => begin %>
            title
        <% end %>
        <% override 'main' => begin %>
            <div>
                main content<%= time %>
            </div>
        <% end %>
    <% end %>

=head2 iter @array => $block

Array iterator with a block.

    <%= iter @array => begin %>
        <% my ($elem, $index) = @_; %>
        No.<%= $index %> is <%= $elem %>
    <% end %>

Array refs and Hash refs are also accepted.

    <%= iter $array_ref => begin %>
        <% my ($elem, $index) = @_; %>
        No.<%= $index %> is <%= $elem %>
    <% end %>

    <%= iter $hash_ref => begin %>
        <% my ($key, $value) = @_; %>
        <%= $key %> is <%= $value %>
    <% end %>

=head2 include('./path/to/template.html', key => value)

Include a template or a static files into current template. The path can be
relative to current template directory or relative to document root if leading
slashed. 

    <%= include('./path/to/template.html', key => value) %>
    <%= include('/path/to/template.html', key => value) %>

=head2 include_as('./path/to/template.html', $handler_ext, key => value)

[EXPERIMENTAL] Include a template into current template. This function is
similar to include but you can specify the handler the template would be parsed
with.

    <%= include_as('./path/to/template.html', 'ep', key => value) %>

=head2 override($name, $block)

Override placeholder. See C<extends> method.

=head2 param('key')

Returns request parameters for given key.

    <%= param('key') %>

=head2 placeholder($name, $default_block)

Set placeholder with default block. See C<extends> method.

=head2 stash('key')

Returns stash value for given key.

    <%= stash('key') %>

=head2 to_abs()

Generate absolute path with given relative one

    <%= to_abs('./path.css') %>

=head2 url_for('path/to/file')

Generate a portable URL.

    <%= url_for('./path.css') %>

=head1 METHODS

L<Marquee::SSIHandler::EP> inherits all methods from
L<Marquee::SSIHandler::EPL> and implements the following new ones.

=head2 $instance->new

Constructor.

    my $ep = Marquee::SSIHandler::EP->new;

=head2 $instance->add_function(name => sub {...})

Adds a function to the renderer.

    $ep->add_function(html_to_text => sub {
        my ($ep, $html) = @_;
        return Mojo::DOM->new($html)->all_text;
    });

in templates...

    <%= html_to_text($html) %>

=head2 $instance->render($path)

Renders given template and returns the result. If rendering fails, die with
L<Mojo::Exception>.

    $ep->render('/path/to/template.html.ep');

=head1 SEE ALSO

L<Marquee::SSIHandler>, L<Marquee>, L<Mojolicious>

=cut

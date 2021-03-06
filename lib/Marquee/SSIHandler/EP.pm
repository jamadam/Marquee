package Marquee::SSIHandler::EP;
use strict;
use warnings;
use Mojo::Base 'Marquee::SSIHandler::EPL';
use feature 'signatures';
no warnings "experimental::signatures";
use File::Basename 'dirname';
use Mojo::ByteStream 'b';
use Mojo::Template;
use Mojo::Path;
use Mojo::Util 'deprecated';
use Encode 'decode_utf8';
use Carp;
use Data::Dumper;

### --
### Function definitions for inside template
### --
has funcs => sub {{}};

### --
### Constructor
### --
sub new($class, @args) {
    my $self = $class->SUPER::new(@args);
    $self->_init;
    return $self;
}

### --
### Add function
### --
sub add_function($self, $name, $cb) {
    
    if ($name =~ /\W/) {
        croak "Function name must be consitsts of [a-zA-Z0-9]";
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
sub render($self, $path) {
    
    my $c = Marquee->c;
    
    my $mt = $self->get_cache($path);
    
    if (! $mt) {
        $mt = Mojo::Template->new();
        $mt->auto_escape(1);
        
        # Be a bit more relaxed for helpers
        my $prepend = q/no strict 'refs'; no warnings 'redefine';/;
        
        # document write backend API
        $prepend .= q!sub _DW; local *_DW = sub {$_O .= _escape(shift); ''};!;
        
        # Helpers
        $prepend .= 'my $_H = shift; my $_F = $_H->funcs;';
        for (keys %{$self->funcs}) {
            $prepend .= "sub $_; local *$_ = sub {\$_F->{$_}->(\$_H, \@_)};";
        }
        
        $prepend .= 'use strict;';
        for my $var (keys %{$c->stash}) {
            $prepend .= " my \$$var = stash '$var';" if ($var =~ /^\w+$/);
        }
        $mt->prepend($prepend);
        
        $self->set_cache($path, $mt, sub($ts) {$ts < (stat($path))[9]});
    }
    
    my $output = $mt->compiled
            ? $mt->process($self, $c) : $mt->render_file($path, $self, $c);
    
    return ref $output ? die $output : $output;
}

### --
### load preset
### --
sub _init($self) {
    
    $self->funcs->{b} = sub($self, @bytes) {
        Mojo::ByteStream->new(@bytes);
    };
    
    $self->funcs->{docwrite} = sub($self, $string) {
        return Mojo::Template::SandBox::_DW($string);
    };
    
    $self->funcs->{app} = sub($self) {
        return Marquee->c->app;
    };
    
    $self->funcs->{param} = sub($self, $k) {
        return Marquee->c->req->param($k);
    };
    
    $self->funcs->{session} = sub($self, $k=undef, $v=undef) {
        my $sesison = Marquee->c->session;
        return $sesison->{$k} = $v if ($k && $v);
        return $sesison if (! $k);
        return $sesison->{$k};
    };
    
    $self->funcs->{stash} = sub($self, $k=undef, $v=undef) {
        my $stash = Marquee->c->stash;
        return $stash->set($k, $v) if ($k && $v);
        return $stash if (! $k);
        return $stash->{$k};
    };
    
    $self->funcs->{current_template} = sub($self, $index=0) {
        return $self->current_template($index);
    };
    
    $self->funcs->{dumper} = sub($self, @data) {
        return Data::Dumper->new([@data])->Indent(1)->Terse(1)->Dump;
    };
    
    $self->funcs->{to_abs} = sub($self, $path) {
        return $self->_to_abs($path);
    };
    
    $self->funcs->{include} = sub($self, $path, $bind=undef, @bind) {
        if (@bind) {
            deprecated 'Array for include is DEPRECATED. Pass an hash reference instead';
            $bind = {$bind, @bind};
        }
        
        $path = $self->_doc_path($path);
        my $c = Marquee->c;
        my $app = $c->app;
        
        if (my $path = $app->static->search($path)) {
            return b(decode_utf8(Mojo::Asset::File->new(path => $path)->slurp));
        }
        
        if (my $path = $app->dynamic->search($path)) {
            local $c->{stash} = $c->{stash}->clone;
            $c->{stash}->set(%$bind);
            return b($app->dynamic->render($path));
        }
        
        die "$path not found";
    };
    
    $self->funcs->{include_as} = sub($self, $path, $handler, $bind=undef, @bind) {
        if (@bind) {
            deprecated 'Array for include_as is DEPRECATED. Pass an has reference instead';
            $bind = [$bind, @bind];
        }
        
        $path = $self->_doc_path($path);
        my $c = Marquee->c;
        my $app = $c->app;
        
        if (my $path = $app->static->search($path)) {
            local $c->{stash} = $c->{stash}->clone;
            $c->{stash}->set(%$bind);
            return b($app->dynamic->render($path, $handler));
        }
        
        die "$path not found";
    };
    
    $self->funcs->{iter} = sub {
        my $self    = shift;
        my $block   = pop;
        my $ref = $_[0];
        if (@_ > 1) {
            deprecated 'Array for iter is DEPRECATED. Pass an Array reference instead';
            $ref = [@_];
        }
        
        my $ret = '';
        
        if (ref $ref eq 'ARRAY') {
            my $idx = 0;
            for my $elem (@$ref) {
                $ret .= $block->($elem, $idx++);
            }
        } elsif (ref $ref eq 'HASH') {
            for my $key (keys %$ref) {
                $ret .= $block->($key, $ref->{$key});
            }
        }
        
        return b($ret);
    };
    
    $self->funcs->{override} = sub($self, $name, $value) {
        my $path = $self->current_template;
        Marquee->c->stash->set(_ph_name($name) => sub() {
            $self->traceable($path, $value)
        });
        return;
    };
    
    $self->funcs->{url_for} = sub($self, @args) {
        return shift->url_for(@args);
    };
    
    $self->funcs->{placeholder} = sub($self, $name, $defalut) {
        my $block = Marquee->c->stash->{_ph_name($name)} || $defalut;
        return $block->() || '';
    };
    
    $self->funcs->{extends} = sub($self, $path, $block) {
        
        $path = $self->_doc_path($path);
        my $c = Marquee->c;
        my $app = $c->app;
        
        local $c->{stash} = $c->{stash}->clone;
        
        $block->();
        
        if (my $path = $app->dynamic->search($path)) {
            return b($app->dynamic->render($path, 'ep'));
        }
        
        die "$path not found";
    };
    
    $self->funcs->{extends_as} = sub($self, $path, $handler, $block) {

        $path = $self->_doc_path($path);
        my $c = Marquee->c;
        my $app = $c->app;
        
        local $c->{stash} = $c->{stash}->clone;
        
        $block->();
        
        if (my $path = $app->static->search($path)) {
            return b($app->dynamic->render($path, $handler));
        }
        
        die "$path not found";
    };
    
    return $self;
}

### --
### Generate portable URL
### --
sub url_for {
    my ($self, $path) = @_;
    
    # base path for CGI environment
    if ($ENV{DOCUMENT_ROOT} && ! defined $ENV{MARQUEE_BASE_PATH}) {
        my $tmp = Marquee->c->app->home->to_string;
        if ($tmp =~ s{^\Q$ENV{DOCUMENT_ROOT}\E}{}) {
            $ENV{MARQUEE_BASE_PATH} = $tmp;
        }
    }
    
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
### generate file path relative to document root
### --
sub _doc_path {
    my ($self, $path) = @_;
    
    return File::Spec->canonpath($1) if ($path =~ qr{^/(.+)});
    
    $path = File::Spec->catfile(dirname($self->current_template), $path);
    $path = File::Spec->canonpath($path);
    for my $root (@{Marquee->c->app->roots}) {
        last if ($path =~ s{^\Q$root\E/}{});
    }
    
    return $path;
}

### --
### abs
### --
sub _to_abs($self, $path) {
    
    (my $root, $path) = ($path =~ qr{^/(.+)})
                                ? (Marquee->c->app->home, $1)
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

=head2 C<funcs>

A Hash ref that contains template functions.

    $ep->funcs->{some_func} = sub(...) {...};

You can use L</add_function> method to add a function entry instead of the code
above.

=head1 FUNCTIONS

Following template functions are automatically available.

=head2 C<b>

shortcut for Mojo::ByteStream constructor. Mojo::ByteStream objects are
always excluded from automatic escaping.

    <%= b('<div></div>') %>

=head2 C<current_template>

Returns current template path.

    <% my $path = current_template(); %>

=head2 C<docwrite>

Append document content immidiately within any template syntax. The return value
is always XML escaped unless when the input is Mojo::ByteStream object.

    <%
        if ($yes) {
            docwrite('yes');
        } else {
            docwrite('nop');
        }
        docwrite(' is the answer!');
    %>
    
The above is paraphrase of below.

    % if ($yes) {
        yes
    % } else {
        nop
    % }
    is the answer!

=head2 C<extends>

L</extends> function cooperates with L</placeholder> and L</override>,
provides template inheritance mechanism.

Base template named C<layout/common.html.ep>.

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

A template can extends C<common.html.ep> as follows. The path can be relative to
current template directory or relative to document root if leading slashed.
The handler is auto detected so you don't need to specify the extension.

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

=head2 C<extends_as>

L</extends_as> inherits a template and extends it.
This function is similar to L</extends> but you can specify the handler
the template would be parsed with.

Note that the C<template.html> MUST NOT be name as C<template.html.ep>

    <%= extends_as './path/to/template.html', 'ep' => begin %>
    ...
    <% end %>

=head2 C<iter>

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

=head2 C<include>

Include a template or a static files into current template. The path can be
relative to current template directory or relative to document root if leading
slashed. 

    <%= include('./path/to/template.html', {key => value}) %>
    <%= include('/path/to/template.html', {key => value}) %>

=head2 C<include_as>

Include a template into current template. This function is
similar to include but you can specify the handler the template would be parsed
with.

    <%= include_as('./path/to/template.html', 'ep', {key => value}) %>

=head2 C<override>

Override placeholder. See L</extends> method.

=head2 C<param>

Returns request parameters for given key.

    <%= param('key') %>

=head2 C<placeholder>

Set placeholder with default block. See L</extends> method.

=head2 C<session>

Sets or get a session value or get all data in hash.

    <%= session('key') %>
    <% session('key', 'value'); %>
    <% $hash = session(); %>

=head2 C<stash>

Returns stash value for given key.

    <%= stash('key') %>

=head2 C<to_abs>

Generates absolute path for server filesystem root with given relative one.
Leading dot-segment indicates current file and the leading slash indicates
Marquee root.

    <%= to_abs('/path.css') %> <!-- /path/to/Marquee/path.css -->

At C</path/to/Marquee/html/category/index.html>

    <%= to_abs('./path.css') %> <!-- /path/to/Marquee/html/category/path.css  -->

=head2 C<url_for>

Generates a portable URL relative to document root.

    <%= url_for('./b.css') %> # current is '/a/.html' then generates '/a/b.css'
    <%= url_for('/b.css') %>  # current is '/a/.html' then generates '/b.css'

=head1 CLASS METHODS

L<Marquee::SSIHandler::EP> inherits all class methods from
L<Marquee::SSIHandler::EPL> and implements the following new ones.

=head2 C<new>

Constructor.

    my $ep = Marquee::SSIHandler::EP->new;

=head1 INSTANCE METHODS

L<Marquee::SSIHandler::EP> inherits all instance methods from
L<Marquee::SSIHandler::EPL> and implements the following new ones.

=head2 C<add_function>

Adds a function to the renderer.

    $ep->add_function(html_to_text => sub($ep, $html) {
        return Mojo::DOM->new($html)->all_text;
    });

in templates...

    <%= html_to_text($html) %>

=head2 C<render>

Renders given template and returns the result. If rendering fails, die with
L<Mojo::Exception>.

    $ep->render('/path/to/template.html.ep');

=head2 C<url_for>

Generates a portable URL relative to document root.

    $ep->url_for('./path.css')

=head1 SEE ALSO

L<Marquee::SSIHandler>, L<Marquee>, L<Mojolicious>

=cut

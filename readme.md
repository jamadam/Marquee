Marquee beta
---------------

[Marquee] distribution is yet another web application framework built on Mojo
toolkit in [Mojolicious] distribution, designed to make dynamic website
development to be plotted at an extension of traditional designer work.

This may possibly be a reinvention of [Mason], [Markup::Perl], [HTML::Embperl]
or PHP.

### Default URL mapping

By default, [Marquee] automatically maps request paths to corresponding
file directory structure. This is similar to typical HTTP servers such as Apache
and this is the leading motivation of this project.
To keep the URI semantics corresponds to directory tree makes things simple.

Given the request path
    
    /news/sports/hockey.html

[Marquee] searches for the following templates or static files under
application root.

    /public_html/news/sports/hockey.html
    /public_html/news/sports/hockey.html.ep
    /public_html/news/sports/hockey.html.epl

The extensioning rule is same as [Mojolicious]. The second extension indecates
a handler for template rendering. ep and epl are always available
and you can also add your own handler easily.

You can also override the mapping rule with Route plugin bundled in core.

    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/path1\.html})->to(sub {
            ...
        });
        $r->route(qr{^/path2\.html})->to(sub {
            ...
        });
    });

### Perlish template

[Marquee] provedes [Mojo::Template] based template handler which allows templates
to be written in more Perl instead of template specific syntax,
therefore, it requires less lerning cost (by comparison to [Mason]).

Basic syntax.

    <% ...; %> <!-- execute Perl code -->
    <%= ... %> <!-- execute Perl code and output(with html escape) -->
    <%== ... %> <!-- execute Perl code and output(without html escape) -->
    % ...; # execute inline Perl code
    %= ...; # execute inline Perl code code and output(with html escape)
    %== ...; # execute inline Perl code code and output(without html escape)
    
Block syntax.

    <% my $block = begin %>
        Plain html here
        <%= ... %>
        Plain html here
    <% end %>

Here's a practical example.

    <ul>
        <%
            require './lib/NewsRelease.pm';
            my $news = NewsRelease->new();
            my @array = $news->fetch(5);
        %>
        <% for my $entry (@array) { %>
            <li>
                <a href="<%= $entry->{url} %>">
                    <%= $entry->{title} %>
                </a>
            </li>
        <% } %>
    </ul>

### Generating Content-Type automatically

[Marquee] restricts the name of templates as name.format.handler style so that
the system can auto detect Content-Type and implicitly serve the header.
This system is more resonable (by comparison to PHP).

    index.html.ep
    index.json.ep
    index.txt.epl

### Easy to install

[Marquee] is written in pure-perl and depends on only [Mojolicious] distribution
which is also a pure-perl, so you can even deploy them via FTP.
Though [Mojolicious] depends on perl-5.10.1 or higher, there is still an option
to adopt backport project [mojo-legacy] to run on perl-5.8.7.

### Mojo toolkit is available

Since [Marquee] is based on mojo, many mojo classes helps you on manipulating
such as HTTP requests, responses, DOM and JSON.

## INSTALLATION

To install this module, run the following commands:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

## Perl API

Here is a smallest Marquee application.

    use Marquee;
    
    my $app = Marquee->new;
    
    $app->start;

You also can separate the app into own class (shown below) and
boot script (similar to above).

    package MyApp;
    use Mojo::Base 'Marquee';
    
    sub new {
        my $self = shift->SUPER::new(@_);
        ...
        return $self;
    }

The application can be start in Mojo way.

    $ ./myapp daemon
    Server available at http://127.0.0.1:3000.

For productions use..
    
    $ hypnotoad ./myapp

For more information refer to API documentations.

- [Marquee](http://marquee.jamadam.com/perldoc/Marquee) (Marquee base class)
- [Marquee::SSIHandler::EP](http://marquee.jamadam.com/perldoc/Marquee/SSIHandler/EP) (Perlish template class)
- [Marquee::Guides::Cookbook](http://marquee.jamadam.com/perldoc/Marquee/Guides/Cookbook) (Cookbook)

## COMMAND LINE INTERFACE

In addition to Perl OOP API, Marquee also provides command line interface
to serve current directory contents as a web pages, using [Mojo::Daemon].
This is useful for temporarily providing web pages without any Apache things.

## SYNOPSIS

    mojo marquee [OPTIONS]

These options are available:
  
    -dr, --document_root <path>  Set document root path, defaults to current dir.
    -df, --default_file <name>   Set default file name and activate auto fill.
    -ai, --auto_index            Activate auto index, defaults to 0.
    -dv, --doc_viewer            Activate document viewer.
    -ud, --under_development     Activate debug screen for server-side include.
    -b, --backlog <size>         Set listen backlog size, defaults to
                                 SOMAXCONN.
    -c, --clients <number>       Set maximum number of concurrent clients,
                                 defaults to 1000.
    -g, --group <name>           Set group name for process.
    -i, --inactivity <seconds>   Set inactivity timeout, defaults to the value
                                 of MOJO_INACTIVITY_TIMEOUT or 15.
    -l, --listen <location>      Set one or more locations you want to listen
                                 on, defaults to the value of MOJO_LISTEN or
                                 "http://*:3000".
    -p, --proxy                  Activate reverse proxy support, defaults to
                                 the value of MOJO_REVERSE_PROXY.
    -r, --requests <number>      Set maximum number of requests per keep-alive
                                 connection, defaults to 25.
    -u, --user <name>            Set username for process.

### EXAMPLE1

    $ mojo marquee
    [Mon Oct 17 23:18:35 2011] [info] Server listening (http://*:3000)
    Server available at http://127.0.0.1:3000.

### EXAMPLE2(specify port number)

    $ mojo marquee --listen http://*:3001

### EXAMPLE3(specify document root)

    $ mojo marquee --document_root ./public

### EXAMPLE4(specify default file name)

    $ mojo marquee --default_file index.html

### EXAMPLE4(activate auto index & auto tree)

    $ mojo marquee --auto_index

![Site list](https://github.com/jamadam/Marquee/raw/master/screenshot/autoindex.png "Auto Index")

![Site list](https://github.com/jamadam/Marquee/raw/master/screenshot/autoindextree.png "Auto Index")

## REPOSITORY

[https://github.com/jamadam/Marquee]
[https://github.com/jamadam/Marquee]:https://github.com/jamadam/Marquee

## CREDIT

Icons by [Yusuke Kamiyamane].

## COPYRIGHT AND LICENSE

Copyright (c) 2012 [jamadam]

This program is free software; you can redistribute it and/or
modify it under the [same terms as Perl itself].

[Marquee]:http://marquee.jamadam.com/perldoc/Marquee
[Mojolicious]:http://mojolicio.us/
[Mason]:http://search.cpan.org/~jswartz/Mason-2.20/lib/Mason.pm
[mojo-legacy]:https://github.com/jamadam/mojo-legacy
[Mojo::Template]:http://search.cpan.org/~sri/Mojolicious-3.35/lib/Mojo/Template.pm
[Mojo::Daemon]:http://search.cpan.org/~sri/Mojolicious-3.35/lib/Mojo/Daemon.pm
[same terms as Perl itself]:http://dev.perl.org/licenses/
[Yusuke Kamiyamane]:http://p.yusukekamiyamane.com/
[jamadam]: http://blog2.jamadam.com/
[Markup::Perl]:http://search.cpan.org/~mmathews/Markup-Perl-0.5/lib/Markup/Perl.pm
[HTML::Embperl]:http://search.cpan.org/~grichter/HTML-Embperl-1.3.6/Embperl.pod

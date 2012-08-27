Marquee beta
---------------

## SYNOPSIS
    
    mojo Marquee [--document_root path] [--dafault_file name]
        [--auto_index] ..

## DESCRIPTION

Marquee distribution is yet another web application framework built on mojo
modules in Mojolicious distribution, designed to make dynamic content
development to be plotted at an extension of designer work.

### Default URL mapping

By default, Marquee automatically maps request paths to corresponding directory
tree as follows.

Given the request path
    
    /news/sports/hockey.html

Marquee searches for the following templates or static files.

    /news/sports/hockey.html
    /news/sports/hockey.html.ep
    /news/sports/hockey.html.epl

The hierarcky mapping is similar to typical HTTP servers such as Apache and
Mason a perl web framework. The extensioning rule is same as Mojolicious.

The second extension indecates a handler for template rendering.
ep and epl are always available and you can also add your own　handler easily.
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

Marquee provedes Mojo::Template based template handler which allows templates
to be written in more Perl and less special syntax, therefore, less lerning cost
(by comparison to Mason).

    <ul>
        <%
            require ./lib/NewsRelease.pm;
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

Marquee restricts the name of templates as name.format.handler style so that
the system can auto detect Content-Type and implicitly serve the header.
This system is more resonable (by comparison to PHP).

    index.html.ep
    index.json.ep
    index.txt.epl

### Easy to install

Marquee is written in pure-perl and depends on only Mojolicious distribution
which is also a pure-perl, so you can even deploy them with FTP clients.
Though Mojolicious depends on perl-5.10.1 or higher, there is still an option
to adopt backport project mojo-legacy to run on perl-5.8.7.

### Mojo toolkit is available

Since Marquee is based on mojo, many mojo classes helps you on manipulating
such as HTTP requests, responses, DOM and JSON.

## INSTALLATION

To install this module, run the following commands:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

## Perl API

Marquee class is based on Mojo. You can run your app in Mojo way

    use Marquee;
    
    my $app = Marquee->new;
    $app->document_root($path);
    $app->default_file('index.html');
    
    $app->plugin('AutoIndex');
    
    $app->start;

On command line..

    $ ./myapp daemon
    Server available at http://127.0.0.1:3000.

## COMMAND LINE API

In addition to Perl OOP framework, Marquee also provides command line API to
serve current directory contents as a web pages, using Mojo::Daemon.
This is useful for temporarily providing web pages without any Apache things.

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

![Site list](/jamadam/Marquee/raw/master/screenshot/autoindex.png "Auto Index")

![Site list](/jamadam/Marquee/raw/master/screenshot/autoindextree.png "Auto Index")

## REPOSITORY

[https://github.com/jamadam/Marquee]
[https://github.com/jamadam/Marquee]:https://github.com/jamadam/Marquee

## CREDIT

Icons by [Yusuke Kamiyamane].
[Yusuke Kamiyamane]:http://p.yusukekamiyamane.com/

## COPYRIGHT AND LICENSE

Copyright (c) 2012 [jamadam]
[jamadam]: http://blog2.jamadam.com/

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

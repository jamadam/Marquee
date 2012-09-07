Marquee
---------------

[Marquee] is yet another web application framework built on Mojo
toolkit in [Mojolicious] distribution, designed to make dynamic website
development to be plotted at an extension of traditional designer work.

This may possibly be a reinvention of [Mason], [Markup::Perl], [HTML::Embperl]
or PHP.

![Komodo Edit](http://mrqe.biz/screenshot/komodo.png "Komodo Edit")

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

You can also override the mapping rule with [Marquee::Router] plugin bundled
in core.

### Perlish template

[Marquee] provedes [Mojo::Template] based template handler which allows templates
to be written in more Perl instead of template specific syntax,
therefore, it requires less lerning cost (by comparison to [Mason]).

### Generating Content-Type automatically

[Marquee] restricts the name of templates as name.format.handler style so that
the system can auto detect Content-Type and implicitly serve the header.
This system is more resonable (by comparison to PHP).

### Easy to install

[Marquee] is written in pure-perl and depends on only [Mojolicious] distribution
which is also a pure-perl, so you can even deploy them via FTP.
Though [Mojolicious] depends on perl-5.10.1 or higher, there is still an option
to adopt backport project [mojo-legacy] to run on perl-5.8.7.

### Mojo toolkit is available

Since [Marquee] is based on mojo, many mojo classes helps you on manipulating
such as HTTP requests, responses, DOM and JSON.

### Command line interface

In addition to Perl OOP API, Marquee also provides command line interface
to serve current directory contents as a web site, using [Mojo::Daemon].
This is useful for such as development environment or even trivial file sharing.
The API provides some useful option such as auto index, POD viewer,
Markdown viewer. You don't need any Apache things anymore.

## INSTALLATION

To install this module, run the following commands:

    $ wget https://github.com/jamadam/Marquee/tarball/master -O marquee.tar.gz
    $ cpanm marquee.tar.gz
    $ rm marquee.tar.gz

## DOCUMENTATIONS

For more information refer to following documentations.

- [Marquee::Guides::Cookbook](http://mrqe.biz/perldoc/Marquee/Guides/Cookbook) (Cookbook)
- [Marquee](http://mrqe.biz/perldoc/Marquee) (Marquee base class)
- [Index of Modules](http://mrqe.biz/perldoc/)
- [Marquee::Guides::Cookbook](http://mrqe.biz/perldoc/Marquee/Guides/Cookbook#COMMAND_LINE_INTERFACE) (Command line interface)

## SCREENSHOTS

Here is some screenshots of how Marquee look like.

### debug screen

![debug screen](http://mrqe.biz/screenshot/debug_screen.png "Debug screen")

### Auto index

![auto index](http://mrqe.biz/screenshot/autoindex.png "Auto Index")

### Auto tree

![auto tree](http://mrqe.biz/screenshot/autoindextree.png "Auto Index")

## REPOSITORY

[https://github.com/jamadam/Marquee]
[https://github.com/jamadam/Marquee]:https://github.com/jamadam/Marquee

## CREDIT

Icons by [Yusuke Kamiyamane].

## COPYRIGHT AND LICENSE

Copyright (c) 2012 [jamadam]

This program is free software; you can redistribute it and/or
modify it under the [same terms as Perl itself].

[Marquee]:http://mrqe.biz/perldoc/Marquee
[Marquee::Router]:http://mrqe.biz/perldoc/Marquee/Router
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

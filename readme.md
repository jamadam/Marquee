Marquee beta
---------------

## SYNOPSIS
    
    mojo Marquee [--document_root path] [--dafault_file name]
        [--auto_index] ..

## DESCRIPTION

Marquee is a simple HTTP server with server-side include.
The distribution is consist of object oriented Perl API and command line API.

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

    mojo marquee [OPTIONS]

These options are available:
  
    -dr, --document_root <path>  Set document root path, defaults to current dir.
    -df, --default_file <name>   Set default file name and activate auto fill.
    -ai, --auto_index            Activate auto index, defaults to 0.
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

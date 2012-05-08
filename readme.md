MojoSimpleHTTPServer 0.01 beta
---------------

## SYNOPSIS
    
    mojo SimpleHTTPServer [--document_root path] [--dafault_file name]
        [--auto_index] ..

## DESCRIPTION

SimpleHTTPServer is a simple HTTP server with server-side include.
The distribution is consist of object oriented API for Perl and command line
interface.

## INSTALLATION

To install this module, run the following commands:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

## Perl API

MojoSimpleHTTPServer class is based on Mojo. You can run your app in Mojo way

    use MojoSimpleHTTPServer;
    
    my $app = MojoSimpleHTTPServer->new;
    $app->document_root($path);
    $app->auto_index(1);
    $app->default_file('index.html');
    $app->start;

On command line..

    $ ./myapp daemon
    Server available at http://127.0.0.1:3000.

## COMMAND LINE INTERFACE

mojo SimpleHTTPServer [OPTIONS]

These options are available:
  
    -dr, --document_root <path>  Set document root path, defaults to current dir.
    -df, --default_file <name>   Set default file name and activate auto fill.
    -ai, --auto_index            Activate auto index, defaults to 0.
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

    $ mojo SimpleHTTPServer
    [Mon Oct 17 23:18:35 2011] [info] Server listening (http://*:3000)
    Server available at http://127.0.0.1:3000.

### EXAMPLE2(specify port number)

Since this program is based on Mojolicious, the options provided by it is
also available.

    $ mojo SimpleHTTPServer --listen http://*:3001

### EXAMPLE3(specify document root)

Since this program is based on Mojolicious, the options provided by it is
also available.

    $ mojo SimpleHTTPServer --document_root ./public

### EXAMPLE4(specify default file name)

Since this program is based on Mojolicious, the options provided by it is
also available.

    $ mojo SimpleHTTPServer --default_file index.html

### EXAMPLE4(activate auto index)

Since this program is based on Mojolicious, the options provided by it is
also available.

    $ mojo SimpleHTTPServer --auto_index

![Site list](/jamadam/MojoSimpleHTTPServer/raw/master/screenshot/autoindex.png "Auto Index")

[https://github.com/jamadam/MojoSimpleHTTPServer]
[https://github.com/jamadam/MojoSimpleHTTPServer]:https://github.com/jamadam/MojoSimpleHTTPServer

Copyright (c) 2012 [jamadam]
[jamadam]: http://blog2.jamadam.com/

Dual licensed under the MIT and GPL licenses:

- [http://www.opensource.org/licenses/mit-license.php]
- [http://www.gnu.org/licenses/gpl.html]
[http://www.opensource.org/licenses/mit-license.php]: http://www.opensource.org/licenses/mit-license.php
[http://www.gnu.org/licenses/gpl.html]:http://www.gnu.org/licenses/gpl.html

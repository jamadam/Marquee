Marquee beta
---------------

## SYNOPSIS
    
    mojo Marquee [--document_root path] [--dafault_file name]
        [--auto_index] ..

## DESCRIPTION

Marqueeは、サーバーサイドインクルード可能なHTTPサーバーです。
このディストリビューションは、オブジェクト指向のPerl APIとコマンドラインAPIで構成されます。

## インストール

下記のコマンドでインストールします。

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

## Perl API

MarqueeクラスはMojoをベースとしていますので、Mojoの提供する方法でアプリを動作させます。

    use Marquee;
    
    my $app = Marquee->new;
    $app->document_root($path);
    $app->default_file('index.html');
    
    $app->plugin('AutoIndex');
    
    $app->start;

コマンドラインで下記のように起動します。

    $ ./myapp daemon
    Server available at http://127.0.0.1:3000.

## コマンドラインAPI

    mojo marquee [OPTIONS]

下記のコマンドが利用できます:
  
    -dr, --document_root <path>  ドキュメントルートのパスをしています。デフォルトはカレントです。
    -df, --default_file <name>   デフォルトのファイル名を指定し、自動補完を有効にします。
    -ai, --auto_index            オートインデックスを有効にします。デフォルトは0です。
    -ud, --under_development     サーバーサイドインクルードのためのデバッグスクリーンを有効にします。
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

### 使用例1

    $ mojo marquee
    [Mon Oct 17 23:18:35 2011] [info] Server listening (http://*:3000)
    Server available at http://127.0.0.1:3000.

### 使用例2(ポート番号を指定)

    $ mojo marquee --listen http://*:3001

### 使用例3(ドキュメントルートを指定)

    $ mojo marquee --document_root ./public

### 使用例4(デフォルトファイル名を指定)

    $ mojo marquee --default_file index.html

### 使用例4(オートインデックスとツリー表示を有効化)

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

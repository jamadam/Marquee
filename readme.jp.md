Marquee beta
---------------

Marqueeディストリビューションは、Mojoliciousディストリビューション付属のmojoモジュール群のうえに構成された、
もうひとつのウェブアプリケーションフレームワークです。
ダイナミックなコンテンツの開発が、デザイナーワークの延長線上に配置されることを想定してデザインされています。

### デフォルトのURLマッピング

Marqueeはデフォルトで、下記のようにリクエストパスを対応するディレクトリツリーにマッピングします。

このようなパスを与えると
    
    /news/sports/hockey.html

Marqueeは下記のようなテンプレートや静的ファイルを検索します。

    /news/sports/hockey.html
    /news/sports/hockey.html.ep
    /news/sports/hockey.html.epl

階層のマッピングは典型的なApacheなどのHTTPサーバーによく似ており、拡張子のルールはMojoliciousと同様です。

2つ目の拡張子はテンプレートをレンダリングするハンドラーを示します。
epとeplは常に利用可能で、任意のハンドラーを追加することも簡単です。
また、コアに付属のRouteプラグインでマッピングルールのオーバーライドも可能です。

    $app->plugin(Router => sub {
        my $r = shift;
        $r->route(qr{^/path1\.html})->to(sub {
            ...
        });
        $r->route(qr{^/path2\.html})->to(sub {
            ...
        });
    });

### Perl風テンプレート

MarqueeはMojo::Templateベースのテンプレートハンドラーを提供します。
これにより、テンプレートは(Masonに比べ)テンプレート固有の構文が少ない代わりに、よりPerl風の記述が可能になり、つまり学習コストがより少ないです。

Basic syntax.

    <% ...; %> <!-- Perl code execution -->
    <%= ... %> <!-- Perl code output(with html escape) -->
    <%== ... %> <!-- Perl code output(without html escape) -->
    
Block syntax.

    <% $block = begin %>
        Plain html here
        <%= ... %>
        Plain html here
    <% end %>

Inline Perl code syntax.

    % ...;

Any linebreaks are allowed.

    <%
        ...;
        ...;
    %>

Here's a practical example.

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

### Content-Typeの自動生成

Marqueeはテンプレートの命名をname.format.handlerというスタイルに制限しているため、
システムはContent-Typeを自動検出し、ヘッダーを暗黙的に出力することができます。この方式は(PHPに比べ)
より合理的です。

    index.html.ep
    index.json.ep
    index.txt.epl

### インストールが容易

MarqueeはPure-Perlで実装されており、また、唯一の依存先であるMojoliciousディストリビューションもPure-Perlですので、
FTPクライアントですらデプロイ可能です。
Mojoliciousはperl-5.10.1に依存していますが、バックポートプロジェクトであるmojo-legacyを選択すれば、
Perl-5.8.7以降で動作させることが可能です。

### Mojoツールキットが利用可能

Marqueeはmojoのうえに実装されているため、多くのmojoクラスによって、HTTPリクエストや、HTTPレスポンス、DOM、JSONなどの操作が簡単に行えます。

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

MarqueeはPerlのオブジェクト指向フレームワークに加え、カレントディレクトリの内容をMojo::Daemonを使って
ウェブページとして発行するコマンドラインAPIも提供します。これは、Apacheなどを使わずに一時的にウェブページを
発行するのに便利です。

## SYNOPSIS

    mojo marquee [OPTIONS]

下記のコマンドが利用できます:
  
    -dr, --document_root <path>  ドキュメントルートのパスをしています。デフォルトはカレントです。
    -df, --default_file <name>   デフォルトのファイル名を指定し、自動補完を有効にします。
    -ai, --auto_index            オートインデックスを有効にします。デフォルトは0です。
    -dv, --doc_viewer            ドキュメントビューワーを有効にします。
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

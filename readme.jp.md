Marquee beta
---------------

Marqueeディストリビューションは、[Mojolicious]ディストリビューション付属のMojoツールキットのうえに構成された、
もうひとつのウェブアプリケーションフレームワークです。
ダイナミックなウェブサイトの開発が、昔ながらのデザイナーワークの延長線上に配置されることを想定してデザインされています。

これはひょっとすると、[Mason]や[Markup::Perl]、[HTML::Embperl]、或いはPHPの再発明かも知れません。

### デフォルトのURLマッピング

Marqueeはデフォルトで、リクエストパスを対応するファイルとディレクトリの構造にマッピングします。
これはApacheなどの典型的なHTTPサーバーと同様で、このことは本プロジェクトの主要な動機です。
URIの意味をディレクトリ構造に対応させることは物事をシンプルにします。

このようなパスを与えると
    
    /news/sports/hockey.html

Marqueeは下記のようなテンプレートや静的ファイルを検索します。

    /news/sports/hockey.html
    /news/sports/hockey.html.ep
    /news/sports/hockey.html.epl

拡張子のルールは[Mojolicious]と同様です。2つ目の拡張子はテンプレートをレンダリングするハンドラーを示します。
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

Marqueeは[Mojo::Template]ベースのテンプレートハンドラーを提供します。
これにより、テンプレートは(Masonに比べ)テンプレート固有の構文が少ない代わりに、よりPerl風の記述が可能になり、つまり学習コストがより少ないです。

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

### Content-Typeの自動生成

Marqueeはテンプレートの命名をname.format.handlerというスタイルに制限しているため、
システムはContent-Typeを自動検出し、ヘッダーを暗黙的に出力することができます。この方式は(PHPに比べ)
より合理的です。

    index.html.ep
    index.json.ep
    index.txt.epl

### インストールが容易

MarqueeはPure-Perlで実装されており、また、唯一の依存先である[Mojolicious]ディストリビューションもPure-Perlですので、
FTP経由ですらデプロイ可能です。
[Mojolicious]はperl-5.10.1に依存していますが、バックポートプロジェクトである[mojo-legacy]を選択すれば、
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

## コマンドラインインターフェース

MarqueeはPerlのオブジェクト指向APIに加え、カレントディレクトリの内容を[Mojo::Daemon]を使って
ウェブページとして発行するコマンドラインインターフェースも提供します。これは、Apacheなどを使わずに一時的にウェブページを
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

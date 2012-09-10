Marquee
---------------

[Marquee]は、[Mojolicious]ディストリビューション付属のMojoツールキットのうえに構成された、
もうひとつのウェブアプリケーションフレームワークです。
ダイナミックなウェブサイトの開発が、昔ながらのデザイナーワークの延長線上に配置されることを想定してデザインされています。

これはひょっとすると、[Mason]や[Markup::Perl]、[HTML::Embperl]、或いはPHPの再発明かも知れません。

__このソフトウェアはアルファクオリティのため、定常的な使用は推奨されません。__

![Komodo Edit](http://mrqe.biz/screenshot/komodo.png "Komodo Edit")

### デフォルトのURLマッピング

[Marquee]はデフォルトで、リクエストパスを対応するファイルとディレクトリの構造にマッピングします。
これはApacheなどの典型的なHTTPサーバーと同様で、このことは本プロジェクトの主要な動機です。
URIの意味をディレクトリ構造に対応させることは物事をシンプルにします。

このようなパスを与えると
    
    /news/sports/hockey.html

[Marquee]は下記のようなテンプレートや静的ファイルを検索します。

    /news/sports/hockey.html
    /news/sports/hockey.html.ep
    /news/sports/hockey.html.epl

拡張子のルールは[Mojolicious]と同様です。2つ目の拡張子はテンプレートをレンダリングするハンドラーを示します。
epとeplは常に利用可能で、任意のハンドラーを追加することも簡単です。
また、コアに付属の[Marquee::Router]プラグインでマッピングルールのオーバーライドも可能です。

### Perl風テンプレート

[Marquee]は[Mojo::Template]ベースのテンプレートハンドラーを提供します。
これにより、テンプレートは(Masonに比べ)テンプレート固有の構文が少ない代わりに、よりPerl風の記述が可能になり、つまり学習コストがより少ないです。

### Content-Typeの自動生成

[Marquee]はテンプレートの命名をname.format.handlerというスタイルに制限しているため、
システムはContent-Typeを自動検出し、ヘッダーを暗黙的に出力することができます。この方式は(PHPに比べ)
より合理的です。

### インストールが容易

[Marquee]はPure-Perlで実装されており、また、唯一の依存先である[Mojolicious]ディストリビューションもPure-Perlですので、
FTP経由ですらデプロイ可能です。
[Mojolicious]はperl-5.10.1に依存していますが、バックポートプロジェクトである[mojo-legacy]を選択すれば、
Perl-5.8.7以降で動作させることが可能です。

### Mojoツールキットが利用可能

[Marquee]はmojoのうえに実装されているため、多くのmojoクラスによって、HTTPリクエストや、HTTPレスポンス、DOM、JSONなどの操作が簡単に行えます。

### コマンドラインインターフェース

[Marquee]はPerlのオブジェクト指向APIに加え、カレントディレクトリの内容を[Mojo::Daemon]を使って
ウェブページとして発行するコマンドラインインターフェースも提供します。
これは、開発環境用や、些細なファイル共有などにも便利です。
APIには、オートインデックス、PODビューワー、Markdownビューワーなどの便利なオプションが備わっています。
もうApacheなどは必要ありません。

## インストール

下記のコマンドでインストールします。

    $ wget https://github.com/jamadam/Marquee/tarball/master -O marquee.tar.gz
    $ cpanm marquee.tar.gz
    $ rm marquee.tar.gz

## ドキュメンテーション

より詳しい情報は下記のドキュメントを参照してください。

- [Marquee::Guides::Cookbook](http://mrqe.biz/perldoc/Marquee/Guides/Cookbook) (クックブック)
- [Marquee](http://mrqe.biz/perldoc/Marquee) (Marqueeベースクラス)
- [モジュールインデックス](http://mrqe.biz/perldoc/)
- [Marquee::Guides::Cookbook](http://mrqe.biz/perldoc/Marquee/Guides/Cookbook#COMMAND_LINE_INTERFACE) (コマンドラインインターフェース)

## スクリーンショット

下記はMarqueeがどんな見栄えかを示したスクリーンショットです。

### デバッグスクリーン

![debug screen](http://mrqe.biz/screenshot/debug_screen.png "Debug screen")

### オートインデックス

![auto index](http://mrqe.biz/screenshot/autoindex.png "Auto Index")

### オートツリー

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

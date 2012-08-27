=encoding utf8

=head1 NAME

Marquee::Plugin::Markdown - Markdownレンダラープラグイン

=head1 SYNOPSIS

    $app->plugin('Markdown');
    
    # ブラウザにて例えば下記のURLが有効になります
    #
    # http://localhost:3000/markdown/
    # http://localhost:3000/markdown/path/to/doc.md

=head1 DESCRIPTION

これはMarkdown閲覧サーバーのプラグインです。

=head1 INSTANCE METHODS

L<Marquee::Plugin::Markdown>は
L<Marquee::Plugin>の全てのインスタンスメソッドを継承し、下記を追加で実装します。

=head2 register

プラグインを登録します。

    $self->register($app);

=head2 serve_index

Markdownファイルのインデックスを出力します。

    $plugin->serve_index;

=head2 serve_markdown

指定のパスのMarkdownをパースし、HTMLを生成します。

    $plugin->serve_markdown('/path/to/markdown.md');

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

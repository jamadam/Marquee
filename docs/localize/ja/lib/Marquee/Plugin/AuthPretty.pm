=encoding utf8

=head1 NAME

Marquee::Plugin::AuthPretty - [EXPERIMENTAL] Pretty authentication form

=head1 SYNOPSIS
    
    $self->plugin(AuthPretty => [
        qr{^/admin/} => 'Secret Area' => sub($username, $password) {
            return $username eq 'user' &&  $password eq 'pass';
        },
        qr{^/admin/} => 'Secret Area2' => sub($username, $password) {
            return $username eq 'user' &&  $password eq 'pass';
        },
    ], 'path/to/storage_dir', 3600);

=head1 DESCRIPTION

This plugin wraps the whole dispatcher and requires authentication for
specific paths with pretty viewed form.

=head1 ATTRIBUTES

L<Marquee::Plugin::AuthPretty> inherits all attributes from
L<Marquee::Plugin> and implements the following new ones.

=head2 C<realm>

Default value of realm which appears to response header. Each entry can override
it. Defaults to 'Secret Area'.

    $plugin->realm('My secret area');
    my $realm = $plugin->realm;

=head1 INSTANCE METHODS

L<Marquee::Plugin::AuthPretty> inherits all instance methods from
L<Marquee::Plugin> and implements the following new ones.

=head2 register

Register the plugin with path entries. $path_entries must be a list of
regex, realm, auth callback groups. realm is optional.

    $self->register($app, $path_entries);

=head1 EXAMPLE

You can port apache htpasswd entries as follows.

    my $htpasswd = {
        user1 => 'znq.opIaiH.zs',
        user2 => 'dF45lPM2wMCDA',
    };
    
    $self->plugin(AuthPretty => [
        qr{^/admin/} => 'Secret Area' => sub($username, $password) {
            if (my $expect = $htpasswd->{$username}) {
                return crypt($password, $expect) eq $expect;
            }
        },
    ]);

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

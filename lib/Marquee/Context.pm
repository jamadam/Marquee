package Marquee::Context;
use strict;
use warnings;
use Mojo::Base -base;
use feature 'signatures';
no warnings "experimental::signatures";
use Mojo::Util qw{hmac_sha1_sum secure_compare b64_decode b64_encode};
use Mojo::JSON qw{encode_json decode_json};

### ---
### App
### ---
has 'app';

### ---
### Session
### ---
has session => sub {{}};

### ---
### Restrict session to HTTPS
### ---
has session_secure => 0;

### ---
### Restrict session to HTTPS
### ---
has session_path => '/';

### ---
### Session expiretion
### ---
has session_expiration => 3600;

### ---
### Session name
### ---
has session_name => 'mrqe';

### ---
### Transaction
### ---
has 'tx';

### ---
### Constructor
### ---
sub new($class, @args) {
    my $self = $class->SUPER::new(@args);
    
    if (my $value = $self->signed_cookie($self->session_name)) {
        $value =~ s/-/=/g;
        if (my $session = decode_json(b64_decode($value))) {
            $self->session($session);
        }
        my $session = decode_json(b64_decode($value));
        $self->session($session) if ($session);
    }
    
    return $self;
}

### ---
### Set or Get cookie
### ---
sub cookie($self, $name, $value=undef, $opt={}) {
  
    # Response cookie
    if (defined $value) {
        if (length $value > 4096) {
            $self->{app}->log->error(
                                qq{Cookie "$name" is bigger than 4096 bytes.})
        }
        $self->res->cookies(
            Mojo::Cookie::Response->new(name => $name, value => $value, %$opt));
        
        return $self;
    }
    return map { $_->value } @{$self->req->every_cookie($name)} if wantarray; # TODO get rid of it
    return unless my $cookie = $self->req->cookie($name);
    return $cookie->value;
}

### ---
### Alias for tx->req
### ---
sub req($self, @args) {
    $self->{tx}->req(@args);
}

### ---
### Alias for tx->res
### ---
sub res($self, @args) {
    $self->{tx}->res(@args);
}

### ---
### Stash
### ---
sub stash($self, $stash=undef) {
    if ($stash) {
        $self->{stash} = $stash;
    } else {
        $self->{stash} ||= $self->{app}->stash->clone;
    }
    return $self->{stash};
}

### ---
### Alias for app->render
### ---
sub serve($self, @args) {
    $self->{app}->serve(@args);
}

### ---
### check if status code is already set
### ---
sub served($self) {
    return defined $self->res->code;
}

### ---
### Set or Get signed cookie
### ---
sub signed_cookie($self, $name, $value=undef, $opt={}) {
    my $secrets = $self->{app}->secrets;
    
    if (defined $value) {
        return $self->cookie($name,
                    "$value--" . hmac_sha1_sum($value, $secrets->[0]), $opt);
    }
    
    my @results;
    
    for my $value ($self->cookie($name)) {
        if ($value =~ s/--([^\-]+)$//) {
            if (_signature($value, $1, @$secrets)) {
                push(@results, $value);
            } else {
                $self->{app}->log->debug(
                    qq{Bad signed cookie "$name", possible hacking attempt.});
            }
        } else {
            $self->{app}->log->debug(qq{Cookie "$name" not signed.});
        }
    }
  
    return wantarray ? @results : $results[0];
}

### ---
### close
### ---
sub close($self) {
    my $session = $self->session;
    
    if (scalar keys %$session) {
        my $value = b64_encode(encode_json($session), '');
        $value =~ s/=/-/g;
        $self->signed_cookie($self->session_name, $value, {
            expires     => time + $self->session_expiration,
            secure      => $self->session_secure,
            httponly    => 1,
            path        => $self->session_path,
        });
    } elsif (defined $self->cookie($self->session_name)) {
        $self->cookie($self->session_name, '', {
            expires     => 1,
            secure      => $self->session_secure,
            httponly    => 1,
            path        => $self->session_path,
        });
    }
};

sub _signature($value, $signature, @secrets) {
    for (@secrets) {
        return 1 if (secure_compare($signature, hmac_sha1_sum($value, $_)));
    }
    return;
}

1;

__END__

=head1 NAME

Marquee::Context - Context

=head1 SYNOPSIS

    my $c = Marquee::Context->new(app => $app, tx => $tx);
    my $app             = $c->app;
    my $req             = $c->req;
    my $res             = $c->res;
    my $tx              = $c->tx;
    my $session         = $c->session;
    my $cookie          = $c->cookie('key');
    my $signed_cookie   = $c->signed_cookie('key');
    my $stash           = $c->stash;

=head1 DESCRIPTION

L<Marquee::Context> class represents a per request context. This
also has ability to manage session and signed cookies.

=head1 ATTRIBUTES

L<Marquee::Context> implements the following attributes.

=head2 C<app>

L<Marquee> application instance.

    my $app = $c->app;

=head2 C<req>

An Alias to C<$self-E<gt>tx-E<gt>req>.

    my $req = $c->req;
    $c->req($req);

=head2 C<res>

An Alias to C<$self-E<gt>tx-E<gt>res>.

    my $res = $c->req;
    $c->req($res);

=head2 C<session>

Persistent data storage, stored JSON serialized in a signed cookie.
Note that cookies are generally limited to 4096 bytes of data.

    my $session = $c->session;
    my $foo     = $session->{'foo'};
    $session->{foo} = 'bar';

=head2 C<session_path>

A path for session. Defaults to C</>.

    $c->session_path('/some/path/')
    my $path = $c->session_path

=head2 C<session_secure>

Set the secure flag on all session cookies, so that browsers send them only over HTTPS connections.

    my $secure = $c->session_secure;
    $c->session_secure(1);

=head2 C<session_expiration>

Time for the session to expire in seconds from now, defaults to 3600.
The expiration timeout gets refreshed for every request

    my $time = $c->session_expiration;
    $c->session_expiration(3600);

=head2 C<session_name>

Name of the signed cookie used to store session data, defaults to 'mrqe'.

    my $name = $c->session_name;
    $c->session_name('session');

=head2 C<stash>

A stash that inherits app's one.

    my $stash = $c->stash;

=head2 C<tx>

L<Mojo::Transaction> instance.

    my $tx = $c->tx;

=head1 CLASS METHODS

L<Marquee::Context> implements the following class methods.

=head2 C<new>

Constructor.

    my $c = Marquee::Context->new;

=head1 INSTANCE METHODS

L<Marquee::Context> implements the following instance methods.

=head2 C<close>

Close the context.

    my $c2 = $c->close;

=head2 C<cookie>

    my $value  = $c->cookie('foo');
    my @values = $c->cookie('foo');
    $c         = $c->cookie(foo => 'bar');
    $c         = $c->cookie(foo => 'bar', {path => '/'});

Access request cookie values and create new response cookies.

    # Create response cookie with domain
    $c->cookie(name => 'sebastian', {domain => 'mojolicio.us'});

=head2 C<res>

An alias for $c->tx->res

    $c->tx->res($res);
    $res = $c->tx->res;

=head2 C<req>

An alias for $c->tx->req

    $c->tx->res($req);
    $req = $c->tx->res;

=head2 C<serve>

An alias for $app->serve

    $c->serve('path/to/index.html');

=head2 C<served>

Check if the response code has already been set and returns boolean.

    if (! $c->served) {
        ...
    }

=head2 C<signed_cookie>

Access signed request cookie values and create new signed response cookies.
Cookies failing signature verification will be automatically discarded.

    my $value  = $c->signed_cookie('foo');
    my @values = $c->signed_cookie('foo');
    $c         = $c->signed_cookie(foo => 'bar');
    $c         = $c->signed_cookie(foo => 'bar', {path => '/'});

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

package Marquee::Context;
use strict;
use warnings;
use Mojo::Base -base;
use Mojo::Util qw{hmac_md5_sum secure_compare b64_decode b64_encode};

### ---
### App
### ---
__PACKAGE__->attr('app');

### ---
### Session
### ---
__PACKAGE__->attr('session', sub {{}});

### ---
### Restrict session to HTTPS
### ---
__PACKAGE__->attr('session_secure', 0);

### ---
### Restrict session to HTTPS
### ---
__PACKAGE__->attr('session_path', '/');

### ---
### Session expiretion
### ---
__PACKAGE__->attr(session_expiretion => 3600);

### ---
### Session name
### ---
__PACKAGE__->attr(session_name => 'mrqe');

### ---
### Transaction
### ---
__PACKAGE__->attr('tx');

### ---
### Constructor
### ---
sub new {
    my $self = shift->SUPER::new(@_);
    
    if (my $value = $self->signed_cookie($self->session_name)) {
        $value =~ s/-/=/g;
        if (my $session = Mojo::JSON->new->decode(b64_decode($value))) {
            $self->session($session);
        }
    }
    
    return $self;
}

### ---
### Set or Get cookie
### ---
sub cookie {
    my ($self, $name, $value, $opt) = @_;
    $opt ||= {};
  
    # Response cookie
    if (defined $value) {
        if (length $value > 4096) {
            $self->app->log->error(
                                qq{Cookie "$name" is bigger than 4096 bytes.})
        }
        $self->tx->res->cookies(
            Mojo::Cookie::Response->new(name => $name, value => $value, %$opt));
        
        return $self;
    }
    return map { $_->value } $self->tx->req->cookie($name) if wantarray;
    return unless my $cookie = $self->tx->req->cookie($name);
    return $cookie->value;
}

### ---
### Stash
### ---
sub stash {
    my ($self, $stash) = @_;
    if ($stash) {
        $self->{stash} = $stash;
    } else {
        $self->{stash} ||= $self->app->stash->clone;
    }
    return $self->{stash};
}

### ---
### Set or Get signed cookie
### ---
sub served {
    return defined shift->tx->res->code;
}

### ---
### Set or Get signed cookie
### ---
sub signed_cookie {
    my ($self, $name, $value, $opt) = @_;
  
    my $secret = $self->app->secret;
    
    if (defined $value) {
        return $self->cookie($name,
                        "$value--" . hmac_md5_sum($value, $secret), $opt);
    }
  
    my @results;
    
    for my $value ($self->cookie($name)) {
        if ($value =~ s/--([^\-]+)$//) {
            my $sig = $1;
      
            if (secure_compare($sig, hmac_md5_sum($value, $secret))) {
                push(@results, $value);
            } else {
                $self->app->log->debug(
                    qq{Bad signed cookie "$name", possible hacking attempt.});
            }
        } else {
            $self->app->log->debug(qq{Cookie "$name" not signed.});
        }
    }
  
    return wantarray ? @results : $results[0];
}

### ---
### close
### ---
sub close {
    my $self = shift;
    
    my $session = $self->session;
    
    if (scalar keys %$session) {
        my $value = b64_encode(Mojo::JSON->new->encode($session), '');
        $value =~ s/=/-/g;
        $self->signed_cookie($self->session_name, $value, {
            expires     => time + $self->session_expiretion,
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

1;

__END__

=head1 NAME

Marquee::Context - Context

=head1 SYNOPSIS

    my $context = Marquee::Context->new(app => $app, tx => $tx);
    my $app             = $context->app;
    my $tx              = $context->tx;
    my $session         = $context->session;
    my $cookie          = $context->cookie('key');
    my $signed_cookie   = $context->signed_cookie('key');
    my $stash           = $context->stash;

=head1 DESCRIPTION

L<Marquee::Context> class represents a per request context. This
also has ability to manage session and signed cookies.

=head1 ATTRIBUTES

=head2 app

L<Marquee> instance.

    my $app = $context->app;

=head2 session

Persistent data storage, stored JSON serialized in a signed cookie.
Note that cookies are generally limited to 4096 bytes of data.

    my $session = $context->session;
    my $foo     = $session->{'foo'};
    $session->{foo} = 'bar';

=head2 session_secure

Set the secure flag on all session cookies, so that browsers send them only over HTTPS connections.

    my $secure = $context->session_secure;
    $context->session_secure(1);

=head2 session_expiration

Time for the session to expire in seconds from now, defaults to 3600.
The expiration timeout gets refreshed for every request

    my $time = $context->session_expiration;
    $context->session_expiration(3600);

=head2 session_name

Name of the signed cookie used to store session data, defaults to 'mrqe'.

    my $name = $context->session_name;
    $context->session_name('session');

=head2 stash

A stash that inherits app's one.

    my $stash = $context->stash;

=head2 tx

L<Mojo::Transaction> instance.

    my $tx = $context->tx;

=head1 METHODS

=head2 new

Constructor.

    my $context = Marquee::Context->new;

=head2 $instance->close

Close the context.

=head2 $instance->cookie

    my $value  = $c->cookie('foo');
    my @values = $c->cookie('foo');
    $c         = $c->cookie(foo => 'bar');
    $c         = $c->cookie(foo => 'bar', {path => '/'});

Access request cookie values and create new response cookies.

    # Create response cookie with domain
    $c->cookie(name => 'sebastian', {domain => 'mojolicio.us'});

=head2 $instance->served

Check if the response code has already been set and returns boolean.

    if (! $c->served) {
        ...
    }

=head2 $instance->signed_cookie

Access signed request cookie values and create new signed response cookies.
Cookies failing signature verification will be automatically discarded.

    my $value  = $c->signed_cookie('foo');
    my @values = $c->signed_cookie('foo');
    $c         = $c->signed_cookie(foo => 'bar');
    $c         = $c->signed_cookie(foo => 'bar', {path => '/'});

=head1 SEE ALSO

L<Marquee>, L<Mojolicious>

=cut

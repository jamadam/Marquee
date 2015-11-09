package Mojolicious::Command::marquee;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Commands';
use feature 'signatures';
no warnings "experimental::signatures";

use Getopt::Long 'GetOptions';
use Mojo::Server::Daemon;
use Marquee;

  has description => <<'EOF';
Start Marquee.
EOF

  has usage => <<"EOF";
usage: $0 marquee [OPTIONS]

These options are available:
  
  -dr, --document_root <path>  Set document root path, defaults to current dir.
  -df, --default_file <name>   Set default file name and activate auto fill.
  -ai, --auto_index            Activate auto index, defaults to 0.
  -dv, --doc_viewer            Activate markdown viewer.
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
EOF

# "It's an albino humping worm!
#  Why do they call it that?
#  Cause it has no pigment."
sub run($self, @args) {
  
  my $app = Marquee->new;
  my $daemon = Mojo::Server::Daemon->new;
  $daemon->app($app);

  # Options
  local @ARGV = @_;
  my @listen;
  GetOptions(
    'b|backlog=i'           => sub($v) { $daemon->backlog($v) },
    'c|clients=i'           => sub($v) { $daemon->max_clients($v) },
    'g|group=s'             => sub($v) { $daemon->group($v) },
    'i|inactivity=i'        => sub($v) { $daemon->inactivity_timeout($v) },
    'l|listen=s'            => \@listen,
    'p|proxy'               => sub($v) { $ENV{MOJO_REVERSE_PROXY} = 1 },
    'r|requests=i'          => sub($v) { $daemon->max_requests($v) },
    'u|user=s'              => sub($v) { $daemon->user($v) },
    'dr|document_root=s'    => sub($v) { $app->document_root($v) },
    'ai|auto_index'         => sub() { $app->plugin('AutoIndex') },
    'df|default_file=s'     => sub($v) { $app->default_file($v) },
    'ud|under_development'  => sub() { $app->under_development(1) },
    'dv|doc_viewer'         => sub() {
        $app->plugin('PODViewer');
        $app->plugin('Markdown');
      },
  );
  
  $app->document_root || $app->document_root('./');

  # Start
  $daemon->listen(\@listen) if @listen;
  $daemon->run;
}

1;
__END__

=head1 NAME

Mojolicious::Command::marquee - marquee command

=head1 SYNOPSIS

  use Mojolicious::Command::marquee;

  my $app = Mojolicious::Command::marquee->new;
  $app->run(@ARGV);

On command line

  $ mojo marquee [OPTIONS]

=head1 DESCRIPTION

L<Mojolicious::Command::marquee> starts applications with
L<Mojo::Server::Daemon> backend.

=head1 ATTRIBUTES

L<Mojolicious::Command::marquee> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 C<description>

Short description of this command, used for the command list.

  my $description = $marquee->description;
  $marquee         = $marquee->description('Foo!');

=head2 C<usage>

Usage information for this command, used for the help screen.

  my $usage = $marquee->usage;
  $marquee  = $marquee->usage('Foo!');

=head1 INSTANCE METHODS

L<Mojolicious::Command::marquee> inherits all instance methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 C<run>

Run this command.

  $marquee->run(@ARGV);

=head1 SEE ALSO

L<marquee>, L<Mojolicious>.

=cut

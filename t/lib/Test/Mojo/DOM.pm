package Test::Mojo::DOM;
use Mojo::Base 'Test::Mojo';
use Test::Mojo::DOM::Inspector;

  sub dom_inspector {
    my ($self, $cb) = @_;
    $cb->(Test::Mojo::DOM::Inspector->new($self->tx->res->dom));
    return $self;
  }

1;

__END__

=head1 NAME

Test::Mojo::DOM - DOM test

=head1 SYNOPSIS

  use Test::Mojo::DOM;
  use Test::More tests => 35;
  
  my $t = Test::Mojo::DOM->new(MyApp->new);
  $t->get_ok('/')
      ->status_is(200)
      ->dom_inspector(sub {
          my $t = shift;
          $t->at('a')
              ->attr_is('href', '../')
              ->attr_isnt('href', './')
              ->attr_like('href', qr'\.\./')
              ->attr_unlike('href', qr'\.\./a')
              ->text_is('some link')
              ->text_isnt('some link2')
              ->text_like(qr'some')
              ->text_unlike(qr'some2')
              ->has_attr('href')
              ->has_attr('empty')
              ->has_attr_not('not_exists');
          $t->at('a')->get(1)
              ->text_is('some link2');
          $t->at('a:nth-child(2)')
              ->text_is('some link2');
          $t->at('a')->each(sub {
              my $t = shift;
              $t->text_like(qr{.});
              $t->text_unlike(qr{a});
              $t->attr_like('href', qr{.});
              $t->attr_unlike('href', qr{a});
          });
          $t->at('a')->parent->attr_is('id', 'some_p');
          $t->at('a')->parent->parent->attr_is('id', 'wrapper');
          $t->at('#some_p')->has_child('a');
          $t->at('#some_p2')->has_child_not('a');
          
          $t->at('#some_img')->has_class('class1');
          $t->at('#some_img')->has_class('class2');
          $t->at('#some_img')->has_class('class3');
          $t->at('#some_img')->has_class_not('class4');
      });

=head1 DESCRIPTION

This is a test tool for Mojo apps on DOM structure.

=head1 ATTRIBUTES

Test::Mojo::DOM inherits all attributes from Test::Mojo.

=head1 METHODS

Test::Mojo::DOM inherits all methods from Test::Mojo and implements the
following new ones.

=head2 Test::Mojo::DOM->dom_inspector($code_ref)

  $t->dom_inspector(sub {
    my $inspector = shift;
  });

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

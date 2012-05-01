package Test::Mojo::DOM::Inspector;
use Mojo::Base -base;
use Mojo::DOM;
use Test::More;
  
  sub new {
    my ($class, $dom) = @_;
    my $self = $class->SUPER::new;
    if (! ref $dom) {
      $dom = Mojo::DOM->new($dom);
    }
    if (! $dom->isa('Mojo::Collection')) {
      $dom = Mojo::Collection->new($dom);
    }
    $self->{dom} = $dom;
    return $self;
  }
  
  sub dom {
    my ($self, $index) = @_;
    if (defined $index) {
      return $self->{dom}->[$index];
    }
    return $self->{dom};
  }
  
  sub at {
    my ($self, $selector) = @_;
    return __PACKAGE__->new($self->dom(0)->find($selector));
  }
  
  sub children {
    my ($self, $selector) = @_;
    return __PACKAGE__->new($self->dom(0)->children($selector));
  }
  
  sub each {
    my ($self, $cb) = @_;
    return __PACKAGE__->new($self->dom->each(sub {
      $cb->(__PACKAGE__->new(shift), shift);
    }));
  }
  
  sub get {
    my ($self, $index) = @_;
    return __PACKAGE__->new($self->dom($index));
  }
  
  sub find {
    my ($self, $selector) = @_;
    return __PACKAGE__->new($self->dom(0)->find($selector));
  }
  
  sub parent {
    my ($self) = @_;
    return __PACKAGE__->new($self->dom(0)->parent);
  }
  
  sub root {
    my ($self) = @_;
    return __PACKAGE__->new($self->dom(0)->root);
  }
  
  sub text_is {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is $self->dom(0)->text, $value, $desc || 'exact match for text';
    return $self;
  }
  
  sub text_isnt {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::isnt $self->dom(0)->text, $value, $desc || 'no match for text';
    return $self;
  }
  
  sub text_like {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::like $self->dom(0)->text, $value, $desc || 'text is similar';
    return $self;
  }
  
  sub text_unlike {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::unlike $self->dom(0)->text, $value, $desc || 'text is not similar';
    return $self;
  }
  
  sub attr_is {
    my ($self, $name, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is $self->dom(0)->attrs($name),
                                $value, $desc || 'exact match for attr value';
    return $self;
  }
  
  sub attr_isnt {
    my ($self, $name, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::isnt $self->dom(0)->attrs($name),
                                    $value, $desc || 'no match for attr value';
    return $self;
  }
  
  sub attr_like {
    my ($self, $name, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::like $self->dom(0)->attrs($name),
                                      $value, $desc || 'attr value is similar';
    return $self;
  }
  
  sub attr_unlike {
    my ($self, $name, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::unlike $self->dom(0)->attrs($name),
                                  $value, $desc || 'attr value is not similar';
    return $self;
  }
  
  sub has_attr {
    my ($self, $name, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok defined $self->dom(0)->attrs($name),
                                            $desc || qq/has attribute "$name"/;
    return $self;
  }
  
  sub has_attr_not {
    my ($self, $name, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok ! defined $self->dom(0)->attrs($name),
                                        $desc || qq/has attribute "$name" not/;
    return $self;
  }
  
  sub has_child {
    my ($self, $selector, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok $self->dom(0)->at($selector),
                                            $desc || qq/has child "$selector"/;
    return $self;
  }
  
  sub has_child_not {
    my ($self, $selector, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok !$self->dom(0)->at($selector),
                                        $desc || qq/has child "$selector" not/;
    return $self;
  }
  
  sub has_class {
    my ($self, $name, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $len = scalar grep {$_ eq $name} (split(/\s/, $self->dom(0)->attrs('class')));
    Test::More::ok($len, $desc || qq/has child "$name"/);
    return $self;
  }
  
  sub has_class_not {
    my ($self, $name, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $len = scalar grep {$_ eq $name} (split(/\s/, $self->dom(0)->attrs('class')));
    Test::More::ok(! $len, $desc || qq/has child "$name"/);
    return $self;
  }

1;

__END__

=head1 NAME

Test::Mojo::DOM - Dom test

=head1 SYNOPSIS

  use Test::Mojo::DOM::Inspector;
  
  my $t = Test::Mojo::DOM::Inspector->new($mojo_dom);
  my $t = Test::Mojo::DOM::Inspector->new($html_in_string);
  
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

=head1 DESCRIPTION

Test::Mojo::DOM::Inspector is a test agent, which allows you to both traversing
dom nodes and test against them.

=head1 METHODS

=head2 Test::Mojo::DOM::Inspector->new($dom)

This is called automatcially.

  my $t = Test::Mojo::DOM::Inspector->new($dom);

or

  my $t = Test::Mojo::DOM::Inspector->new($html);

=head2 $instance->dom($index)

=head2 Traversing

=head3 $instance->at($selector)

=head3 $instance->children($selector)

=head3 $instance->each($cb)

=head3 $instance->get($number)

=head3 $instance->find($selector)

=head3 $instance->parent()

=head3 $instance->root()

=head2 Testing

=head3 $instance->text_is($expected, $description)

=head3 $instance->text_isnt($expected, $description)

=head3 $instance->text_like($expected, $description)

=head3 $instance->text_unlike($expected, $description)

=head3 $instance->attr_is($name, $expected, $description)

=head3 $instance->attr_isnt($name, $expected, $description)

=head3 $instance->attr_like($name, $expected, $description)

=head3 $instance->attr_unlike($name, $expected, $description)

=head3 $instance->has_attr($name, $description)

=head3 $instance->has_attr_not($name, $description)

=head3 $instance->has_child($selector, $description)

=head3 $instance->has_child_not($selector, $description)

=head3 $instance->has_class($name, $description)

=head3 $instance->has_class_not($name, $description)

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

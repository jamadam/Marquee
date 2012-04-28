package Test::Mojo::Dom;
use Mojo::Base 'Test::Mojo';
  
  sub test_dom {
    my ($self, $cb) = @_;
    #local $Test::Builder::Level = $Test::Builder::Level + 1;
    $cb->(Test::Mojo::Dom::_Test->new($self->tx->res->dom));
  }

package Test::Mojo::Dom::_Test;
use Mojo::Base -base;
use Mojo::DOM;

  __PACKAGE__->attr('dom');
  
  sub new {
    my ($class, $dom) = @_;
    my $self = $class->SUPER::new;
    if (! $dom->isa('Mojo::Collection')) {
      $dom = Mojo::Collection->new($dom || Mojo::DOM->new);;
    }
    $self->dom($dom);
    return $self;
  }
  
  sub at {
    my ($self, $selector) = @_;
    return __PACKAGE__->new($self->dom->[0]->find($selector));
  }
  
  sub children {
    my ($self, $selector) = @_;
    return __PACKAGE__->new($self->dom->[0]->children($selector));
  }
  
  sub each {
    my ($self, $cb) = @_;
    return __PACKAGE__->new($self->dom->each(sub {
      $cb->(__PACKAGE__->new(shift));
    }));
  }
  
  sub get {
    my ($self, $index) = @_;
    return __PACKAGE__->new($self->dom->[$index]);
  }
  
  sub find {
    my ($self, $selector) = @_;
    return __PACKAGE__->new($self->dom->[0]->find($selector));
  }
  
  sub parent {
    my ($self) = @_;
    return __PACKAGE__->new($self->dom->[0]->parent);
  }
  
  sub root {
    my ($self) = @_;
    return __PACKAGE__->new($self->dom->[0]->root);
  }
  
  sub text_is {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is $self->dom->[0]->text, $value, $desc || 'exact match for text';
    return $self;
  }
  
  sub text_isnt {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::isnt $self->dom->[0]->text, $value, $desc || 'no match for text';
    return $self;
  }
  
  sub text_like {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::like $self->dom->[0]->text, $value, $desc || 'text is similar';
    return $self;
  }
  
  sub text_unlike {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::unlike $self->dom->[0]->text, $value, $desc || 'text is not similar';
    return $self;
  }
  
  sub attr_is {
    my ($self, $name, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is $self->dom->[0]->attrs($name),
                                $value, $desc || 'exact match for attr value';
    return $self;
  }
  
  sub attr_isnt {
    my ($self, $name, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::isnt $self->dom->[0]->attrs($name),
                                    $value, $desc || 'no match for attr value';
    return $self;
  }
  
  sub attr_like {
    my ($self, $name, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::like $self->dom->[0]->attrs($name),
                                      $value, $desc || 'attr value is similar';
    return $self;
  }
  
  sub attr_unlike {
    my ($self, $name, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::unlike $self->dom->[0]->attrs($name),
                                  $value, $desc || 'attr value is not similar';
    return $self;
  }
  
  sub has_attr {
    my ($self, $name, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok defined $self->dom->[0]->attrs($name),
                                            $desc || qq/has attribute "$name"/;
    return $self;
  }
  
  sub has_attr_not {
    my ($self, $name, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok ! defined $self->dom->[0]->attrs($name),
                                        $desc || qq/has attribute "$name" not/;
    return $self;
  }
  
  sub has_child {
    my ($self, $selector, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok $self->dom->[0]->at($selector),
                                            $desc || qq/has child "$selector"/;
    return $self;
  }
  
  sub has_child_not {
    my ($self, $selector, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::ok !$self->dom->[0]->at($selector),
                                        $desc || qq/has child "$selector" not/;
    return $self;
  }
  
  sub has_class {
    my ($self, $name, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $len = scalar grep {$_ eq $name} (split(/\s/, $self->dom->[0]->attrs('class')));
    Test::More::ok($len, $desc || qq/has child "$name"/);
    return $self;
  }
  
  sub has_class_not {
    my ($self, $name, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $len = scalar grep {$_ eq $name} (split(/\s/, $self->dom->[0]->attrs('class')));
    Test::More::ok(! $len, $desc || qq/has child "$name"/);
    return $self;
  }

1;

__END__
  
=head1 NAME

Test::Mojo::Dom - Dom test

=head1 SYNOPSIS

use Test::Mojo::Dom;
    
    use Test::More tests => 35;
    
    my $t = Test::Mojo::Dom->new(MyApp->new);
    $t->get_ok('/')
        ->status_is(200)
        ->test_dom(sub {
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

This is a test tool for Mojo apps on dom structure.

=head1 METHODS

=head2 $self->test_dom($code_ref)

=head2 Class->new($dom)

=head2 $self->at($selector)

=head2 $self->children($selector)

=head2 $self->each($cb)

=head2 $self->get($number)

=head2 $self->find($selector)

=head2 $self->parent()

=head2 $self->root()

=head2 $self->text_is($expected, $description)

=head2 $self->text_isnt($expected, $description)

=head2 $self->text_like($expected, $description)

=head2 $self->text_unlike($expected, $description)

=head2 $self->attr_is($name, $expected, $description)

=head2 $self->attr_isnt($name, $expected, $description)

=head2 $self->attr_like($name, $expected, $description)

=head2 $self->attr_unlike($name, $expected, $description)

=head2 $self->has_attr($name, $description)

=head2 $self->has_attr_not($name, $description)

=head2 $self->has_child($selector, $description)

=head2 $self->has_child_not($selector, $description)

=head2 $self->has_class($name, $description)

=head2 $self->has_class_not($name, $description)

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

Sugama Keita, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Sugama Keita.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

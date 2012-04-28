package Test::Mojo::Dom;
use Mojo::Base 'Test::Mojo';
  
  sub dom_text_is {
    my ($self, $selector, $expected, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is $self->tx->res->dom->at($selector)->text, $expected,
      $desc || qq/"$selector" exists/;
    return $self;
  }
  
  sub dom_sub_test {
    my ($self, $cb) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $cb->(Test::Mojo::Dom::_Test->new($self->tx->res->dom));
  }

package Test::Mojo::Dom::_Test;
use Mojo::Base -base;
use Mojo::DOM;

  __PACKAGE__->attr('dom');
  
  sub new {
    my ($class, $dom) = @_;
    my $self = $class->SUPER::new;
    $self->dom($dom || Mojo::DOM->new);
    return $self;
  }
  
  sub at {
    my ($self, $selector) = @_;
    return __PACKAGE__->new($self->{dom}->at($selector));
  }
  
  sub children {
    my ($self, $selector) = @_;
    return __PACKAGE__->new($self->{dom}->children($selector));
  }
  
  sub each {
    my ($self, $cb) = @_;
    return __PACKAGE__->new($self->{dom}->each(sub {
      $cb->(__PACKAGE__->new(shift));
    }));
  }
  
  sub find {
    my ($self, $selector) = @_;
    return __PACKAGE__->new($self->{dom}->find($selector));
  }
  
  sub parent {
    my ($self) = @_;
    return __PACKAGE__->new($self->{dom}->parent);
  }
  
  sub root {
    my ($self) = @_;
    return __PACKAGE__->new($self->{dom}->root);
  }
  
  sub text_is {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is $self->dom->text, $value, $desc || 'exact match for text';
    return $self;
  }
  
  sub text_like {
    my ($self, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::like $self->dom->text, $value, $desc || 'exact match for text';
    return $self;
  }
  
  sub attr_is {
    my ($self, $name, $value, $desc) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::is $self->dom->attrs($name), $value, $desc || 'exact match for attr value';
    return $self;
  }

1;

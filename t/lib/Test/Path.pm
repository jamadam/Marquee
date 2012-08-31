package Test::Path;
use Test::More;
use File::Spec;
our(@ISA, @EXPORT_OK);
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(path_is);

sub path_is {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($given, $expect, $msg) = @_;
  $given =~ s{\\}{/}g;
  $expect =~ s{\\}{/}g;
  is($given, $expect, $msg);
}

1;

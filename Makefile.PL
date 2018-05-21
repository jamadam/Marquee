use 5.020000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Marquee',
  VERSION_FROM  => 'lib/Marquee.pm',
  ABSTRACT_FROM => 'lib/Marquee.pm',
  AUTHOR        => 'sugama <sugama@jamadam.com>',
  LICENSE       => 'perl',
  META_MERGE   => {
    dynamic_config => 0,
    'meta-spec'    => {version => 2},
    no_index       => {directory => ['examples', 't']},
    prereqs        => {runtime => {requires => {perl => '5.020000'}}},
    resources      => {
      bugtracker => {web => 'https://github.com/jamadam/Marquee/issues'},
      homepage   => 'http://marquee.jamadam.com',
      repository => {
        type => 'git',
        url  => 'https://github.com/jamadam/Marquee.git',
        web  => 'https://github.com/jamadam/Marquee',
      },
    },
  },
  BUILD_REQUIRES => {
    'Test::More'            => '0.98',
    'Test::UseAllModules'   => '0.10',
  },
  PREREQ_PM => {
    'Mojolicious' => '7.80',
  },
  test => {TESTS => 't/*.t t/*/*.t'}
);

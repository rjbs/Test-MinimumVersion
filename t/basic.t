use strict;
use warnings;

use Test::Tester;
use Test::More tests => 9;
use Test::MinimumVersion;

minimum_version_ok('t/eg/bin/5.6-warnings.pl', '5.006');

check_test(
  sub {
    minimum_version_ok('t/eg/bin/5.6-warnings.pl', '5.006');
  },
  {
    ok   => 1,
    name => 't/eg/bin/5.6-warnings.pl',
    diag => '',
  },
  "successful comparison"
);

subtest "skip files" => sub {
  chdir "t/eg";
  all_minimum_version_ok(
    '5.006',
    { no_test => 1, skip => [ 'bin/explicit-5.8.pl' ] },
  );
};


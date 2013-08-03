use strict;
use warnings;

use Test::Tester 0.109;
use Test::More 0.98 tests => 8;
use Test::MinimumVersion;

minimum_version_ok('t/eg/5.6-warnings.pl', '5.006');

check_test(
  sub {
    minimum_version_ok('t/eg/5.6-warnings.pl', '5.006');
  },
  {
    ok   => 1,
    name => 't/eg/5.6-warnings.pl',
    diag => '',
  },
  "successful comparison"
);


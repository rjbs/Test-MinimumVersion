use strict;
use warnings;

use inc::Module::Install;

author    ('Ricardo SIGNES <rjbs@cpan.org>');
license   ('perl');
all_from  ('lib/Test/MinimumVersion.pm');

requires('Perl::MinimumVersion' => 0.14);  # accuracy
requires('Test::Builder'        => 0.000); # minimum unknown
requires('version'              => 0.70);  # culted from Perl::MinimumVersion

WriteAll();

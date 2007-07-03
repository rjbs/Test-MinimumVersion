use strict;
use warnings;

use inc::Module::Install;

name      ('Test-MinimumVersion');
all_from  ('lib/Test/MinimumVersion.pm');
author    ('Ricardo SIGNES <rjbs@cpan.org>');
license   ('perl');

requires('File::Find::Rule::Perl' => 0.00);  # any version will do
requires('Perl::MinimumVersion'   => 0.14);  # accuracy
requires('Test::Builder'          => 0.000); # minimum unknown
requires('version'                => 0.70);  # culted from Perl::MinimumVersion

WriteAll();

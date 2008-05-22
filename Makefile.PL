use inc::Module::Install;

all_from  ('lib/Test/MinimumVersion.pm');

requires('File::Find::Rule::Perl' => 0.00);  # any version will do
requires('Perl::MinimumVersion'   => 0.15);  # accuracy
requires('Test::Builder'          => 0.000); # minimum unknown
requires('version'                => 0.70);  # culted from Perl::MinimumVersion

auto_manifest;
extra_tests;
WriteAll();

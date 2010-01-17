use inc::Module::Install;

all_from  ('lib/Test/MinimumVersion.pm');

requires('File::Find::Rule::Perl' => 0.00);  # any version will do
requires('Perl::MinimumVersion'   => 1.20);  # accuracy
requires('Test::Builder'          => 0.000); # minimum unknown
requires('Test::Tester'           => 0.000); # minimum unknown
requires('version'                => 0.70);  # culted from Perl::MinimumVersion
requires('YAML::Tiny'             => 1.40);  # bugfixes

extra_tests;
auto_manifest;

WriteAll();

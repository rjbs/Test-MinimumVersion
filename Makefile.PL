use strict;
use warnings;
 
 BEGIN { require 5.006; }
 
use ExtUtils::MakeMaker 6.31;
 
 
 
my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Test::MinimumVersion',
                       'DISTNAME' => 'Test-MinimumVersion',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Ricardo Signes',
                       'BUILD_REQUIRES' => {
                                             "Test::More"   => '0.98',
                                             "Test::Tester" => '0.109',
                                           },
                       'ABSTRACT' => 'does your code require newer perl than you think?',
                       'EXE_FILES' => [],
                       'VERSION_FROM' => 'lib/Test/MinimumVersion.pm',
                       'PREREQ_PM' => {
                                        "Exporter"               => '5.68',
                                        "File::Find::Rule"       => '0.33',
                                        "File::Find::Rule::Perl" => '1.13',
                                        "Parse::CPAN::Meta"      => '1.4405',
                                        "Perl::MinimumVersion"   => '1.32',
                                        "Test::Builder"          => '0.98',
                                        "parent"                 => '0.225',
                                        "version"                => '0.9902',
                                      },
                       'LICENSE' => 'perl'
                     );
 
 
delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };
 
delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };
 
WriteMakefile(%WriteMakefileArgs);

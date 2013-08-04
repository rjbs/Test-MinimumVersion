use 5.008009;
use strict;
use warnings;

package Test::MinimumVersion;

BEGIN {
  $Test::MinimumVersion::VERSION = '0.101088';
}

#use base 'Exporter';
use parent 0.225 qw(Exporter);

# ABSTRACT: does your code require newer perl than you think?
#use Data::Printer {caller_info => 1, colored => 1,};

=head1 SYNOPSIS

Example F<minimum-perl.t>:

  #!perl
  use Test::MinimumVersion;
  all_minimum_version_ok('5.008');

=cut

use File::Find::Rule 0.33;
use File::Find::Rule::Perl 1.13;
use Perl::MinimumVersion 1.32;    # accuracy
use version 0.9902;
use Parse::CPAN::Meta 1.4405;

use Test::Builder 0.98;
@Test::MinimumVersion::EXPORT = qw(
  minimum_version_ok
  all_minimum_version_ok
  all_minimum_version_from_metayml_ok
  all_minimum_version_from_metajson_ok
  all_minimum_version_from_meta2_ok
);

sub import {
  my ($self) = shift;
  my $pack = caller;

  my $Test = Test::Builder->new;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, @Test::MinimumVersion::EXPORT);
}

sub _objectify_version {
  my ($version) = @_;
  $version
    = eval { $version->isa('version') } ? $version : version->new($version);
}

=func minimum_version_ok

  minimum_version_ok($file, $version);

This test passes if the given file does not seem to require any version of perl
newer than C<$version>, which may be given as a version string or a version
object.

=cut

sub minimum_version_ok {
  my ($file, $version) = @_;

  my $Test = Test::Builder->new;

  $version = _objectify_version($version);

  my $pmv = Perl::MinimumVersion->new($file);

  my $explicit_minimum = $pmv->minimum_explicit_version || 0;
  my $minimum = $pmv->minimum_syntax_version($explicit_minimum) || 0;

  my $is_syntax = 1 if $minimum and $minimum > $explicit_minimum;

  $minimum = $explicit_minimum
    if $explicit_minimum and $explicit_minimum > $minimum;

  my %min = $pmv->version_markers;

  if ($minimum <= $version) {
    $Test->ok(1, $file);
  }
  else {
    $Test->ok(0, $file);
    $Test->diag("$file requires $minimum "
        . ($is_syntax ? 'due to syntax' : 'due to explicit requirement'));

    if ($is_syntax and my $markers = $min{$minimum}) {
      $Test->diag("version markers for $minimum:");
      $Test->diag("- $_ ") for @$markers;
    }
  }
}

=func all_minimum_version_ok

  all_minimum_version_ok($version, \%arg);

Given either a version string or a L<version> object, this routine produces a
test plan (if there is no plan) and tests each relevant file with
C<minimum_version_ok>.

Relevant files are found by L<File::Find::Rule::Perl>.

C<\%arg> is optional.  Valid arguments are:

  paths   - in what paths to look for files; defaults to (t, lib, xt/smoke,
            and any .pm or .PL files in the current working directory)
            if it contains files, they will be checked
  no_plan - do not plan the tests about to be run

=cut

sub all_minimum_version_ok {
  my ($version, $arg) = @_;
  $arg ||= {};
  $arg->{paths} ||= [qw( script bin lib t )];

  my $Test = Test::Builder->new;

  $version = _objectify_version($version);

  my @perl_files;
  for my $path (@{$arg->{paths}}) {
    if (-f $path and -s $path) {
      push @perl_files, $path;
    }
    elsif (-d $path) {
      push @perl_files, File::Find::Rule->perl_file->in($path);
    }
  }

  unless ($Test->has_plan or $arg->{no_plan}) {
    $Test->plan(tests => scalar @perl_files);
  }

  minimum_version_ok($_, $version) for @perl_files;
}

=func all_minimum_version_from_metayml_ok

  all_minimum_version_from_metayml_ok(\%arg);

This routine checks F<META.yml> for an entry in F<{requires}{perl}>. If no
META.yml file or no perl version is found, all tests are skipped. If a version
is found, the test proceeds as if C<all_minimum_version_ok> had been called
with that version.

=cut

sub all_minimum_version_from_metayml_ok {
  my ($arg) = @_;
  $arg ||= {};

  my $Test = Test::Builder->new;

  $Test->plan(skip_all => "META.yml could not be found")
    unless -f 'META.yml' and -r _;

  my $metadata_structure = Parse::CPAN::Meta->load_file('META.yml');

  $Test->plan(skip_all => "no minimum perl version could be determined")
    unless my $version = $metadata_structure->{requires}{perl};

  all_minimum_version_ok($version, $arg);
}

=func all_minimum_version_from_metajson_ok

  all_minimum_version_from_metajson_ok(\%arg);

This routine checks F<META.json> for an entry in F<{prereqs}{runtime}{requires}{perl}>. If no
META.json file or no perl version is found, all tests are skipped. If a version
is found, the test proceeds as if C<all_minimum_version_ok> had been called
with that version.

=cut

sub all_minimum_version_from_metajson_ok {
  my ($arg) = @_;
  $arg ||= {};

  my $Test = Test::Builder->new;

  $Test->plan(skip_all => "META.json could not be found")
    unless -f 'META.json' and -r _;

  my $metadata_structure = Parse::CPAN::Meta->load_file('META.json');

  $Test->plan(skip_all => "no minimum perl version could be determined")
    unless my $version
    = $metadata_structure->{prereqs}{runtime}{requires}{perl};

  all_minimum_version_ok($version, $arg);
}

=func all_minimum_version_from_meta2_ok

  all_minimum_version_from_meta2_ok(\%arg);

This routine checks for F<META.json> first, and then F<META.yml>.
Then uses the revelent F<all_minimum_version_from_meta..._ok>.
If neither are found, all tests are skipped.
=cut


sub all_minimum_version_from_meta2_ok {
  my ($arg) = @_;
  $arg ||= {};

  if (-f 'META.json' and -r _ ) {
    all_minimum_version_from_metajson_ok($arg);
  }
  elsif (-f 'META.yml' and -r _) {
    all_minimum_version_from_metayml_ok($arg);
  }
  else {
    my $Test = Test::Builder->new;
    $Test->plan(skip_all => "no META files to be found");
  }
}

1;


use strict;
package Test::MinimumVersion;

=head1 NAME

Test::MinimumVersion - does your code require newer perl than you think?

=head1 VERSION

version 0.003

 $Id$

=cut

use vars qw($VERSION);
$VERSION = '0.003';

=head1 SYNOPSIS

B<Achtung!>

  This interface may change slightly over the next few weeks.
  -- rjbs, 2007-04-02

Example F<minimum-perl.t>:

  #!perl
  use Test::MinimumVersion;
  all_minimum_version_ok('5.008');

=cut

use File::Find::Rule;
use File::Find::Rule::Perl;
use Perl::MinimumVersion;
use version;

use Test::Builder;
require Exporter;
@Test::MinimumVersion::ISA = qw(Exporter);
@Test::MinimumVersion::EXPORT = qw(minimum_version_ok all_minimum_version_ok);

my $Test = Test::Builder->new;

sub import {
  my($self) = shift;
  my $pack = caller;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, @Test::MinimumVersion::EXPORT);
}

sub _objectify_version {
  my ($version) = @_;
  $version = eval { $version->isa('version') } 
           ? $version
           : version->new($version);
}

=head2 minimum_version_ok

  minimum_version_ok($file, $version);

This test passes if the given file does not seem to require any version of perl
newer than C<$version>, which may be given as a version string or a version
object.

=cut

sub minimum_version_ok {
  my ($file, $version) = @_;

  $version = _objectify_version($version);

  my $pmv = Perl::MinimumVersion->new($file);

  my $explicit_minimum = $pmv->minimum_explicit_version;
  my $minimum = $pmv->minimum_syntax_version($explicit_minimum);

  my $is_syntax = 1 if $minimum > $explicit_minimum;

  $minimum = $explicit_minimum if $explicit_minimum > $minimum;

  if (not defined $minimum) {
    $Test->ok(1, $file);
  } elsif ($minimum <= $version) {
    $Test->ok(1, $file);
  } else {
    $Test->ok(0, $file);
    $Test->diag(
      "$file requires $minimum "
      . ($is_syntax ? 'due to syntax' : 'due to explicit requirement')
    );
  }
}

=head2 all_minimum_version_ok

  all_minimum_version_ok($version, \%arg);

Given either a version string or a L<version> object, this routine produces a
test plan and tests each relevant file with C<minimum_version_ok>.

Relevant files are found by L<File::Find::Rule::Perl>.

C<\%arg> is optional.  Valid arguments are:

  paths - in what paths to look for files; defaults to (t, lib)
          if it contains files, they will be checked

=cut

sub all_minimum_version_ok {
  my ($version, $arg) = @_;
  $arg ||= {};
  $arg->{paths} ||= [ qw(lib t) ];

  $version = _objectify_version($version);

  my @perl_files;
  for my $path (@{ $arg->{paths} }) {
    if (-f $path) {
      push @perl_files, $path;
    } else {
      push @perl_files, File::Find::Rule->perl_file->in($path);
    }
  }

  $Test->plan(tests => scalar @perl_files);

  minimum_version_ok($_, $version) for @perl_files;
}

=head1 TODO

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ricardo SIGNES, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

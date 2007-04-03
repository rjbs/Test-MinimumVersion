
use strict;
package Test::MinimumVersion;

=head1 NAME

Test::MinimumVersion - does your code require newer perl than you think?

=head1 VERSION

version 0.001

 $Id$

=cut

use vars qw($VERSION);
$VERSION = '0.001';

=head1 SYNOPSIS

B<Achtung!>

  This interface may change slightly over the next few weeks.
  -- rjbs, 2007-04-02

Example F<minimum-perl.t>:

  #!perl
  use Test::More tests => 1;
  use Test::MinimumVersion;
  minimum_version_ok('5.008');

=cut

use File::Find::Rule;
use File::Find::Rule::Perl;
use Perl::MinimumVersion;
use version;

use Test::Builder;
require Exporter;
@Test::MinimumVersion::ISA = qw(Exporter);
@Test::MinimumVersion::EXPORT = qw(minimum_version_ok);

my $Test = Test::Builder->new;

sub import {
  my($self) = shift;
  my $pack = caller;

  $Test->exported_to($pack);
  $Test->plan(@_);

  $self->export_to_level(1, $self, 'minimum_version_ok');
}

=head2 minimum_version_ok

  minimum_version_ok($version);

Given either a version string or a L<version> object, this test passes if none
of the Perl files in F<t> or F<lib> require a newer perl.

Clearly this routine needs more configurability.

=cut

sub minimum_version_ok {
  my $version = shift;
  my $wanted_minimum = eval { $version->isa('version') } 
                     ? $version
                     : version->new($version);

  my @perl_files = File::Find::Rule->perl_file->in(qw(lib t));

  my @violations;

  for my $file (@perl_files) {
    my $pmv = Perl::MinimumVersion->new($file);

    next unless my $file_minimum = $pmv->minimum_version;

    if ($file_minimum > $wanted_minimum) {
      push @violations, [ $file, $file_minimum ];
    }
  }

  $Test->ok(
    !@violations,
    "no files require a version higher than $wanted_minimum"
  );
  $Test->diag(map { "$_->[0] requires version $_->[1]\n" } @violations);
}

=head1 TODO

=over

=item better docs

=item more params (like which dirs to check)

=item better output (like reason why)

=back

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ricardo SIGNES, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

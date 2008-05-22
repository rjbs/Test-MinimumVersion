use strict;
package Test::MinimumVersion;
require 5.005; # required by embedded YAML::Tiny

=head1 NAME

Test::MinimumVersion - does your code require newer perl than you think?

=head1 VERSION

version 0.007

=cut

use vars qw($VERSION);
$VERSION = '0.007';

=head1 SYNOPSIS

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
@Test::MinimumVersion::EXPORT = qw(
  minimum_version_ok
  all_minimum_version_ok
  all_minimum_version_from_metayml_ok
);

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

  my $is_syntax = 1
    if $minimum and $minimum > $explicit_minimum;

  $minimum = $explicit_minimum
    if $explicit_minimum and $explicit_minimum > $minimum;

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
  $arg->{paths} ||= [ qw(lib t xt/smoke), glob ("*.pm"), glob ("*.PL") ];

  $version = _objectify_version($version);

  my @perl_files;
  for my $path (@{ $arg->{paths} }) {
    if (-f $path) {
      push @perl_files, $path;
    } elsif (-d $path) {
      push @perl_files, File::Find::Rule->perl_file->in($path);
    }
  }

  unless ($Test->has_plan or $arg->{no_plan}) {
    $Test->plan(tests => scalar @perl_files);
  }

  minimum_version_ok($_, $version) for @perl_files;
}

=head2 all_minimum_version_from_metayml_ok

  all_minimum_version_from_metayml_ok(\%arg);

This routine checks F<META.yml> for an entry in F<requires> for F<perl>.  If no
META.yml file or no perl version is found, all tests are skipped.  If a version
is found, the test proceeds as if C<all_minimum_version_ok> had been called
with that version.

=cut

sub all_minimum_version_from_metayml_ok {
  my ($arg) = @_;
  $arg ||= {};

  $Test->plan(skip_all => "META.yml could not be found")
    unless -f 'META.yml' and -r _;

  my $documents = Test::MinimumVersion::YAMLTiny->read('META.yml');

  $Test->plan(skip_all => "no minimum perl version could be determined")
    unless my $version = $documents->[0]->{requires}{perl};

  all_minimum_version_ok($version, $arg);
}

=head1 TODO

Uh, this code has no tests.  I'm really sorry.  I'll get around to it.

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007, Ricardo SIGNES.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

### BEGIN EMBEDDED YAML::Tiny
package Test::MinimumVersion::YAMLTiny;
use strict;
BEGIN {
 require 5.004;
 $YAML::Tiny::VERSION = '1.32';
 $YAML::Tiny::errstr = '';
}
my $ESCAPE_CHAR = '[\\x00-\\x08\\x0b-\\x0d\\x0e-\\x1f\"\n]';
my @UNPRINTABLE = qw(
	z    x01  x02  x03  x04  x05  x06  a
	x08  t    n    v    f    r    x0e  x0f
	x10  x11  x12  x13  x14  x15  x16  x17
	x18  x19  x1a  e    x1c  x1d  x1e  x1f
);
my %UNESCAPES = (
 z => "\x00", a => "\x07", t => "\x09",
 n => "\x0a", v => "\x0b", f => "\x0c",
 r => "\x0d", e => "\x1b", '\\' => '\\',
);
sub new {
 my $class = shift;
 bless [ @_ ], $class;
}
sub read {
 my $class = ref $_[0] ? ref shift : shift;
 my $file = shift or return $class->_error( 'You did not specify a file name' );
 return $class->_error( "File '$file' does not exist" ) unless -e $file;
 return $class->_error( "'$file' is a directory, not a file" ) unless -f _;
 return $class->_error( "Insufficient permissions to read '$file'" ) unless -r _;
 local $/ = undef;
 local *CFG;
 unless ( open(CFG, $file) ) {
 return $class->_error( "Failed to open file '$file': $!" );
 }
 my $contents = <CFG>;
 unless ( close(CFG) ) {
 return $class->_error( "Failed to close file '$file': $!" );
 }

$class->read_string( $contents );
}
sub read_string {
 my $class = ref $_[0] ? ref shift : shift;
 my $self = bless [], $class;
 return undef unless defined $_[0];
 return $self unless length $_[0];
 unless ( $_[0] =~ /[\012\015]+$/ ) {
 return $class->_error("Stream does not end with newline character");
 }
 my @lines = grep { ! /^\s*(?:\#.*)?$/ }
 split /(?:\015{1,2}\012|\015|\012)/, shift;
 @lines and $lines[0] =~ /^\%YAML[: ][\d\.]+.*$/ and shift @lines;
 while ( @lines ) {
 if ( $lines[0] =~ /^---\s*(?:(.+)\s*)?$/ ) {
 shift @lines;
 if ( defined $1 and $1 !~ /^(?:\#.+|\%YAML[: ][\d\.]+)$/ ) {
 push @$self, $self->_read_scalar( "$1", [ undef ], \@lines );
 next;
 }
 }

if ( ! @lines or $lines[0] =~ /^(?:---|\.\.\.)/ ) {
 push @$self, undef;
 while ( @lines and $lines[0] !~ /^---/ ) {
 shift @lines;
 }

} elsif ( $lines[0] =~ /^\s*\-/ ) {
 my $document = [ ];
 push @$self, $document;
 $self->_read_array( $document, [ 0 ], \@lines );

} elsif ( $lines[0] =~ /^(\s*)\S/ ) {
 my $document = { };
 push @$self, $document;
 $self->_read_hash( $document, [ length($1) ], \@lines );

} else {
 die "YAML::Tiny does not support the line '$lines[0]'";
 }
 }

$self;
}
sub _read_scalar {
 my ($self, $string, $indent, $lines) = @_;
 $string =~ s/\s*$//;
 return undef if $string eq '~';
 if ( $string =~ /^\'(.*?)\'$/ ) {
 return '' unless defined $1;
 my $rv = $1;
 $rv =~ s/\'\'/\'/g;
 return $rv;
 }
 if ( $string =~ /^\"((?:\\.|[^\"])*)\"$/ ) {
 my $str = $1;
 $str =~ s/\\"/"/g;
 $str =~ s/\\([never\\fartz]|x([0-9a-fA-F]{2}))/(length($1)>1)?pack("H2",$2):$UNESCAPES{$1}/gex;
 return $str;
 }
 die "Unsupported YAML feature" if $string =~ /^['"!&]/;
 return {} if $string eq '{}';
 return [] if $string eq '[]';
 return $string unless $string =~ /^[>|]/;
 die "Multi-line scalar content missing" unless @$lines;
 $lines->[0] =~ /^(\s*)/;
 $indent->[-1] = length("$1");
 if ( defined $indent->[-2] and $indent->[-1] <= $indent->[-2] ) {
 die "Illegal line indenting";
 }
 my @multiline = ();
 while ( @$lines ) {
 $lines->[0] =~ /^(\s*)/;
 last unless length($1) >= $indent->[-1];
 push @multiline, substr(shift(@$lines), length($1));
 }

my $j = (substr($string, 0, 1) eq '>') ? ' ' : "\n";
 my $t = (substr($string, 1, 1) eq '-') ? '' : "\n";
 return join( $j, @multiline ) . $t;
}
sub _read_array {
 my ($self, $array, $indent, $lines) = @_;

while ( @$lines ) {
 if ( $lines->[0] =~ /^(?:---|\.\.\.)/ ) {
 while ( @$lines and $lines->[0] !~ /^---/ ) {
 shift @$lines;
 }
 return 1;
 }
 $lines->[0] =~ /^(\s*)/;
 if ( length($1) < $indent->[-1] ) {
 return 1;
 } elsif ( length($1) > $indent->[-1] ) {
 die "Hash line over-indented";
 }

if ( $lines->[0] =~ /^(\s*\-\s+)[^\'\"]\S*\s*:(?:\s+|$)/ ) {
 my $indent2 = length("$1");
 $lines->[0] =~ s/-/ /;
 push @$array, { };
 $self->_read_hash( $array->[-1], [ @$indent, $indent2 ], $lines );

} elsif ( $lines->[0] =~ /^\s*\-(\s*)(.+?)\s*$/ ) {
 shift @$lines;
 push @$array, $self->_read_scalar( "$2", [ @$indent, undef ], $lines );

} elsif ( $lines->[0] =~ /^\s*\-\s*$/ ) {
 shift @$lines;
 unless ( @$lines ) {
 push @$array, undef;
 return 1;
 }
 if ( $lines->[0] =~ /^(\s*)\-/ ) {
 my $indent2 = length("$1");
 if ( $indent->[-1] == $indent2 ) {
 push @$array, undef;
 } else {
 push @$array, [ ];
 $self->_read_array( $array->[-1], [ @$indent, $indent2 ], $lines );
 }

} elsif ( $lines->[0] =~ /^(\s*)\S/ ) {
 push @$array, { };
 $self->_read_hash( $array->[-1], [ @$indent, length("$1") ], $lines );

} else {
 die "YAML::Tiny does not support the line '$lines->[0]'";
 }

} else {
 die "YAML::Tiny does not support the line '$lines->[0]'";
 }
 }

return 1;
}
sub _read_hash {
 my ($self, $hash, $indent, $lines) = @_;

while ( @$lines ) {
 if ( $lines->[0] =~ /^(?:---|\.\.\.)/ ) {
 while ( @$lines and $lines->[0] !~ /^---/ ) {
 shift @$lines;
 }
 return 1;
 }
 $lines->[0] =~ /^(\s*)/;
 if ( length($1) < $indent->[-1] ) {
 return 1;
 } elsif ( length($1) > $indent->[-1] ) {
 die "Hash line over-indented";
 }
 unless ( $lines->[0] =~ s/^\s*([^\'\" ][^\n]*?)\s*:(\s+|$)// ) {
 die "Unsupported YAML feature" if $lines->[0] =~ /^\s*[?'"]/;
 die "Bad or unsupported hash line";
 }
 my $key = $1;
 if ( length $lines->[0] ) {
 $hash->{$key} = $self->_read_scalar( shift(@$lines), [ @$indent, undef ], $lines );
 } else {
 shift @$lines;
 unless ( @$lines ) {
 $hash->{$key} = undef;
 return 1;
 }
 if ( $lines->[0] =~ /^(\s*)-/ ) {
 $hash->{$key} = [];
 $self->_read_array( $hash->{$key}, [ @$indent, length($1) ], $lines );
 } elsif ( $lines->[0] =~ /^(\s*)./ ) {
 my $indent2 = length("$1");
 if ( $indent->[-1] >= $indent2 ) {
 $hash->{$key} = undef;
 } else {
 $hash->{$key} = {};
 $self->_read_hash( $hash->{$key}, [ @$indent, length($1) ], $lines );
 }
 }
 }
 }

return 1;
}
sub write {
 my $self = shift;
 my $file = shift or return $self->_error(
 'No file name provided'
 );
 open( CFG, '>' . $file ) or return $self->_error(
 "Failed to open file '$file' for writing: $!"
 );
 print CFG $self->write_string;
 close CFG;

return 1;
}
sub write_string {
 my $self = shift;
 return '' unless @$self;
 my $indent = 0;
 my @lines = ();
 foreach my $cursor ( @$self ) {
 push @lines, '---';
 if ( ! defined $cursor ) {
 } elsif ( ! ref $cursor ) {
 $lines[-1] .= ' ' . $self->_write_scalar( $cursor );
 } elsif ( ref $cursor eq 'ARRAY' ) {
 unless ( @$cursor ) {
 $lines[-1] .= ' []';
 next;
 }
 push @lines, $self->_write_array( $cursor, $indent, {} );
 } elsif ( ref $cursor eq 'HASH' ) {
 unless ( %$cursor ) {
 $lines[-1] .= ' {}';
 next;
 }
 push @lines, $self->_write_hash( $cursor, $indent, {} );

} else {
 Carp::croak("Cannot serialize " . ref($cursor));
 }
 }

join '', map { "$_\n" } @lines;
}
sub _write_scalar {
 my $str = $_[1];
 return '~' unless defined $str;
 if ( $str =~ /$ESCAPE_CHAR/ ) {
 $str =~ s/\\/\\\\/g;
 $str =~ s/"/\\"/g;
 $str =~ s/\n/\\n/g;
 $str =~ s/([\x00-\x1f])/\\$UNPRINTABLE[ord($1)]/g;
 return qq{"$str"};
 }
 if ( length($str) == 0 or $str =~ /(?:^\W|\s)/ ) {
 $str =~ s/\'/\'\'/;
 return "'$str'";
 }
 return $str;
}
sub _write_array {
 my ($self, $array, $indent, $seen) = @_;
 if ( $seen->{refaddr($array)}++ ) {
 die "YAML::Tiny does not support circular references";
 }
 my @lines = ();
 foreach my $el ( @$array ) {
 my $line = ('  ' x $indent) . '-';
 my $type = ref $el;
 if ( ! $type ) {
 $line .= ' ' . $self->_write_scalar( $el );
 push @lines, $line;

} elsif ( $type eq 'ARRAY' ) {
 if ( @$el ) {
 push @lines, $line;
 push @lines, $self->_write_array( $el, $indent + 1, $seen );
 } else {
 $line .= ' []';
 push @lines, $line;
 }

} elsif ( $type eq 'HASH' ) {
 if ( keys %$el ) {
 push @lines, $line;
 push @lines, $self->_write_hash( $el, $indent + 1, $seen );
 } else {
 $line .= ' {}';
 push @lines, $line;
 }

} else {
 die "YAML::Tiny does not support $type references";
 }
 }

@lines;
}
sub _write_hash {
 my ($self, $hash, $indent, $seen) = @_;
 if ( $seen->{refaddr($hash)}++ ) {
 die "YAML::Tiny does not support circular references";
 }
 my @lines = ();
 foreach my $name ( sort keys %$hash ) {
 my $el = $hash->{$name};
 my $line = ('  ' x $indent) . "$name:";
 my $type = ref $el;
 if ( ! $type ) {
 $line .= ' ' . $self->_write_scalar( $el );
 push @lines, $line;

} elsif ( $type eq 'ARRAY' ) {
 if ( @$el ) {
 push @lines, $line;
 push @lines, $self->_write_array( $el, $indent + 1, $seen );
 } else {
 $line .= ' []';
 push @lines, $line;
 }

} elsif ( $type eq 'HASH' ) {
 if ( keys %$el ) {
 push @lines, $line;
 push @lines, $self->_write_hash( $el, $indent + 1, $seen );
 } else {
 $line .= ' {}';
 push @lines, $line;
 }

} else {
 die "YAML::Tiny does not support $type references";
 }
 }

@lines;
}
sub _error {
 $YAML::Tiny::errstr = $_[1];
 undef;
}
sub errstr {
 $YAML::Tiny::errstr;
}
sub Dump {
 YAML::Tiny->new(@_)->write_string;
}
sub Load {
 my $self = YAML::Tiny->read_string(@_)
 or Carp::croak("Failed to load YAML document from string");
 if ( wantarray ) {
 return @$self;
 } else {
 return $self->[-1];
 }
}
BEGIN {
 *freeze = *Dump;
 *thaw = *Load;
}
sub DumpFile {
 my $file = shift;
 YAML::Tiny->new(@_)->write($file);
}
sub LoadFile {
 my $self = YAML::Tiny->read($_[0])
 or Carp::croak("Failed to load YAML document from '" . ($_[0] || '') . "'");
 if ( wantarray ) {
 return @$self;
 } else {
 return $self->[-1];
 }
}
BEGIN {
 eval {
 require Scalar::Util;
 };
 if ( $@ ) {
 eval <<'END_PERL';
sub refaddr {
  my $pkg = ref($_[0]) or return undef;
  if (!!UNIVERSAL::can($_[0], 'can')) {
    bless $_[0], 'Scalar::Util::Fake';
  } else {
    $pkg = undef;
  }
  "$_[0]" =~ /0x(\w+)/;
  my $i = do { local $^W; hex $1 };
  bless $_[0], $pkg if defined $pkg;
  $i;
}
END_PERL
 } else {
 Scalar::Util->import('refaddr');
 }
}
1;
### END EMBEDDED YAML::Tiny

1;

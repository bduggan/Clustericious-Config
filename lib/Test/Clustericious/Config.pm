package Test::Clustericious::Config;

use strict;
use warnings;
use v5.10;
use File::HomeDir::Test;
use File::HomeDir;
use YAML::XS qw( DumpFile );
use File::Path qw( mkpath );
use Clustericious::Config;

use base qw( Test::Builder::Module Exporter );

our @EXPORT = qw( create_config_ok create_directory_ok home_directory_ok );
our @EXPORT_OK = @EXPORT;
our $VERSION = '0.16';

my $config_dir = File::HomeDir->my_home . "/etc";
mkdir $config_dir;

$ENV{CLUSTERICIOUS_CONF_DIR} = $config_dir;
Clustericious::Config->_testing(1);

=head1 NAME

Test::Clustericious::Config - Test Clustericious::Config

=head1 SYNOPSIS

 use Test::Clustericious::Config;
 
 create_config_ok 'Foo', { url => 'http://localhost:1234' };

=head1 DESCRIPTION

This module provides an interface for testing Clustericious
configurations, or Clustericious applications which use
a Clustericious configuration.

It uses L<File::HomeDir::Test> to isolate your test environment
from any configurations you may have in your C<~/etc>.  Keep
in mind that this means that C<$HOME> and friends will be in
a temporary directory and removed after the test runs.  It also
means that the caveats for L<File::HomeDir::Test> apply when
using this module as well (ie. this should be the first module
that you use in your test after C<use strict> and C<use warnings>).

=head1 FUNCTIONS

=head2 create_config_ok $name, $config, [$test_name]

Create a Clustericious config with the given C<$name>.
If C<$config> is a reference then it will create the 
configuration file with C<YAML::XS::DumpFile>, if
it is a scalar, it will will write the scalar out
to the config file.  Thus these three examples should
create a config with the same values (though in different
formats):

hash reference:

 create_config_ok 'Foo', { url => 'http://localhost:1234' }];

YAML:

 create_config_ok 'Foo', <<EOF;
 ---
 url: http://localhost:1234
 EOF

JSON:

 create_config_ok 'Foo', <<EOF;
 {"url":"http://localhost:1234"}
 EOF

In addition to being a test that will produce a ok/not ok
result as output, this function will return the full path
to the configuration file created.

=cut

sub create_config_ok
{
  my($config_name, $config, $test_name) = @_;
  
  my $config_filename = "$config_dir/$config_name.conf";
  
  eval {
    if(ref $config)
    {
      DumpFile($config_filename, $config);
    }
    else
    {
      open my $fh, '>', $config_filename;
      print $fh $config;
      close $fh;
    }
  };
  my $error = $@;
  
  $test_name //= "create config for $config_name at $config_filename";
  
  my $tb = __PACKAGE__->builder;  
  $tb->ok($error eq '', $test_name);
  $tb->diag("exception: $error") if $error;
  return $config_filename;
}

=head2 create_directory_ok $path, [$test_name]

Creates a directory in your test environment home directory.
This directory will be recursively removed when your test
terminates.  This function returns the full path of the 
directory created.

=cut

sub create_directory_ok
{
  my($path, $test_name) = @_;
  
  my $fullpath = $path;
  $fullpath =~ s{^/}{};
  $fullpath = join('/', File::HomeDir->my_home, $fullpath);
  mkpath $fullpath, 0, 0700;
  
  $test_name //= "create directory $fullpath";
  
  my $tb = __PACKAGE__->builder;
  $tb->ok(-d $fullpath, $test_name);
  return $fullpath;
}

=head2 home_directory_ok [$test_name]

Tests that the temp homedirectory has been created okay.
Returns the full path of the home directory.

=cut

sub home_directory_ok
{
  my($test_name) = @_;
  
  my $fullpath = File::HomeDir->my_home;
  
  $test_name //= "home directory $fullpath";
  
  my $tb = __PACKAGE__->builder;
  $tb->ok(-d $fullpath, $test_name);
  return $fullpath;
}

1;

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 SEE ALSO

=over 4

=item *

L<Clustericious::Config>

=item *

L<Clustericious>

=back

=cut
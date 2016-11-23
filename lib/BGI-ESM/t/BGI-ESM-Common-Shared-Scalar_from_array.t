
=head1 NAME

Test module for BGI ESM Common Shared scalar_from_array

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::Shared scalar_from_array method

=head1 REVISIONS

CVS Revsion: $Revision: 1.1 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2009-02-28   nichj   Developing 
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:
	
=cut

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
use Carp;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;

my @subs = qw(
    scalar_from_array
 );

BEGIN { use_ok('BGI::ESM::Common::Shared', @subs); };

#########################

can_ok( __PACKAGE__, 'scalar_from_array');

SCALAR_FROM_ARRAY:
{
my $expected_scalar = "1;2;3;4";
my @array_to_munge = ( "1", "2", "3", "4");
my $sep = ";";
my $new_val = scalar_from_array(\@array_to_munge, $sep);

is ($expected_scalar, $new_val, "scalar_from_array will take the values from an array and merge them into scalar.");

print "Expected: $expected_scalar\n";
print "Received: $new_val\n";
}


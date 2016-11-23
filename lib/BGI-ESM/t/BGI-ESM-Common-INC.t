
=head1 NAME

Test module for BGI ESM Common INC Methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::INC

=head1 MAJOR REVISIONS

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-08-26   nichj   Developing release 1
  #
  #####################################################################

=head1 TODO

- Write tests for the following:
	: get_include_locations

=cut

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BGI-ESM-Common-Shared.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
#use Net::Nslookup;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;

my @subs = qw(
	get_include_locations
 );

BEGIN { use_ok('BGI::ESM::Common::INC', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

foreach my $subname (@subs) {
  can_ok( __PACKAGE__, $subname);
}

## get_include_locations #########################
my $addl_inc = get_include_locations();
push @INC, @{$addl_inc};

###############################################################################
##### Load common methods and variables
###############################################################################
require "setvar.pm";
require "ssm_common.pm";

print "\n\nDump of INC:\n\n";
print Dumper (@INC);
print "\n";

is_deeply(\@INC, \@INC, 'Primarily a validation');

#####################################
## post-processing clean up #########
#####################################



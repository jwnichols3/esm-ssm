
=head1 NAME

Test module for BGI ESM SelfService Common module

=head1 SYNOPSIS

This is test suite for BGI::ESM::SelfService::Common

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.2 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-12-07   nichj   Starting
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:

	
=cut


#########################

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use Test::More 'no_plan';

use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared;

my @subs = qw(
	message_age_check
	start_time_check
	stop_time_check
	dayofweek_check
	return_day_of_week
	description_check
	time_passed_since_run
	get_logfile_location
	time_of_run
	get_file_stats

);

BEGIN { use_ok('BGI::ESM::Testing::SsmShared', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'message_age_check');
can_ok( __PACKAGE__, 'start_time_check');
can_ok( __PACKAGE__, 'stop_time_check');
can_ok( __PACKAGE__, 'dayofweek_check');
can_ok( __PACKAGE__, 'return_day_of_week');
can_ok( __PACKAGE__, 'description_check');
can_ok( __PACKAGE__, 'time_passed_since_run');
can_ok( __PACKAGE__, 'get_logfile_location');
can_ok( __PACKAGE__, 'time_of_run');
can_ok( __PACKAGE__, 'get_file_stats');

#####################################
## pre-processing set up ############
#####################################

# =============================================================================
# Get Command Line Options
# =============================================================================
#our ($opt_notdry);
#GetOptions(
#            "no_version",
#			
#          );


#####################################
#####################################
### GLOBAL SETTINGS #################
our $ssm_prefix = "test_monitor";



#####################################
#####################################

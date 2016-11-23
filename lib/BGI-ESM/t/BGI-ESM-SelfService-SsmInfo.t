
=head1 NAME

Test module for BGI ESM Self Service Information methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::SelfService::SsmInfo

=head1 REVISIONS

CVS Revision: $Revision: 1.1 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-09-23   nichj   Developing release
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:
	: 
	
=cut

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os);

##################################################
##################################################
#our ($opt_agent_test);
#GetOptions(
#            "agent_test"
#          );

##################################################
##################################################
my @subs = qw(
	get_exe_list
	ssm_program_versions
);

BEGIN { use_ok('BGI::ESM::SelfService::SsmInfo', @subs); };

##################################################
##################################################

can_ok( __PACKAGE__, 'get_exe_list'     );


##################################################
##################################################
GET_EXE_LIST:
{
	print "\nVariable list based on current os: " . os_type() . "\n\n";
	
	my $exe_list = get_exe_list();
	
	print Dumper ($exe_list);
	
	my $exe_list_win = get_exe_list('WINDOWS');
	my $exe_list_sol = get_exe_list('UNIX');
	
	print "\nVariable list based on WINDOWS\n\n";
	print Dumper ($exe_list_win);
	print "\nVariable list based on UNIX\n\n";
	print Dumper ($exe_list_sol);
}

##################################################
##################################################
SSM_PROGRAM_VERSIONS:
{
	print "\nSSM Program Versions\n\n";
	our $program_version = ssm_program_versions();
	
	print Dumper ($program_version);
}

##################################################
## post-processing clean up ######################
##################################################



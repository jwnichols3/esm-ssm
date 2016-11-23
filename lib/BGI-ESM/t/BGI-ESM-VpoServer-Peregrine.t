#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME



=head1 SYNOPSIS



=head1 REVISIONS

CVS Revision: $Revision: 1.1 $

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

	
=cut

##############################################################################
### Module Use Section #######################################################
use warnings;
use strict;
use Data::Dumper;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm

##############################################################################
my @subs = qw(
	peregrine_working
	create_ticket
	get_scauto_program_cmd
	get_peregrine_working_flag
 );

BEGIN { use_ok('BGI::ESM::VpoServer::Peregrine', @subs); };

##############################################################################

can_ok( __PACKAGE__, 'peregrine_working');
can_ok( __PACKAGE__, 'create_ticket');
can_ok( __PACKAGE__, 'get_scauto_program_cmd');
can_ok( __PACKAGE__, 'get_peregrine_working_flag');

###############################################################################
##### Load common methods and variables
###############################################################################


###############################################################################
##### Testing Section
###############################################################################

#########################
#########################
MODULE_NAME:
{
	
	my $status;
	
}

###############################################################################
##### post-processing clean up 
###############################################################################



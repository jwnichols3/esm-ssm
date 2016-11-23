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
    looking_glass_new_vpo_event
    lg_get_db_structure
    lg_open_db
    lg_close_db
    lg_merge_records
    lg_add_record
    lg_update_record
    lg_get_record
    lg_print_all_record_keys
    lg_print_xref_all
    lg_print_xref
    lg_print_record
    lg_print_csv_all
    lg_print_csv
    lg_delete_record
    lg_vpo_to_lg
    lg_log
 );

BEGIN { use_ok('BGI::ESM::VpoServer::LookingGlass', @subs); };

##############################################################################

can_ok( __PACKAGE__, 'looking_glass_new_vpo_event');
can_ok( __PACKAGE__, 'lg_get_db_structure');
can_ok( __PACKAGE__, 'lg_open_db');
can_ok( __PACKAGE__, 'lg_close_db');
can_ok( __PACKAGE__, 'lg_merge_records');
can_ok( __PACKAGE__, 'lg_add_record');
can_ok( __PACKAGE__, 'lg_update_record');
can_ok( __PACKAGE__, 'lg_get_record');
can_ok( __PACKAGE__, 'lg_print_all_record_keys');
can_ok( __PACKAGE__, 'lg_print_xref_all');
can_ok( __PACKAGE__, 'lg_print_xref');
can_ok( __PACKAGE__, 'lg_print_record');
can_ok( __PACKAGE__, 'lg_print_csv_all');
can_ok( __PACKAGE__, 'lg_print_csv');
can_ok( __PACKAGE__, 'lg_delete_record');
can_ok( __PACKAGE__, 'lg_vpo_to_lg');
can_ok( __PACKAGE__, 'lg_log');

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



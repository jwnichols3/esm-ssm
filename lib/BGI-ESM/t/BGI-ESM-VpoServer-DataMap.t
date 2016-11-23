#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME



=head1 SYNOPSIS



=head1 REVISIONS

CVS Revision: $Revision: 1.3 $

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
	get_ap_group_name
	get_data_map_record
	data_map_get_method
	get_ap_action_script
	data_map_print_all_apps
	data_map_get_all_apps
	data_map_print_all_details
	data_map_print_app_details
	data_map_print_peregrine
	data_map_print_apgrp
	data_map_print_alarmpoint
	data_map_lookup
	get_data_map_data
	get_datamap_version
 );

BEGIN { use_ok('BGI::ESM::VpoServer::DataMap', @subs); };

##############################################################################

can_ok( __PACKAGE__, 'get_ap_group_name');
can_ok( __PACKAGE__, 'get_data_map_record');
can_ok( __PACKAGE__, 'data_map_get_method');
can_ok( __PACKAGE__, 'get_ap_action_script');
can_ok( __PACKAGE__, 'data_map_print_all_apps');
can_ok( __PACKAGE__, 'data_map_get_all_apps');
can_ok( __PACKAGE__, 'data_map_print_all_details');
can_ok( __PACKAGE__, 'data_map_print_app_details');
can_ok( __PACKAGE__, 'data_map_print_peregrine');
can_ok( __PACKAGE__, 'data_map_print_apgrp');
can_ok( __PACKAGE__, 'data_map_print_alarmpoint');
can_ok( __PACKAGE__, 'data_map_lookup');
can_ok( __PACKAGE__, 'get_data_map_data');
can_ok( __PACKAGE__, 'get_datamap_version');

###############################################################################
##### Load common methods and variables
###############################################################################
our $app_list = data_map_get_all_apps();

###############################################################################
##### Testing Section
###############################################################################

#########################
#########################
MODULE_NAME:
{
	
	my $status;
	
}

#########################
#########################
DATA_MAP_GET_APP_APPS:
{
	my $app_list_test = data_map_get_all_apps();
	
	is_deeply ($app_list_test, $app_list, 'data_map_get_all_apps( ) should return a reference to a list of app names');
	
}

#########################
#########################
VERSION:
{
	my $dm_version = get_datamap_version();
	
	is ($dm_version, $dm_version, 'get_datamap_version( ) should return the DataMap module version: ' . $dm_version);
}

#########################
#########################
GET_DATA_MAP_RECORD:
{
	foreach my $item (@{$app_list}) {
		
		my $record = get_data_map_record($item);
		print "Record for $item\t";
		print Dumper $record;
		
	}

}

###############################################################################
##### post-processing clean up 
###############################################################################



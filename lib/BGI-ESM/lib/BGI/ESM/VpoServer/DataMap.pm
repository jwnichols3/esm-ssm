=c
head1 TITLE

BGI::ESM::VpoServer::DataMap

=head1 DESCRIPTION

Has methods around the data mapping interface between VPO, Peregrine, and AP

=head1 USAGE

use BGI::ESM::VpoServer::DataMap

=head1 TODO



=head1 REVISIONS

CVS Revision: $Revision: 1.139 $

    #####################################################################
    #  2005-10-05 - nichj - Migrated to Perl Module
    #  2005-11-16 - nichj - added gmd_europe_mi
    #  2006-03-25 - nichj - updated End to End group
    #  2006-03-31 - nichj - updated ESM mapping
    #  2006-05-09 - nichj - Added Oracle mapping
    #####################################################################
 
=cut

##############################################################################
### Package Name #############################################################
package BGI::ESM::VpoServer::DataMap;
##############################################################################

##############################################################################
### Module Use Section #######################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os);
##############################################################################

##############################################################################
### Require Section ##########################################################
require Exporter;
##############################################################################

##############################################################################
### Who is this ##############################################################
our @ISA = qw(Exporter BGI::ESM::VpoServer);
##############################################################################

##############################################################################
### Public Exports ###########################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
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
##############################################################################

##############################################################################
### VERSION ##################################################################
my $VERSION = (qw$Revision: 1.139 $)[-1];
##############################################################################

##############################################################################
# Public Variables
##############################################################################

##############################################################################
# Public Methods / Functions
##############################################################################

=head2 get_datamap_version()
	returns version of DataMap module
=cut

sub get_datamap_version {
	return $VERSION;
}

=head2 Function: get_ap_group_name($message_group)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     get_ap_group_name($message_group)
	#
	# Description:  Uses a hash table to lookup the incoming message group's
	#                corresponding Alarmpoint group.  Returns the group name.
	#                If not found, returns esm.
	#
	# Returns:      The corresponding alarmpoint group in scalar format
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub get_ap_group_name {
	my $message_group = shift;
	my $retval        = "";
	my $data_map;
	
	#my $logfile       = "$PGM_LOGS/data_map.log";
	#
	#if ($debug)                                                        { open DM_LOGFILE, ">> $logfile"; }
	
	$data_map = get_data_map_data();

	## Populating message_group
	##
	$retval = $data_map->{$message_group}->{'ap_group'};
	
	if ($retval eq "") {
		#Changed not to default to esm if no group found
		#$retval = "esm";
		$retval = "no_mapped_group";
	} 

	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: get_data_map_record($message_group)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     get_data_map_record($message_group)
	#
	# Description:  Loads the data map hash, looks up the hash associated with $message_group and returns a reference to that hash
	#
	# Returns:      A hash reference to the hash array associated with $message_group
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub get_data_map_record {
	my $message_group = shift;
	my $retval        = "";
	my $data_map;
	
	$data_map = get_data_map_data();

	## Populating message_group
	##
	$retval = $data_map->{$message_group};
	
	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: data_map_get_method($message_group)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     data_map_get_method($message_group)
	#
	# Description:  Loads the data map hash, looks up the hash associated with $message_group and returns the method
	#
	# Returns:      the alert method (usually ticket, alarmpoint_only, or something similar).
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub data_map_get_method {
	my $message_group = shift;
	my $retval        = "";
	my $data_map;
	
	$data_map = get_data_map_data();

	## Populating method
	##
	$retval = $data_map->{$message_group}->{'method'};
	
	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: get_ap_action_script($message_group)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     get_ap_action_script($message_group)
	#
	# Description:  Uses a hash table to lookup the incoming message group's
	#                corresponding Alarmpoint action script.  Returns the action script name.
	#                If not found, returns the default: BGI On-Call.
	#
	# Returns:      The corresponding alarmpoint action script in scalar format
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub get_ap_action_script {
	my $message_group = shift;
	   $message_group = lc $message_group;
	my $retval        = "";
	
	my $data_map = get_data_map_data();

	$retval = $data_map->{$message_group}->{'ap_script'};
	
	if ($retval eq "") {
				$retval = "BGI On-Call";
	} 

	return $retval;


}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: data_map_print_all_apps

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     data_map_print_all_apps
	#
	# Description:  
	#
	# Returns:      
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub data_map_print_all_apps {
	my $retval        = 1;
	
	my $data_list = data_map_get_all_apps();

	foreach my $item (@{$data_list}) {
	  
	  print "$item\n";
  
	}

	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: data_map_get_all_apps

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     data_map_get_all_apps
	#
	# Description:  Gets all applications
	#
	# Returns:      An array reference to all applications
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub data_map_get_all_apps {
	my @retval        = ();
	
	my $data_map = get_data_map_data();

	foreach my $key (sort keys %{$data_map}) {
	  
	  push @retval, $key;
  
	}

	return \@retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 Function: data_map_print_all_details

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     
	#
	# Description:  
	#
	# Returns:      
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub data_map_print_all_details {
	my $retval        = 1;
	
	my $data_map = get_data_map_data();

  foreach my $key (sort keys %{$data_map}) {
    my $record = get_data_map_record($key);
  
    print "$key\n";
  
    foreach my $reckey (keys %{$record}) {
      print "\t". $reckey . "=" . $data_map->{$key}->{$reckey} . "\n";
    }
  }

	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: data_map_print_app_details

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     
	#
	# Description:  
	#
	# Returns:      
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub data_map_print_app_details {
	my $message_group = shift;
	   $message_group = trim($message_group);
	my $retval        = 1;

	my $data_map = get_data_map_data();
	
  my $record = get_data_map_record($message_group);

  print $record . "\n";
  
  foreach my $reckey (sort keys %{$record}) {
      print "\t". $reckey . " == " . $data_map->{$message_group}->{$reckey} . "\n";
  }

	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: data_map_print_peregrine

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     data_map_print_peregrine
	#
	# Description:  
	#
	# Returns:      
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub data_map_print_peregrine {
	my $message_group = shift;
	   $message_group = trim($message_group);
	my $retval        = 1;
	
	my $data_map = get_data_map_data();

  my $record = get_data_map_record($message_group);

  foreach my $reckey (sort keys %{$record}) {
    if ($reckey =~ m/^p_/) {
      print "\t". $reckey . " == " . $data_map->{$message_group}->{$reckey} . "\n";
    }
  }

	return $retval;


}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: data_map_print_apgrp

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     data_map_print_apgrp
	#
	# Description:  prints the associated alarmpoint group name
	#
	# Returns:      
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub data_map_print_apgrp {
	my $message_group = shift;
	   $message_group = trim($message_group);
	my $retval        = 1;
	
	my $data_map = get_data_map_data();

  print get_ap_group_name($message_group) . "\n";

	return $retval;


}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: data_map_print_alarmpoint($application)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     data_map_print_alarmpoint($application)
	#
	# Description:  prints the associated alarmpoint information
	#
	# Returns:      
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub data_map_print_alarmpoint {
	my $message_group = shift;
	   $message_group = trim($message_group);
	my $retval        = 1;
	
	my $data_map = get_data_map_data();

  my $record = get_data_map_record($message_group);

  foreach my $reckey (sort keys %{$record}) {
    if ($reckey =~ m/^ap_/) {
      print "\t". $reckey . " == " . $data_map->{$message_group}->{$reckey} . "\n";
    }
  }

	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 Function: data_map_lookup($search_string, $field)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     data_map_lookup($search_string, $field)
	#
	# Description:  search for $search_string in $field
	#
	# Returns:      reference to hash with results in the format of the data_map
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub data_map_lookup {
	my $search_string = shift;
	   $search_string = trim($search_string);
	my $field_name    = shift;
	my $data_map      = get_data_map_data();
	my ($retval, $record);

	## Add logic

	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

#################################################################################################
#################################################################################################
###############                          THE DATA MAP                 ###########################
#################################################################################################
#################################################################################################
=head2 Function: get_data_map_data()

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     get_data_map_data
	#
	# Description:  Holds the hash table with the data map information.
	#
	# Returns:      A reference to a hash with the data map
	#
	# Requires:     N/A
	#
	# -------------------------------------------------------------------

=cut

sub get_data_map_data {
	my $data_map;

	$data_map = {
		'ade' 						 => { 
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ACTIVE-DATA", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL" 
										  },
		'ae-fi-infa' 						 => { 
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-AE-FI-INFA", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL" 
										  },
		'administration'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-administration", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ais_inception'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'alarmpoint'									 => {
											'method'     => "ticket",
											'ap_group'   => "ESM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'amsx'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'amsx_load'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ap1'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'apex'													 => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-APEX", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'appdesk'													 => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KMIT-SYSTEM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_canotice'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_client'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_clientorder'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_execution'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_fxrate'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_generic'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_loanquote'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_rrr'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_unitprice'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'aria_jap_onloanreport'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'art'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ascot'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ascot", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'asi'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'asm'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'autos'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-AUTOSYS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'autosys'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-AUTOSYS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bac_staging'							 => {
											'method'     => "ticket",
											'ap_group'   => "BAC-STAGING", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'barclaysglobal'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CAST", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bep'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-BEP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'betax'									 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-BETAX", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bg-aria'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-bg-aria", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "MQSERIES",
											'p_problem'  => "FAULT-ARIA",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bg_aus'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-bg_aus", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "MQSERIES",
											'p_problem'  => "FAULT-AUSTRALIA",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bg_can'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-bg_can", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "MQSERIES",
											'p_problem'  => "FAULT-CANADA",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bgicash'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-bgicash", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bgicashfunds'								 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-bgicashfunds", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "BGICASHFUNDS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bgiconnect_aus'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-BGICONNECT AUS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "BGICONNECT AUS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bgifunds'										 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-bgifunds.com", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "BGIFUNDS.COM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bgis_uk'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-bgis_uk", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bgis_uk_qa'									 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-bgis-uk_qa", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bgis_uk_dev'									 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-orbis-uk_dev", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bgis_us'									 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-BGIS-US", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bidbook'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-bidbook", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "BID BOOK",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bip'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CAST", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bloomberg_recon'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KM IT Production Services", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'blk_unix'			                   => {
											'method'     => "ticket",
											'ap_group'   => "BLK-UNIX", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bms'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-bms", 
											'ap_script'  => "BGI VPO",
											'p_category' => "FACILITIES",
											'p_subcat'   => "HVAC",
											'p_product'  => "HVAC",
											'p_problem'  => "REPAIR",
											'p_asg_grp'  => "", 
											'p_location' => "RAC1"
										  },
		'calypso'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CALYPSO", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'cem'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-cem", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'cipit'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CIPIT", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'client_applications'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'cncrt'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT-SOLUTIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'com'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GOT-FTS-COM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ORDERS ONLINE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'compact'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-compact", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "COMPACT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'concert'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-concert", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CONCERT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'cp_ms_uk'										 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-cp_ms_uk", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CP_MS_UK",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'cpdl'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "COMMON PLATFORM DATA LOADER",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'cpdl_jp'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-CPDL_JP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'cr_uk'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-cr_uk", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TBD APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'crs'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'crm'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-crs", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CRM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'csds'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CSDATASERVICE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE", 
											'p_subcat'   => "SOFTWARE", 
											'p_product'  => "CSDS",
											'p_problem'  => "FAULT", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'csm'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'dbssi'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'delta_uk'										 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-delta_uk", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "DELTA_UK",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'desktop_antivirus'								 => {
											'method'     => "ticket",
											'ap_group'   => "Tech Team-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ANTIVIRUS",
											'p_problem'  => "REPAIR",
											'p_asg_grp'  => "TECH TEAM-FTS", 
											'p_location' => "GLOBAL"
										  },
		'dev_rpt'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'devicequery'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'devnet'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-devnet", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "DEVNET",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'documentum'									 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-documentum", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "DOCUMENTUM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'dynamo'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-dynamo", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ATG DYNAMO",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'easus'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GOT-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GOT-FTS-SUPPORT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'easjp'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ITGOTJP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "IT GOT JP",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'eas_europe'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-EAS-EUROPE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GOT-FTS-SUPPORT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'eat'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'emc_alarms'									 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-emc_alarms", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'equilend'										 => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-EQUILEND", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'equilend_b'									 => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-equilend_b", 
											'ap_script'  => "BGI Equilend",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'esmdc'													 => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-DECISIONCENTER", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'esm'													 => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "ESM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'esm-notify'                   => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "z_ESM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'eshed_uk'                     => {
											'method'     => "ticket",
											'ap_group'   => "", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TBD APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'etf'			 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-etf", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ETF",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'etfuk-business'			 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ETF-BUSINESS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ETF",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'etf_systems'		 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ETF-SYSTEMS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ETF SYSTEMS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'bgis_fi_prod'			 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-BGIS-FIXEDINCOME-PROD", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'fiag'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-FIAG", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'fidap'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-FIDAP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "FIDAP",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'fids'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-Fixed Income Data Support", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "FIDS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'fi_research'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-FI-RESEARCH", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "FI RESEARCH",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'fi_sovplus'												 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-FI-SOVPLUS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'flextrade'			          		 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-flextrade", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "FLEXTRADE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_aasg'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_aasg", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA AASG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_acm'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_acm", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA ACM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_adg'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GAA ADG AUTOGEN", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA ADG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_aig'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_aig", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA AIG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'amg'				                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-AMG-IT", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "AMG IT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_aplus'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_aplus", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA APLUS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_asgintl'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_asgintl", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA ASGINTL",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_asgus'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GAA ASGUS AUTOGEN", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA ASGUS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_atg'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_atg", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA ATG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_aurg'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_aurg", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA AURG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_cnrg'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_cnrg", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA CNRG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_etg'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_etg", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA ETG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_faser'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_faser", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA FASER",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_gaepm'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_gaepm", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA GAEPM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_gaepm_uk_aa'			         => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_gaepm_uk_aa", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA GAEPM_UK AA",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_gaepm_uk_alphagen'			   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_gaepm_uk_alphagen", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA GAEPM_UK ALPHAGEN",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_growtheq'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_growtheq", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA GROWTHEQ",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_gtaa'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_gtaa", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA GTAA",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_intellis'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_intellis", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA INTELLIS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_neualpha'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GAA NEUALPHA", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA NEUALPHA",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_otg'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_otg", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA OTG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_tpg'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_tpg", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA TPG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_trg'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_trg", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA TRG",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_ukpm'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_ukpm", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA UKPM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_usafi'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gaa_usafi", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA USAFI",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaa_usss'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GAA-USSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAA USSS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gaepm'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GAEPM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gae_ade_idb'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GAEIT IDB", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GAEIT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gate'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gate", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gcmform'				 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gcom'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GCOM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GCOM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "SUPPORT-GCOM", 
											'p_location' => "GLOBAL"
										  },
		'gds'							 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gem'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gem", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'genie'			                     => {
											'method'     => "ticket",
											'ap_group'   => "EDS-Genie", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gift'				 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gitap'				 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gfit'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gfit", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GFIT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gio'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gio", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GIO",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gio-unix'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gio-unix", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GIO-UNIX",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gitap'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gitap", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SHAREIT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gladis'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gladis", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GLADIS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'glm' 			                   => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-glm2", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GLM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'glm2'			                   => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-glm2", 
											'ap_script'  => "BGI Equilend",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GLM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'global_ishares'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GLOBAL ISHARES IT", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ISHARES MESSAGING",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gls_gate'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUP-MQSERIES", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "MQSERIES",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gmd'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KMIT-SYSTEM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SUMS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gmd_europe_mi'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GMD EUROPE MI", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SUMS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gmmt_soa'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GMMT-SOA", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SOA",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gmmt_soa_email'				=> {
											'method'     => "alarmpoint_only",
											'ap_group'   => "GMMT_SOA_EMAIL",
											'ap_script'  => "BGI VPO",
                                                                                        'p_category' => "",
                                                                                        'p_subcat'   => "",
                                                                                        'p_product'  => "",
                                                                                        'p_problem'  => "",
                                                                                        'p_asg_grp'  => "",
                                                                                        'p_location' => "GLOBAL"
 										},
		'gmsg'			                 	=> {
											'method'     => "ticket",
											'ap_group'   => "SUP-mqseries", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "MQSERIES",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },

		'gos'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gos", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GOS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'got_europe'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GOT-EUROPE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GOT-EUROPE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'got_fts'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GOT-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GOT-FTS-SUPPORT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'got_fts_email'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GOT-FTS-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GOT-FTS-SUPPORT-EMAIL",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'got'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-BGI-GOT-FTS-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'eas'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-BGI-GOT-FTS-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'easuk'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CIPIT", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gotuk'													 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CIPIT", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'goton'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GOT-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GOT-FTS-SUPPORT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gps'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gps", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GPS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gss'	         		             => {
											'method'     => "ticket",
											'ap_group'   => "unknown", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gss_cfmail'				 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gsurveyor'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-gsurveyor", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "MQSERIES",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gtse'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GTS-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GTS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'gts'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GTS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ha'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ha", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'halfpipe'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-HALFPIPE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE", 
											'p_subcat'   => "SOFTWARE", 
											'p_product'  => "HALFPIPE",
											'p_problem'  => "FAULT", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'hardcatweb'				 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'hardware'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-hardware", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'helpme'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "HELPME",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'hfdp'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-HFDP-DI", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "HFDP-DI",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'hfdp-di'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-HFDP-DI", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "HFDP-DI",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'hfdpm'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-HFDP-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "HFDP-EMAIL",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'hfdpp'			                 => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-HFDP-PT-EMAIL", 
											'ap_script'  => "",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'hfdpt'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-HFDP-PT", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "HFDP-PT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'indev'			                 => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-INDEV", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ia_developers'			                 => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-IA-DEVELOPERS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ihub'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-IHUB", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "IHUB",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'iweb'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'javaee_support'		 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-BGI JAVA EE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'jea-batches'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-TOKYO-AE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TOKYO AE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'jea-services'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-TOKYO-AE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TOKYO AE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'jea-web'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-TOKYO-AE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TOKYO AE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'jp_trade'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ITGOTJP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "JP TRADE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'iborprod'				=> {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-IT-GOT-GIBOR",
											'ap_script'  => "BGI VPO",
                                                                                        'p_category' => "",
                                                                                        'p_subcat'   => "",
                                                                                        'p_product'  => "",
                                                                                        'p_problem'  => "",
                                                                                        'p_asg_grp'  => "",
                                                                                        'p_location' => "GLOBAL"
										  },
		'ibordev'				=> {
											'method'     => "alarmpoint_only",
											'ap_group'   => "IBOR-DEV-EMAIL",
											'ap_script'  => "BGI VPO",
                                                                                        'p_category' => "",
                                                                                        'p_subcat'   => "",
                                                                                        'p_product'  => "",
                                                                                        'p_problem'  => "",
                                                                                        'p_asg_grp'  => "",
                                                                                        'p_location' => "GLOBAL"
										  },
		'iborppc'				=> {
											'method'     => "alarmpoint_only",
											'ap_group'   => "IBOR-PPC-EMAIL",
											'ap_script'  => "BGI VPO",
                                                                                        'p_category' => "",
                                                                                        'p_subcat'   => "",
                                                                                        'p_product'  => "",
                                                                                        'p_problem'  => "",
                                                                                        'p_asg_grp'  => "",
                                                                                        'p_location' => "GLOBAL"
										  },
		'ibortest'				=> {
											'method'     => "alarmpoint_only",
											'ap_group'   => "IBOR-TEST-EMAIL",
											'ap_script'  => "BGI VPO",
                                                                                        'p_category' => "",
                                                                                        'p_subcat'   => "",
                                                                                        'p_product'  => "",
                                                                                        'p_problem'  => "",
                                                                                        'p_asg_grp'  => "",
                                                                                        'p_location' => "GLOBAL"
										  },
		'ibt_gateway'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ibt_gateway", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "IBT GATEWAY",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'icore'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-icore", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'idl'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-idl", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'imm'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-imm", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "IMM (INTERNET MEETING MANAGER)",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ims'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ims", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'indices'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-indices", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TBD APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'internet_infrastructure'			 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-internet_infrastructure", 
											'ap_script'  => "BGI VPO",
											'p_category' => "NETWORK",
											'p_subcat'   => "INTERNET ACCESS",
											'p_product'  => "OTHER",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'intlpm'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-intlpm", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'intraspect'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUP-intraspect", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "INTRASPECT",
											'p_problem'  => "FAULT",

											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ipc'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-IPC", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'spa'											 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-SAPPHIRE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'iplanet'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-iplanet", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "IPLANET",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ishares'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-ishares.com", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ISHARES.COM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ishares_dynamo'               => {
											'method'     => "ticket",
											'ap_group'   => "SUP-ishares.com", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ISHARES.COM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ishares_inktomi'              => {
											'method'     => "ticket",
											'ap_group'   => "SUP-ishares.com", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ISHARES.COM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ishares_fi_bus'			         => {
											'method'     => "ticket",
											'ap_group'   => "SUP-ishares-fi", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ISHARES.COM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ishares_fi_dev'			         => {
											'method'     => "ticket",
											'ap_group'   => "SUP-ishares-fi", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ISHARES.COM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'issue_price'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'itsm-servicecenter'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SERVICECENTER",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'iunits'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-iunits.com", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "IUNITS.COM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'job'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-job", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'jrun'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUP-jrun", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'km_it_ps'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KM IT Production Services", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'kmit'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KM IT Production Services", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'kmitps'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KM IT Production Services", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'kmmdw'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-sums", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SUMS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'kmmws'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-EDS IT", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'k2desk'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "K2DESK",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'km_mdw'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KMIT-SYSTEM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'kmmdw_uat'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KMMDW-UAT", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'km_messages'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KM-PUBLISHED-MESSAGE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "KM-PUBLISHED-MESSAGE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'km_rdp'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-KM-RDP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "KM RDP",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'lockouts'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'lid_qa'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-LID-QA", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mac'			             => {
											'method'     => "ticket",
											'ap_group'   => "3 US TRADEFLOOR", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SERVERS",
											'p_subcat'   => "TRADE FLOOR",
											'p_product'  => "MAC",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mirai'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GBPS-MIRAI", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'misc'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-misc", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mqadmin'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-mqseries", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "MQSERIES",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mqgateways'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-GATEWAYS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "MQSERIES",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mss_admin'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-mss_admin", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mss_conf'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-mss_conf", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mss_fault'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-mss_fault", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mss_perf'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-mss_perf", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mssql-amr'			               => {
											'method'     => "ticket",
											'ap_group'   => "DBA-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "DATABASE",
											'p_subcat'   => "DATABASE ADMINISTRATION",
											'p_product'  => "MICROSOFT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mssql'   			               => {
											'method'     => "ticket",
											'ap_group'   => "DBA-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "DATABASE",
											'p_subcat'   => "DATABASE ADMINISTRATION",
											'p_product'  => "MICROSOFT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mssql-test'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-mssql-test", 
											'ap_script'  => "BGI VPO",
											'p_category' => "DATABASE",
											'p_subcat'   => "DATABASE ADMINISTRATION",
											'p_product'  => "MSSQL-TEST",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'mpotr'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-TRIM-MPO", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'multi_curr'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'nas'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-STORAGE-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "STORAGE",
											'p_subcat'   => "CAPACITY EXPANSION",
											'p_product'  => "NAS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'nas_email'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-STORAGE-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "STORAGE",
											'p_subcat'   => "CAPACITY EXPANSION",
											'p_product'  => "NAS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'netapps'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-STORAGE-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'netbackup'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-STORAGE-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "STORAGE",
											'p_subcat'   => "DATA PROTECTION",
											'p_product'  => "BACKUPS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'netbackup_sox'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'network'			               => {
											'method'     => "ticket",
											'ap_group'   => "NETWORK-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'network-sip'			               => {
											'method'     => "ticket",
											'ap_group'   => "NETWORK-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'new-cash-flow'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-NEW-CASH-FLOW", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "NEW-CASH-FLOW",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'newscale'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'notification'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUP-VPOSCAP", 
											'ap_script'  => "BGI On-Call",
											'p_category' => "MESSAGING",
											'p_subcat'   => "END-TO-END",
											'p_product'  => "VPO-SERVICECENTER-ALARMPOINT",
											'p_problem'  => "MESSAGE CHECKER",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'notification_sc'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ENDTOEND", 
											'ap_script'  => "BGI VPO",
											'p_category' => "MESSAGING",
											'p_subcat'   => "END-TO-END",
											'p_product'  => "SUPPORT-VPO SC ALARMPOINT",
											'p_problem'  => "MESSAGE CHECKER",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ofa'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'onetick'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-EDS-ONETICK", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'opc'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-opc", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'opendeploy'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUP-opendeploy", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "OPEN DEPLOY",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'oracl'			                 => {
											'method'     => "ticket",
											'ap_group'   => "DBA-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "Database", 
											'p_subcat'   => "Database Administration", 
											'p_product'  => "Oracle",
											'p_problem'  => "Fault", 
											'p_asg_grp'  => "DBA Oracle Autogen-FTS", 
											'p_location' => "GLOBAL"
										  },
		'oracle'			                 => {
											'method'     => "ticket",
											'ap_group'   => "DBA-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "Database", 
											'p_subcat'   => "Database Administration", 
											'p_product'  => "Oracle",
											'p_problem'  => "Fault", 
											'p_asg_grp'  => "DBA Oracle Autogen-FTS", 
											'p_location' => "GLOBAL"
										  },
		'oracle2'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-DBA-FTS-TIER2", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'oracle-test'			                 => {
											'method'     => "ticket",
											'ap_group'   => "Oracle-Test", 
											'ap_script'  => "BGI VPO",
											'p_category' => "Database", 
											'p_subcat'   => "Database Administration", 
											'p_product'  => "Oracle-Test",
											'p_problem'  => "Fault", 
											'p_asg_grp'  => "Oracle Autogen-Test", 
											'p_location' => "GLOBAL"
										  },
		'orbis'			                   => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis_b", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ORBIS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_escalate'			       => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis_escalate", 
											'ap_script'  => "BGI ORBIS ESCALATE",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_trd_japan_escalate'		  => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis_trd_japan_escalate", 
											'ap_script'  => "BGI ORBIS ESCALATE",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_aus_escalate'			  => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis_aus_escalate", 
											'ap_script'  => "BGI ORBIS ESCALATE",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_can_escalate'			  => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis_can_escalate", 
											'ap_script'  => "BGI ORBIS ESCALATE",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_europe_escalate'			  => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis_europe_escalate", 
											'ap_script'  => "BGI ORBIS ESCALATE",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_aus'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-orbis-aus", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_aus_risk'			         => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-RISK", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_aus_trd'			           => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-orbis-aus-trd", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_can'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-orbis-can", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_can_risk'			         => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-RISK", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_can_trd'			           => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-orbis-can-trd", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_crossing'			         => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis-cross", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_cst'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis-cst", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_equity'			           => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis_equity", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_japan_trading'			           => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-JAPAN-TRADING", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_qa'			           => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-ORBIS-QA", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_qa_uk'			           => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-ORBIS-QA-UK", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_rm'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis-rm", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_support'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS MESSAGING",
											'ap_script'  => "BGI ORBIS",
											'p_category' => "SOFTWARE", 
											'p_subcat'   => "SOFTWARE", 
											'p_product'  => "ORBIS MESSAGING",
											'p_problem'  => "FAULT", 
											'p_asg_grp'  => "SUPPORT-ORBIS MESSAGING", 
											'p_location' => "GLOBAL"
										  },
		'orbis_trd'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis-trd_b", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_trd_japan'			         => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis japan_b", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_us_index'			         => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-US-INDEX", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_us_currency'			         => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-CURRENCY", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_us_auto'			         => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-US-AUTO", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_us_breach'			         => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-US-BREACH", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_us_equity'			         => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-US-EQUITY", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_uk'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis-uk", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_uk_currency'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-UK-CURRENCY", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_uk_fi'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-UK-FIT", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_uk_equity'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ORBIS-UK-EQUITY", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'orbis_usidxpm'			           => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUP-orbis-usidxpm_b", 
											'ap_script'  => "BGI ORBIS",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ordersonline'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GOT-FTS-COM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ORDERS ONLINE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'os'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-os", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SERVERS",
											'p_subcat'   => "UNIX",
											'p_product'  => "OPERATING SYSTEM",
											'p_problem'  => "REPAIR/REPLACE",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'pars'  			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-pars", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "PARS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'pb_rpt'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'peoplesoft_hr'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-PEOPLESOFT-HR", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "PEOPLESOFT HR",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'performance'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-performance", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'pims'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-pims", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'prep'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'prism'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-PRISM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'proa'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'pst' 			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										},
		'purchasing'			         => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'purchasing_web'			         => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'quality_center'			         => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-QUALITY CENTER", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'rho'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-RHO", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "RHO",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'rk'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-rk", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TBD APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'rkp'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-rkp", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TBD APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'san'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-STORAGE-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "STORAGE",
											'p_subcat'   => "CAPACITY EXPANSION",
											'p_product'  => "SAN",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'security'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-security", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SECURITY",
											'p_subcat'   => "SERVER SECURITY",
											'p_product'  => "UNIX",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'sentry'			               => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-SENTRY", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'servicecenter'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SERVICECENTER",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'shareit'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SERVICECENTER",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'shareit-test'			           => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SERVICECENTER",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'solaris' 	                   => {
											'method'     => "ticket",
											'ap_group'   => "FTS-UNIX", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SERVERS",
											'p_subcat'   => "UNIX",
											'p_product'  => "OPERATING SYSTEM",
											'p_problem'  => "REPAIR/REPLACE",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'snmp'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-snmp", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'spi_svcdisc'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-spi_svcdisc", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ssp'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ssp", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'statement'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-statement", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'sums'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GMD", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "SUMS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'sybas'			                 => {
											'method'     => "ticket",
											'ap_group'   => "DBA-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "DATABASE",
											'p_subcat'   => "DATABASE ADMINISTRATION",
											'p_product'  => "SYBASE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'sybase'			                 => {
											'method'     => "ticket",
											'ap_group'   => "DBA-FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "DATABASE",
											'p_subcat'   => "DATABASE ADMINISTRATION",
											'p_product'  => "SYBASE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'sybase-test'			             => {
											'method'     => "ticket",
											'ap_group'   => "DBA-TEST", 
											'ap_script'  => "BGI VPO",
											'p_category' => "DATABASE",
											'p_subcat'   => "DATABASE ADMINISTRATION",
											'p_product'  => "SYBASE-TEST",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'sydinv'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-SYDNEY-INV", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'symphony'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-SYMPHONY", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tar'			                     => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-tar", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TAR",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'teledirect'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TELEDIRECT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tky_cdb'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-TOKYO CDB", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tky_pas'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-TOKYO PAS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tky_mngw'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-TOKYO-AE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TOKYO AE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tky_tpt'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ITGOTJP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tkymn'			             => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-TOKYO-AE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tky_it_gfi'			             => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-TKY-IT-GFI", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tky_it_gfi_email'			             => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-TKY-IT-GFI-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tky_it_got_jp'			             => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-ITGOTJP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tky_it_got_jp_email'			             => {
											'method'     => "alarmpoint_only",
											'ap_group'   => "SUPPORT-GOT-JP-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tky_it_prod_sup'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-ITGOTJP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'torapps'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-torapps", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CAN APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'torinfra'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-torinfra", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CAN INFRASTRUCTURE",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tradefloor'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-tradefloor", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SERVERS",
											'p_subcat'   => "TRADE FLOOR",
											'p_product'  => "APPLICATION RELATED",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'trackit'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-IT TRACKIT", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "IT TRACKIT",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'transfer'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-transfer", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'transvc'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-transvc", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TRANSITION SERVICES",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'triplea'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-triplea", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "TBD APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'tsweb'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GSS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'uk-it-dev'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-uk-it-dev", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "UK-IT DEV",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'uk_tradefloor'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-TRADEFLOOR", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'unix'			             => {
											'method'     => "ticket",
											'ap_group'   => "FTS-UNIX", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'unix_security_env'			             => {
											'method'     => "ticket",
											'ap_group'   => "FTS-UNIX", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'uktest'			                 => {
											'method'     => "ticket",
											'ap_group'   => "uktest", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'uk_helpdesk'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-HELPDESK", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'ultraseek'	                   => {
											'method'     => "ticket",
											'ap_group'   => "SUP-ULTRASEEK", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "ULTRASEEK",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'usoe'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GOT-FTS-COM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GOT-FTS-COM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'v3de'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-V3DE", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'valkyrie'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-EAS-AUS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'vpo-servicecenter-alarmpoint' => {
											'method'     => "ticket",
											'ap_group'   => "SUP-VPOSCAP", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'webadmin'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-webadmin", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'weblogic' 			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-GOT-FTS-COM", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "GOT-FTS-COM",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'windows' 			               => {
											'method'     => "ticket",
											'ap_group'   => "WINDOWS On-Call FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'winfts' 			               => {
											'method'     => "ticket",
											'ap_group'   => "WINDOWS On-Call FTS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'windows_app_admin' 			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-APPMANAGER-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'windows_sc' 			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-WINDOWS-GLOBAL-EMAIL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "",
											'p_subcat'   => "",
											'p_product'  => "",
											'p_problem'  => "",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'windows_global'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-WINDOWS-GLOBAL", 
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'wl_prd'			                 => {
											'method'     => "ticket",
											'ap_group'   => "SUP-WEBLOGIC", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "WEBLOGIC",
											'p_problem'  => "ADVICE/GUIDANCE",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'wl_qa'			                   => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-wl_qa", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "WEBLOGIC",
											'p_problem'  => "ADVICE/GUIDANCE",
											  'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'x_stats'			             => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-CLIENT APPLICATIONS", 
											'ap_script'  => "BGI VPO",
											'p_category' => "SOFTWARE",
											'p_subcat'   => "SOFTWARE",
											'p_product'  => "CLIENT APPLICATIONS",
											'p_problem'  => "FAULT",
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL"
										  },
		'z-spreads'			               => {
											'method'     => "ticket",
											'ap_group'   => "SUPPORT-zspreads",
											'ap_script'  => "BGI VPO",
											'p_category' => "", 
											'p_subcat'   => "", 
											'p_product'  => "",
											'p_problem'  => "", 
											'p_asg_grp'  => "", 
											'p_location' => "GLOBAL" 
										  }
	};

	return $data_map;


}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

##############################################################################
### End of Public Methods / Functions ########################################
##############################################################################

##############################################################################
### Private Methods / Functions ##############################################
##############################################################################






##############################################################################
### End of Private Methods / Functions #######################################
##############################################################################

##############################################################################
# Do not change this.  Required for successful require load
1;
##############################################################################

__END__

=head2 DEVELOPER'S NOTES
 

=cut


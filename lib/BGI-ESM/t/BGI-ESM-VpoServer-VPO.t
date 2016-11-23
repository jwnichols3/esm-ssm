#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME

Test script for BGI::ESM::VpoServer::VPO

=head1 SYNOPSIS



=head1 REVISIONS

CVS Revision: $Revision: 1.13 $

	#####################################################################
	#
	# Major Revision History:
	#
	#  Date       Initials  Description of Change
	#  ---------- --------  ---------------------------------------
	#  2005-08-26   nichj   Developing release 1
	#  2005-11-30   nichj   Adding options for additional methods
	#  2006-03-31   nichj   Removing node-related methods and moving them to -Nodes.t
	#  2006-08-06   nichj   Added ovo_server_status and get_ovo_server_status_cmd
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
use BGI::ESM::Common::Shared qw(os_type get_hostname say);
use BGI::ESM::Common::Variables qw(server_variables);


##############################################################################
my @subs = qw(
	deconstruct_vpo_data_hash
	get_opc_notify_cmd
	get_remote_agent_status
	get_remote_agent_status_command
	parse_cma
	vpo_ack_event
	vpo_data_hash_blank
	vpo_data_populate
	vpo_message_groups
	vpo_own_event
	vpo_sql_call
	vpo_tti_cli_generate
    vpo_annotate
    ovo_server_status
    get_ovo_server_status_cmd
 );

BEGIN { use_ok('BGI::ESM::VpoServer::VPO', @subs); };

##############################################################################

can_ok( __PACKAGE__, 'deconstruct_vpo_data_hash'); # done
can_ok( __PACKAGE__, 'get_opc_notify_cmd'); # done
can_ok( __PACKAGE__, 'get_remote_agent_status'); # done
can_ok( __PACKAGE__, 'get_remote_agent_status_command'); # done
can_ok( __PACKAGE__, 'parse_cma');
can_ok( __PACKAGE__, 'vpo_ack_event');
can_ok( __PACKAGE__, 'vpo_annotate');
can_ok( __PACKAGE__, 'vpo_data_hash_blank'); 
can_ok( __PACKAGE__, 'vpo_data_populate');
can_ok( __PACKAGE__, 'vpo_message_groups');
can_ok( __PACKAGE__, 'vpo_own_event');
can_ok( __PACKAGE__, 'vpo_sql_call');
can_ok( __PACKAGE__, 'vpo_tti_cli_generate');
can_ok( __PACKAGE__, 'ovo_server_status');
can_ok( __PACKAGE__, 'get_ovo_server_status_cmd');

###############################################################################
##### Load common methods and variables
###############################################################################


###############################################################################
##### Testing Section
###############################################################################

#########################
#########################
GET_REMOTE_AGENT_STATUS:
{
	
	print "\n\nget_remote_agent_status_command\n";
	my $server_vars = server_variables();
	my $cmd_got = get_remote_agent_status_command();
	my $cmd_exp = $server_vars->{'RAGENT'};
	
	is ($cmd_got, $cmd_exp, 'get_remote_agent_status_command( ) should return the ragent command: ' . $cmd_got);
	
	
	if (os_type() eq 'UNIX') {
	print "\n\nget_remote_agent_status\n";
		my $hostname = "vpo";
		my $rstatus_got = get_remote_agent_status($hostname);
		my @rstatus_exp = `$cmd_got $hostname 2>&1 |grep -v BBC`;
		
		is_deeply($rstatus_got, \@rstatus_exp,
				  'get_remote_agent_status( $hostname ) should return the output of the ragent command');
	}
	
}

#########################
#########################
VPO_TTI_CLI:
{
	print "\n\nvpo_tti_cli_generate\n\n";
	my @apps         = qw(esm orbis test_app);
	my @severities   = qw(warning minor major critical);
	my $message_text = "Testing opc_notify at " . time;
	my $node         = get_hostname();
	
	my $vpo_event    = {
			'message_group'      => "",
			'node'               => $node,
			'cma'                => "",
			'message_text'       => "$message_text",
			'msgid'              => "12345" . time,
			'node_type'          => "Intel x86/Px",
			'event_date_node'    => "11/29/2005",
			'event_time_node'    => "18:00:01",
			'event_date_mgmtsvr' => "11/29/2005",
			'event_time_mgmtsvr' => "18:00:01",
			'appl'               => "appl",
			'obj'                => "obj",
			'severity'           => "",
			'operators'          => "",
			'instruction_text'   => "",
		};
	
	
	foreach my $app (@apps) {
		foreach my $sev (@severities) {
			
			$vpo_event->{'severity'}      = $sev;
			$vpo_event->{'message_group'} = $app;
			
			my $cli_params = vpo_tti_cli_generate($vpo_event);
			
			say("\nTTI CLI");
			say($cli_params);
			
			my $vpo_event_array_nq = deconstruct_vpo_data_hash($vpo_event, 'no_quotes');
			my $vpo_event_array    = deconstruct_vpo_data_hash($vpo_event);
			
			my $vpo_hash_populated = vpo_data_populate($vpo_event_array);
			
			is_deeply($vpo_hash_populated, $vpo_event, 'vpo_data_populate( \%vpo_data ) should populate the data hash.' );
		
		}
	}
	
}

#########################
#########################
GET_OPC_NOTIFY_CMD:
{
	
	print "\n\nget_opc_notify_cmd\n\n";
	my $opc_notify_cmd_expected_windows  = "c:/code/vpo/vpo_server/src/opc_notify.pl";
	my $opc_notify_cmd_unix_prod         = "/apps/esm/tti/bin/opc_notify";
	my $opc_notify_cmd_unix_cvs          = "/apps/esm/vpo/vpo_server/src/opc_notify.pl";
	
	my $opc_notify_cmd_cvs  = get_opc_notify_cmd();
	my $opc_notify_cmd_prod = get_opc_notify_cmd('prod');
	
	if (os_type() eq 'WINDOWS') {
		is ($opc_notify_cmd_cvs, $opc_notify_cmd_expected_windows,
			'get_opc_notify_cmd( ) should return the opc_notify command: ' . $opc_notify_cmd_cvs);
		is ($opc_notify_cmd_prod, $opc_notify_cmd_expected_windows,
			'get_opc_notify_cmd( prod ) should return the opc_notify command: ' . $opc_notify_cmd_cvs);
	}
	else {
		is ($opc_notify_cmd_cvs, $opc_notify_cmd_unix_cvs,
			'get_opc_notify_cmd( ) should return the opc_notify command: ' . $opc_notify_cmd_cvs);
		is ($opc_notify_cmd_prod, $opc_notify_cmd_unix_prod,
			'get_opc_notify_cmd( prod ) should return the opc_notify command: ' . $opc_notify_cmd_cvs);
	}
		
}

GET_VPO_OWN_CMD:
{

	print "\n\nget_vpo_own_cmd\n\n";
	my ($chg_own_cmd_expected, $chg_own_cmd_got);
	
	if (os_type() eq 'UNIX') {
		$chg_own_cmd_expected = "/apps/esm/bin/chg_own";
	}
	else {
		$chg_own_cmd_expected = 0;
	}
	
	$chg_own_cmd_got = get_vpo_own_cmd();
	
	is ($chg_own_cmd_got, $chg_own_cmd_expected, 'get_vpo_own_cmd( ) should return the vpo chg owner command (only on UNIX): ' . $chg_own_cmd_got);

}

#########################
#########################
OVO_SERVER_STATUS:
{
	my $ovo_server_status = ovo_server_status();
	print "OVO Server Status\n";
	print @{$ovo_server_status};
	if (os_type() ne 'WINDOWS' or os_type() ne 'LINUX') {
		is ($ovo_server_status, $ovo_server_status, 'ovo_server_status() should return the status of the ovo server status command');
	}
}

###############################################################################
##### post-processing clean up 
###############################################################################



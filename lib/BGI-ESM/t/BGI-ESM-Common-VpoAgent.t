
=head1 NAME

Test module for BGI ESM Common VpoAgent Methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::VpoAgent

=head1 REVISIONS

CVS Revision: $Revision: 1.4 $

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
	: 
	
=cut

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
#use Net::Nslookup;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type);

##################################################
##################################################
our ($opt_agent_test);
GetOptions(
            "agent_test"
          );

##################################################
##################################################
my @subs = qw(
    get_monitoring_policies
	get_monitoring_policies_cmd
    get_agent_status
    get_agent_status_output
    get_agent_status_cmd
    get_agent_start_cmd
    get_agent_kill_cmd
    get_agent_stop_cmd
    agent_kill
    agent_start
    agent_restart
    agent_stop
	agent_start
    get_nodeinfo_file_contents
    get_nodeinfo_file_name
    get_opcinfo_file_contents
    get_opcinfo_file_name
    get_mgrconf_file_contents
    get_mgrconf_file_name
    get_primmgr_file_contents
    get_primmgr_file_name
    disable_monitoring_policy
    enable_monitoring_policy
	return_all_monitoring_policies
	return_monitoring_policy
);

BEGIN { use_ok('BGI::ESM::Common::VpoAgent', @subs); };

##################################################
##################################################

can_ok( __PACKAGE__, 'get_monitoring_policies'     );
can_ok( __PACKAGE__, 'get_monitoring_policies_cmd' );
can_ok( __PACKAGE__, 'get_agent_status'            );
can_ok( __PACKAGE__, 'get_agent_status_output'     );
can_ok( __PACKAGE__, 'get_agent_status_cmd'        );
can_ok( __PACKAGE__, 'get_agent_start_cmd'         );
can_ok( __PACKAGE__, 'get_agent_kill_cmd'          );
can_ok( __PACKAGE__, 'get_agent_stop_cmd'          );
can_ok( __PACKAGE__, 'agent_kill'                  );
can_ok( __PACKAGE__, 'agent_start'                 );
can_ok( __PACKAGE__, 'agent_restart'               );
can_ok( __PACKAGE__, 'agent_stop'                  );
can_ok( __PACKAGE__, 'agent_start'                 );
can_ok( __PACKAGE__, 'get_nodeinfo_file_contents'  );
can_ok( __PACKAGE__, 'get_nodeinfo_file_name'      );
can_ok( __PACKAGE__, 'get_opcinfo_file_contents'   );
can_ok( __PACKAGE__, 'get_opcinfo_file_name'       );
can_ok( __PACKAGE__, 'get_mgrconf_file_contents'   );
can_ok( __PACKAGE__, 'get_mgrconf_file_name'       );
can_ok( __PACKAGE__, 'get_primmgr_file_contents'   );
can_ok( __PACKAGE__, 'get_primmgr_file_name'       );
can_ok( __PACKAGE__, 'disable_monitoring_policy'   );
can_ok( __PACKAGE__, 'enable_monitoring_policy'    );
can_ok( __PACKAGE__, 'return_all_monitoring_policies' );
can_ok( __PACKAGE__, 'return_monitoring_policy'    );

##################################################
##################################################
# Variables for the test
our $sleep_time = 10;

##################################################
##################################################
GET_MONITORING_POLICIES:
{
	print "\n\n== Get Monitoring Policies\n\n";
	my $monitoring_policies_got = get_monitoring_policies();
	
	print Dumper ($monitoring_policies_got);
	
}

##################################################
##################################################
RETURN_ALL_MONITORING_POLICIES:
{
	print "\n\n== Return *ALL* Monitoring Policies\n\n";
	my $results = return_all_monitoring_policies();
	
	print Dumper ($results)
}

##################################################
##################################################
RETURN_MONITORING_POLICY:
{
	print "\n\n== Return specific Monitoring Policy
	\n\n";
	my $search = "File";
	
	my $results = return_monitoring_policy($search);
	
	print Dumper ($results)
}

##################################################
##################################################
GET_MONITORING_POLICIES_CMD:
{
	print "\n\n== Get Monitoring Policies Cmd\n\n";
	
	my $monitoring_policies_cmd_expected = "opctemplate";
	
	my $monitoring_policies_cmd_got  = get_monitoring_policies_cmd();
	
	is ($monitoring_policies_cmd_got, $monitoring_policies_cmd_expected,
		'get_monitoring_policies_cmd( ) should return the command line for getting the monitoring policy: ' . $monitoring_policies_cmd_got);

}

##################################################
##################################################
GET_AGENT_STATUS:
{
	print "\n\n== Get Agent Status\n\n";
	my $agent_status_got = get_agent_status();
	
	is ($agent_status_got, 1,
		'get_agent_status( ) should return 1 if agent is running okay.');
}

##################################################
##################################################
GET_AGENT_STATUS:
{
	print "\n\n== Get Agent Status Output\n\n";
	my $agent_status_output_got = get_agent_status_output();
	
	print Dumper ($agent_status_output_got);
	
};

##################################################
##################################################
GET_NODEINFO_FILE_NAME:
{
	print "\n\n== Node Info File NAME\n\n";

	my $nodeinfo_file_name = get_nodeinfo_file_name();
	
	print Dumper ($nodeinfo_file_name);
	
	
}

##################################################
##################################################
GET_NODEINFO_FILE_CONTENTS:
{
	print "\n\n== Node Info File Contents\n\n";

	my $nodeinfo_file_contents = get_nodeinfo_file_contents();
	
	print Dumper ($nodeinfo_file_contents);
	
	
}

##################################################
##################################################
GET_OPCINFO_FILE_NAME:
{
	print "\n\n== opc Info File NAME\n\n";

	my $opcinfo_file_name = get_opcinfo_file_name();
	
	print Dumper ($opcinfo_file_name);
	
	
}

##################################################
##################################################
GET_OPCINFO_FILE_CONTENTS:
{
	print "\n\n== opc Info File Contents\n\n";

	my $opcinfo_file_contents = get_opcinfo_file_contents();
	
	print Dumper ($opcinfo_file_contents);
	
	
}

##################################################
##################################################
GET_MGRCONF_FILE_NAME:
{
	print "\n\n== mgrconf File NAME\n\n";

	my $mgrconf_file_name = get_mgrconf_file_name();
	
	print Dumper ($mgrconf_file_name);
	
	
}

##################################################
##################################################
GET_MGRCONF_FILE_CONTENTS:
{
	print "\n\n== mgrconf File Contents\n\n";

	my $mgrconf_file_contents = get_mgrconf_file_contents();
	
	print Dumper ($mgrconf_file_contents);
	
	
}

##################################################
##################################################
GET_PRIMMGR_FILE_NAME:
{
	print "\n\n== primmgr File NAME\n\n";

	my $primmgr_file_name = get_primmgr_file_name();
	
	print Dumper ($primmgr_file_name);
	
	
}

##################################################
##################################################
GET_PRIMMGR_FILE_CONTENTS:
{
	print "\n\n== primmgr File Contents\n\n";

	my $primmgr_file_contents = get_primmgr_file_contents();
	
	print Dumper ($primmgr_file_contents);
	
	
}

##################################################
##################################################
GET_AGENT_STATUS_CMD:
{
	print "\n\n== Get Agent Status Cmd\n\n";
	my $agent_status_cmd_expected = "opcagt -status";
	my $agent_status_cmd_got      = get_agent_status_cmd();
	
	is ($agent_status_cmd_got, $agent_status_cmd_expected,
		'get_agent_status_cmd( ) should return the command line for agent status: ' . $agent_status_cmd_got);
}

##################################################
##################################################
GET_AGENT_START_CMD:
{
	print "\n\n== Get Agent Start Cmd\n\n";
	my $agent_start_cmd_expected ;
	
	if (os_type() eq 'WINDOWS') {
		$agent_start_cmd_expected = "opcagt -start";
	}
	else {
		$agent_start_cmd_expected = "/etc/init.d/opcagt start";
	}
	
	my $agent_start_cmd_got      = get_agent_start_cmd();
	
	is ($agent_start_cmd_got, $agent_start_cmd_expected,
		'get_agent_start_cmd( ) should return the command line for agent start: ' . $agent_start_cmd_got);
}

##################################################
##################################################
GET_AGENT_KILL_CMD:
{
	print "\n\n== Get Agent Kill Cmd\n\n";
	my $agent_kill_cmd_expected = "opcagt -kill";
	my $agent_kill_cmd_got      = get_agent_kill_cmd();
	
	is ($agent_kill_cmd_got, $agent_kill_cmd_expected,
		'get_agent_kill_cmd( ) should return the command line for agent kill: ' . $agent_kill_cmd_got);

};

##################################################
##################################################
GET_AGENT_STOP_CMD:
{
	print "\n\n== Get Agent Stop Cmd\n\n";
	my $agent_stop_cmd_expected = "opcagt -stop";
	my $agent_stop_cmd_got      = get_agent_stop_cmd();
	
	is ($agent_stop_cmd_got, $agent_stop_cmd_expected,
		'get_agent_stop_cmd( ) should return the command line for agent stop: ' . $agent_stop_cmd_got);

};

###############################################################################
#### Agent Testing - --agent_test should be flagged on the command line #######
###############################################################################
if ($opt_agent_test) {
    
    print "=== Running Agent Tests...\n\n";
        
    ##################################################
    ##################################################
    AGENT_KILL:
    {
        print "\n\n== Agent Kill\n\n";
        my $agent_kill_status = agent_kill();
        is ($agent_kill_status, 1,
            'agent_kill( ) should return 1 if successful.');
        
    };
    
    print "Sleeping...\n";
    sleep $sleep_time;
    
    ##################################################
    ##################################################
    AGENT_START:
    {
    
        print "\n\n== Agent Start\n\n";
        my $agent_start_status = agent_start();
        is ($agent_start_status, 1,
            'agent_start( ) should return 1 if successful.');
    
    };
    
    print "Sleeping...\n";
    sleep $sleep_time;
    
    ##################################################
    ##################################################
    AGENT_RESTART:
    {
    
        print "\n\n== Agent Restart\n\n";
        my $agent_restart_status = agent_restart();
        is ($agent_restart_status, 1,
            'agent_restart( ) should return 1 if successful.');
    
    };
    
    print "Sleeping...\n";
    sleep $sleep_time;
    
    ##################################################
    ##################################################
    #AGENT_STOP:
    #{
    #
    #	print "\n\n== Agent Stop\n\n";
    #	my $agent_stop_status = agent_stop();
    #	is ($agent_stop_status, 1,
    #		'agent_stop( ) should return 1 if successful.');
    #
    #};
    #
    #print "Sleeping...\n";
    #sleep $sleep_time;
    
    print "Current Agent Status\n\n";
    print Dumper (get_agent_status_output());
    print "\n";

}    
#####################################
## post-processing clean up #########
#####################################



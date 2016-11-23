
=head1 NAME

Test module for BGI ESM Compile VpoServer modules

=head1 SYNOPSIS

This is test suite for BGI::ESM::VpoServer::Alarmpoint

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.3 $

    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2005-08-26   nichj   Developing release 1
    #  2005-10-27   nichj   Adding Linux checks
    #####################################################################

=head1 TODO

- Write tests for the following:
    : alarmpoint_alert
	
=cut

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More 'no_plan';
use Carp;
use Data::Dumper;
use lib "/code/vpo/BGI-ESM/lib";
use lib "/apps/esm/lib/BGI-ESM/lib";
use BGI::ESM::Common::Shared qw(os_type check_os trim);
use BGI::ESM::Common::Variables qw(agent_variables server_variables);

my @subs = qw(
                alarmpoint_alert
                numeric_sev
                get_apclient_command
                get_alarmpoint_hash_structure
            );

BEGIN { use_ok('BGI::ESM::VpoServer::Alarmpoint', @subs); };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'alarmpoint_alert');  
can_ok( __PACKAGE__, 'numeric_sev');                   # done
can_ok( __PACKAGE__, 'get_apclient_command');          # done
can_ok( __PACKAGE__, 'get_alarmpoint_hash_structure'); # done


#########################
#########################
# GLOBAL VARIABLES
my ($apclient_cmd_found);

#########################
#########################
NUMERIC_SEV:
{
    
    print "\n\n==Numeric_Sev==\n\n";
    my @sevs = qw(normal warning minor major critical);
	my $sev_expected;

	foreach my $sev (@sevs) {

		if ($sev eq "normal") {
			$sev_expected = 6;
		}
		elsif ($sev eq "warning") {
			$sev_expected = 5;
		}
		elsif ($sev eq "minor") {
			$sev_expected = 4;
		}
		elsif ($sev eq "major") {
			$sev_expected = 3;
		}
		elsif ($sev eq "critical") {
			$sev_expected = 2;
		}
		else {
			$sev_expected = 0;
		}
		
		my $num_sev = numeric_sev($sev);
		
		
		is ($sev_expected, $num_sev,
			'numeric_sev( ) should return the numeric equal to the severity: ' . $sev . " returned: " . $num_sev);
	}
}

#########################
#########################
APCLIENT_CMD:
{
    print "\n\n==get_apclient_command==\n\n";

    my ($ap_cmd, $ap_drv, $ap_exe,);
    
    if (os_type() eq 'WINDOWS') {
        $ap_drv = "e:";
        $ap_exe = "/APAgent/APClient.bin.exe";
        $ap_cmd = "${ap_drv}${ap_exe}";
        
        if (not -e $ap_cmd) {
            $ap_drv = "c:";
            $ap_cmd = "${ap_drv}${ap_exe}";
        }
        else {
            carp "Unable to locate apclient command!";
            $ap_cmd = $ap_exe;
        }
        
    }
    elsif (os_type() eq 'LINUX') {
        $ap_cmd = "/opt/OV/apagent/APClient.bin";
        
    }
    elsif (os_type() eq 'UNIX') {
        $ap_cmd = "/opt/OV/apagent/APClient.bin";
        
    }
    else {
        $ap_cmd = "";
    }
    
    my $ap_cmd_got = get_apclient_command();
    
    is ($ap_cmd, $ap_cmd_got,
        'get_apclient_command should return the alarmpoint client command: ' . $ap_cmd_got);
    
    if ($ap_cmd_got) {
        $apclient_cmd_found = 1;
    }
}

ALARMPOINT_HASH_STRUCTURE:
{
    
   	# Data Structure Notes
	#  ap_data{ 'map_data'       }*
	#  ap_data{ 'script'         }*
	#  ap_data{ 'groupname'      }*
	#  ap_data{ 'eventid'        }*
	#  ap_data{ 'messagetext'    }
	#  ap_data{ 'host'           }
	#  ap_data{ 'severity'       }
	#  ap_data{ 'ticket'         }
	#  ap_data{ 'logfile'        }
	#  ap_data{ 'contact_device' }
	#  ap_data{ 'behavior'       }
	#
	#  ap_data{ 'netiq_severity' }
	#  ap_data{ 'netiq_specifics' }
	#  ap_data{ 'longmessage' }

    my $ap_data = {
                   'map_data'        => "",
                   'script'          => "",
                   'groupname'       => "",
                   'eventid'         => "",
                   'messagetext'     => "",
                   'host'            => "",
                   'severity'        => "",
                   'ticket'          => "",
                   'logfile'         => "",
                   'contact_device'  => "",
                   'behavior'        => "",
                   'netiq_severity'  => "",
                   'netiq_specifics' => "",
                   'longmessage'     => "",
                  };

    my $ap_data_got = get_alarmpoint_hash_structure();
    
    is_deeply ($ap_data_got, $ap_data, 'get_alarmpoint_hash_structure( ) should return blank alarmpoint data hash...');
    
    print Dumper $ap_data_got;
    
}

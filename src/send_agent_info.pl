###################################################################
#
#             File: send_agent_info.pl
#         Revision: 1.0
#
#           Author: Bill Dooley
#
#    Original Date: 11/03
#
#      Description: This program will send the agent.info data to
#                   then Managemet Server
#                   
#           Usage:  send_agent_info.pl  
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  11/03      wpd           <Initial Version>
#####################################################################

# ===================================================================
# Begining of Main
# ===================================================================

#
# Set up the standard variables
#
$platform = "$^O";
chomp ($platform);
use Getopt::Std;


print "Setting variables for $platform from setvar.pm\n";

if ( "$platform" eq "MSWin32" ) {
   $ov_dir = $ENV{"OvAgentDir"};
   if ( "$ov_dir" eq "" ) {
      $ov_dir = "c:\\usr\\OV";
   }
   require $ov_dir . "/bin/OpC/cmds/setvar.pm";
} elsif ( "$platform" eq "aix" ) {
   require "/var/lpp/OV/OpC/cmds/setvar.pm";
} else {
   require "/var/opt/OV/bin/OpC/cmds/setvar.pm";
}

$agent_file = $PWC_LOGS . "agent.info";
# print "Processing $agent_file\n";
open (agent_file, "$agent_file");
@info = <agent_file>;
close (agent_file);

foreach $rec (@info) {
   # print "Processing $rec";
   $rec =~ tr /\"\(/  /;
   $t1 = $t1 . $rec;
}

`$OpC_BIN/opcmsg a=VPPA o="Data Files" msg_grp=Transfer msg_text="$t1" sev=normal`;


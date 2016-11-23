###################################################################
#
#             File: nodestatus.sweep.pl
#         Revision: 1.00
#
#           Author: 
#
#    Original Date: 02/05
#
#      Description: This program will check the VPO Agent Status
#                   messages that had a delay configured for
#                   notification.  It will:
#                     1. Check if the agent is running fine.  if
#                        yes then remove the delay file and update
#                        the agent status file and exit.
#                     2. Send the agent notification if the agent
#                        is isn't running fine.  It will then update
#                        the delay file until the agent is running
#                        properly.
#                     3. If notification has already been sent it
#                        will check until the agent is running
#                        fine.  It will then update the agent
#                        status file and exit.
#
#           Usage:  nodestatus.sweep.pl  
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  02/05      wpd           <Initial Version>
#####################################################################


$version = "$0 version 1.00\n";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;
use File::Basename;

# ===================================================================
# Get Command Line Options
# ===================================================================

GetOptions(
            "t", "test",
            "v", "version",
            "h", "help",
            "d", "debug", "debugextensive"
          );

# ===================================================================
# Version check
# ===================================================================
if ( $opt_v or $opt_version ) { die $version }

if ( $opt_h or $opt_help ) {
  usage();
  die $version;
}

# ===================================================================
# Set up the standard variables
# ===================================================================
get_ssm_vars();

# ===================================================================
# Incorporate the common functions
# ===================================================================
get_ssm_common_functions();

# ===================================================================
# Check debug configuration
# ===================================================================

$DEBUG_EXTENSIVE_ON  = "$SSM_CONF" . "nodestatus.sweep.debugextensive";
$DEBUG_ON            = "$SSM_CONF" . "nodestatus.sweep.debug";

check_debug_settings($DEBUG_ON, $DEBUG_EXTENSIVE_ON);

# ===================================================================
# Begining of Main
# ===================================================================

if ( $opt_t or $opt_test ) {
  $debug = 1;
  $test  = 1;
  print "Running in Test Mode\n";
}

#
# Check to see if another instance of the program is running
# chk_running will exit if there is
#

$running_status = chk_running("nodestatus.sweep",N);

#
# Set up the standard variables
#

$vposend = $SSM_BIN . "vposend";
$now = time;
$disp_date = `date`;
chomp($disp_date);

#
# Set up the main loop
#

while ($loop == 0) {
   &chk_delay;
   &chk_agent;
   &chk_node;
   print "sleeping for 60 seconds\n";
   sleep 60;
}

sub chk_delay {
   #
   # Get all the delayed notification status files
   #

   @files = `$LL /esm/prod/nodestatus/status/*_delay_*`;

   foreach $file (@files) {
      chomp($file);
      $fname = basename($file);
      ($dummy,$fname) = split(/delay_/,$fname);
      $agt_file = "/esm/prod/nodestatus/status/" . $fname;
      print "$disp_date - nodestatus.sweep.pl - $fname - Checking agent for $fname\n";
      @agt_status = `$OpC_BIN/opcragt $fname 2>&1 |grep -v BBC`;
      @chk_run = grep(/isn't running/, @agt_status);
      $not_found =+ @chk_run;
      if ( $not_found > 0 ) {
         print "$disp_date - nodestatus.sweep.pl - $fname - Agent on $fname still isn't running\n";
         open (delay, "$file");
         @delay = <delay>;
         close(delay);
         $no_more_delay = "0";
         foreach $delay_rec (@delay) {
            chomp($delay_rec);
            ($delay_time,$delay_arg) = split(/--DELAY--/,$delay_rec);

            if ( $now >= $delay_time ) {
               print "$disp_date - nodestatus.sweep.pl - $fname - Sending notification for $fname with $delay_arg\n";
               if (!$test) {
                  `$vposend $delay_arg`;
               }
            } else {
               print "$disp_date - nodestatus.sweep.pl - $fname - Delay of notification is still active for $fname. $now vs $delay_time\n";
               $no_more_delay = "1";
               push (@delay_rec_new, "$delay_rec\n");
            }
         }
         if ( "$no_more_delay" eq "0" ) {
            print "$disp_date - nodestatus.sweep.pl - Removing Delay file $file\n";
            if (!$test) {
               unlink "$file";
            }
         } else {
            print "$disp_date - nodestatus.sweep.pl - Updating Delay file with:\n @delay_rec_new \n";
            if (!$test) {
               open (delay, ">$file");
               print delay ("@delay_rec_new");
               close(delay);
            }
         }
      } else {

         $addl_msg = "No notification will occur.";
         &update_agent_status;
   
         if (!$test) {
            unlink $file;
         }
      }
   }
} # end of chk_delay

sub chk_agent {
   #
   # Get all the status files that the node is up and agent has issues
   #

   @files = `grep -l partial /esm/prod/nodestatus/status/*`;
   
   foreach $file (@files) {
      chomp($file);
      if ($debug) { print "$disp_date - nodestatus.sweep.pl - Checking Agent in $file for availability\n"; }
      $fname = basename($file);
      $agt_file = $file;
      print "$disp_date - nodestatus.sweep.pl - $fname - Checking agent for $fname\n";
      @agt_status = `$OpC_BIN/opcragt $fname 2>&1 |grep -v BBC`;
      @chk_run = grep(/isn't running/, @agt_status);
      $not_found =+ @chk_run;
      if ( $not_found == 0 ) {
         $addl_msg = "Resetting status file.";
         &update_agent_status;
      }
   }
} # end of chk_agent

sub chk_node {
   #
   # Get all the status files that the node down
   #

   @files = `grep -l "Node_available = no" /esm/prod/nodestatus/status/*`;
   
   foreach $file (@files) {
      chomp($file);
      if ($debug) { print "$disp_date - nodestatus.sweep.pl - Checking $file for availability\n"; }
      $fname = basename($file);
      $agt_file = $file;
      print "$disp_date - nodestatus.sweep.pl - $fname - Checking availibility\n";
   
      @alive = `/usr/sbin/ping $fname 3 |grep "is alive"`;
      $alive =+ @alive;
   
      if ( $alive > 0 ) {
         print "$disp_date - nodestatus.sweep.pl - $fname is alive.\n";
         ($short_name,$dummy) = split(/\./, $fname);
         `$OpC_BIN/opcmsg a=nodestatus o=$fname msg_grp=esm msg_text="$short_name - Node is alive." node=$fname`;
         `/esm/prod/nodestatus/bin/nodestatus.delta --status=nodeup --node=$fname --agent_process=node --vpo_msgid="unknown" --group="esm" --sev="normal" --message="$short_name - Node is alive." node=$fname`;
         $addl_msg = "Node is alive";
         &update_agent_status;;
      }
   }
} # end of chk_node

sub update_agent_status {

   $node_status = "yes";
   $node_time = "$now";
   $agent_status = "yes";
   $agent_time = $now;
   $agent_daemon = "";
   $agent_retry = 0;
   $ping_status = "yes";
   $ping_time = "$now";

   print "$disp_date - nodestatus.sweep.pl - $fname - Agent is running fine for $fname. $addl_msg\n";

   if (!$test) {
      open (agt_file, ">$agt_file");

      print agt_file ("\[Node\]\n");
      print agt_file ("Node_available = $node_status\n");
      print agt_file ("Node_status = $node_time\n");
      print agt_file ("Node_monitored = yes\n");
      print agt_file ("\[Agent\]\n");
      print agt_file ("Agent_available = $agent_status\n");
      print agt_file ("Agent_status = $agent_time\n");
      print agt_file ("Agent_subprocess_failures = $agent_daemon\n");
      print agt_file ("Agent_subprocess_retry_attempt = $agent_retry\n");
      print agt_file ("\[Ping\]\n");
      print agt_file ("Ping_available = $ping_status\n");
      print agt_file ("Ping_status = $ping_time\n");

      close (agt_file);
   }

}
# ===================================================================
# End of Main
# ===================================================================

# ===================================================================
# Start of FUNCTIONS
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_ssm_vars()
#  this function is called to setup all standard variables.
# -------------------------------------------------------------------

$vposend = $SSM_BIN . "vposend";

sub get_ssm_vars {
   $platform = "$^O";
   chomp ($platform);
   
   if ( "$platform" eq "MSWin32" ) {
     # Windows Platform
     $ov_dir    = $ENV{"OvAgentDir"};
     
     if ( "$ov_dir" eq "" ) {
        $ov_dir = "c:\\usr\\OV";
     }
     
     require      $ov_dir . "/bin/OpC/cmds/setvar.pm";
     $vposend   = $ov_dir . "/bin/opc/cmds/vposend.exe";
      
    } elsif ( "$platform" eq "aix" ) {
     # AIX Platform  
     require      "/var/lpp/OV/OpC/cmds/setvar.pm";
     $vposend   = "/var/lpp/OV/OpC/cmds/vposend";
   
    } else {
     # Everything else, assume Solaris
     require      "/var/opt/OV/bin/OpC/cmds/setvar.pm";
     $vposend   = "/var/opt/OV/bin/OpC/cmds/vposend";
   }
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_ssm_common_functions()
#  this function is called to incorporate all ssm common functions
# -------------------------------------------------------------------
sub get_ssm_common_functions {
  
   my $ssm_common_functions_file = $SSM_BIN . "ssm_common.pm";
   
   if (-e $ssm_common_functions_file) {
      require $ssm_common_functions_file;
   }
   
   if ($debug) { print " Incorporated $ssm_common_functions_file\n"; }
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
USAGE\n
   nodestatus.sweep [-t] [-v] [-d] [-h]\n
";

}
# end of usage



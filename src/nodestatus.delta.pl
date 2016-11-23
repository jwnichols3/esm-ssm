###################################################################
#
#             File: nodestatus.delta.pl
#         Revision: 1.10
#
#           Author: Bill Dooley
#
#    Original Date: 08/03
#
#      Description: Update the Agent status files and call the 
#                   agent_notify program to perform the notification.
#                   
#           Usage:  nodestatus.delta --status=<status> --node=<node> --agent_process=<daemon>
#                     --vpo_msgid=<msg_id> --group=<grp> --sev=<sev> --message=<text>
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  02/05      wpd           <Initial Version>#
#
#  02/05     nichj    v1.01 changed options to qualified and
#                            did some minor code restructure
#
#  2005-07-19 nichj   v1.10 Moved to new apps esm directory structure
#                            incorporated server common libraries
#
#####################################################################

$version = "$0 version 1.10\n";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;

# ===================================================================
# Get Command Line Options
# ===================================================================

GetOptions(
            "status:s"        => \$status,
            "node:s"          => \$node,
            "agent_process:s" => \$daemon,
            "vpo_msgid:s"     => \$msgid,
            "group:s"         => \$grp,
            "sev:s"           => \$sev,
            "message:s"       => \$msgtext,
            "v", "version",
            "h", "help",
            "d", "debug", "debugextensive"
          );

chomp($node);
chomp($daemon);
chomp($msgid);
chomp($grp);
chomp($sev);
chomp($msgtext);


# ===================================================================
# Version check
# ===================================================================
if ( $opt_v or $opt_version ) { print "$version\n";
                                exit 0;  }

# ===================================================================
# Help Check
# ===================================================================
if ( $opt_h or $opt_help ) {
  usage();
  print "$version;\n";
  exit 0;
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
# Incorporate the server common functions
# ===================================================================
get_server_common_functions();

# ===================================================================
# Program Location Variables
# ===================================================================
$PGM_ROOT = "/apps/esm/nodestatus";
$PGM_CONF = "$PGM_ROOT/conf";
$PGM_LOGS = "$PGM_ROOT/logs";
$PGM_BIN  = "$PGM_ROOT/bin";
$PGM_LIB  = "$PGM_ROOT/lib";

# ===================================================================
# Check debug configuration
# ===================================================================

$DEBUG_EXTENSIVE_ON  = "$PGM_CONF" . "nodestatus.debugextensive"; 
$DEBUG_ON            = "$PGM_CONF" . "nodestatus.debug";         

check_debug_settings($DEBUG_ON, $DEBUG_EXTENSIVE_ON);


# ===================================================================
# Begining of Main
# ===================================================================

$now                    = time;
($sec,$min,$hour,$mday) = localtime(time);
$disp_date              = get_display_date();
chomp($disp_date);
$agt_file               = "$PGM_ROOT/status/" . $node;
$log_file               = "$PGM_LOGS/nodestatus.log";
$nodestatus_alert_pgm   = "$PGM_ROOT/bin/nodestatus.alert";

if ($debug) {
  print "Processing $agt_file for $status $node $daemon\n";
  print "\n";
  print " debug variables:\n";
  print "\n";
  print "  status  = $status\n";
  print "  node    = $node\n";
  print "  daemon  = $daemon\n";
  print "  msgid   = $msgid\n";
  print "  grp     = $grp\n";
  print "  sev     = $sev\n";
  print "  msgtext = $msgtext\n";
  print "\n";
}

@agt_file = read_file_contents($agt_file);

foreach $status_rec(@agt_file) {
  
   chomp($status_rec);
   
   ($rec_type, $rec_value) = split(/ \= /, $status_rec);
   
   print "Processing $rec_type $rec_value\n";
   
   if (      "$rec_type"     eq "Node_available" ) {
    
             $node_status    =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Node_status_epoch" ) {
    
             $node_time      =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Node_status_date" ) {
    
             $node_disp_tm   =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Node_monitored" ) {
    
             $node_monitored =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Agent_available" ) {
    
             $agent_status   =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Agent_status_epoch" ) {
    
             $agent_time     =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Agent_status_date" ) {
    
             $agent_disp_tm  =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Agent_subprocess_failures" ) {
    
             $agent_daemon   =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Agent_subprocess_retry_attempt" ) {
    
             $agent_retry    =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Ping_available" ) {
    
             $ping_status    =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Ping_status_epoch" ) {
    
             $ping_time      =  $rec_value;
      
   } elsif ( "$rec_type"     eq "Ping_status_date" ) {
    
             $ping_disp_tm   =  $rec_value;
      
   }
}

if ( "$status" eq "nodedown" ) {
  
   $node_status   = "no";
   $node_time     = $now;
   $node_disp_tm  = $disp_date;
   $ping_status   = "no";
   $ping_time     = $now;
   $ping_disp_tm  = $disp_date;
}

if ( "$status" eq "nodeup" ) {
  
   $node_status   = "yes";
   $node_time     = "$now";
   $node_disp_tm  = $disp_date;
   $agent_status  = "yes";
   $agent_time    = $now;
   $agent_disp_tm = $disp_date;
   $agent_daemon  = "";
   $agent_retry   = 0;
   $ping_status   = "yes";
   $ping_time     = "$now";
   $ping_disp_tm  = $disp_date;
}

if ( "$status" eq "agentdown" ) {
  
   $node_status   = "partial";
   $node_time     = $now;
   $node_disp_tm  = $disp_date;
   $agent_status  = "no";
   $agent_time    = $now;
   $agent_disp_tm = $disp_date;
   $agent_daemon  = "";
}

if ( "$status" eq "agentdegraded" ) {
  
   $node_status   = "partial";
   $node_time     = $now;
   $node_disp_tm  = $disp_date;
   $agent_status  = "degraded";
   $agent_time    = $now;
   $agent_disp_tm = $disp_date;
   $agent_daemon  = $agent_daemon . " " . $daemon;
}

if ( "$status" eq "agentup" ) {

   $node_status   = "yes";
   $node_time     = "$now";
   $agent_status  = "yes";
   $agent_time    = $now;
   $agent_disp_tm = $disp_date;
   $agent_daemon  = "";
   $agent_retry   = 0;
   $ping_status   = "yes";
   $ping_time     = "$now";
   $ping_disp_tm  = $disp_date;
}


if ( open (agt_file, ">$agt_file") ) {
  
  if ($debug) {
     print "Processing rewrite\n";
     print "\[Node\]\n";
     print "Node_available                 = $node_status\n";
     print "Node_status_epoch              = $node_time\n";
     print "Node_status_date               = $disp_date\n";
     print "Node_monitored                 = $node_monitored\n";
     print "\n\[Agent\]\n";
     print "Agent_available                = $agent_status\n";
     print "Agent_status_epoch             = $agent_time\n";
     print "Agent_status_date              = $disp_date\n";
     print "Agent_subprocess_failures      = $agent_daemon\n";
     print "Agent_subprocess_retry_attempt = $agent_retry\n";
     print "\n\[Ping\]\n";
     print "Ping_available                 = $ping_status\n";
     print "Ping_status_epoch              = $ping_time\n";
     print "Ping_status_date               = $disp_date\n";
  }
  
  print agt_file ("\[Node\]\n");
  print agt_file ("Node_available = $node_status\n");
  print agt_file ("Node_status_epoch = $node_time\n");
  print agt_file ("Node_status_date  = $disp_date\n");
  print agt_file ("Node_monitored = $node_monitored\n");
  print agt_file ("\n\[Agent\]\n");
  print agt_file ("Agent_available = $agent_status\n");
  print agt_file ("Agent_status_epoch = $agent_time\n");
  print agt_file ("Agent_status_date  = $disp_date\n");
  print agt_file ("Agent_subprocess_failures = $agent_daemon\n");
  print agt_file ("Agent_subprocess_retry_attempt = $agent_retry\n");
  print agt_file ("\n\[Ping\]\n");
  print agt_file ("Ping_available = $ping_status\n");
  print agt_file ("Ping_status_epoch = $ping_time\n");
  print agt_file ("Ping_status_date  = $disp_date\n");
  
  close (agt_file);
  
} else {
  
  die "ERROR: unable to open $agt_file: $!\n";
  
}

# 
# Call the nodestatus.alert program
#

if ($debug) { print "Adding msgtext to $PGM_ROOT/logs/nodestatus.log - $msgtext\n"; }

if (open LOGFILE, ">> $log_file") {
  print LOGFILE "$disp_date - $node - $status - $msgtext\n";
  close LOGFILE;
} else {
  warn "Problem opening $log_file: $!\n";
}

if ($debug) { print "Calling nodestatus.alert with --status=$status --node=$node --vpo_msgid=$msg_ID --group=$grp --sev=$sev --message=\"$msgtext\"\n"; }

$nodestatus_alert_params = "--status\"$status\" --node\"$node\" --vpo_msgid=\"$msg_id\" --group=\"$grp\" --sev=\"$sev\" --message=\"$msgtext\"";

#`$nodestatus_alert_pgm --status="$status" --node="$node" --vpo_msgid="$msg_id" --group="$grp" --sev="$sev" --message="$msgtext"`;
`$nodestatus_alert_pgm $nodestatus_alert_params`;

if ($debug) { print "Finished Calling $nodestatus_alert_pgm: $!\n"; }

exit 0;

# ===================================================================
# Start of FUNCTIONS
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_ssm_vars()
#  this function is called to setup all standard variables.
# -------------------------------------------------------------------

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
# Function: get_server_common_functions()
#  this function is called to incorporate all ssm common functions
# -------------------------------------------------------------------
sub get_server_common_functions {
   my $server_common_functions_file = "/apps/esm/lib/all_server_common.pl";
   
   if (-e $server_common_functions_file) {
      require $server_common_functions_file;
   }
   
   if ($debug) { print " Incorporated $server_common_functions_file\n"; }
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
Usage:  nodestatus.delta --status=<status> --node=<node> --agent_process=<daemon> \\
                         --vpo_msgid=<msg_id> --group=<grp> --sev=<sev> --message=<text>\n
";

}
# end of usage
# ===================================================================
# End of FUNCTIONS
# ===================================================================

###################################################################
#
#             File: nodestatus.alert.pl
#         Revision: 1.10
#
#           Author: Bill Dooley
#
#    Original Date: 08/03
#
#      Description: This program will check if/how the agent
#                   outage notificatoin should take place
#                   
#           Usage:  nodestatus.alert --status=<status> --node=<node> --vpo_msgid=<msg_id> 
#                      --group=<grp> --severity=<sev> --message=<msgtext>
#
# Revision History:
#
#  Date     Initials  Vers  Description of Change
#
#  02/05      wpd     1.00  <Initial Version>
#
#  02/05     nichj    1.01  Changed the options to be fully qualified
#                           Put functions at the bottom.
#
#  02/05     wpd      1.02  Fixed the issue that was stopping the a   
#                           node down from notification becuase the 
#                           agent=Yes is not configured.  The nodedow
#                           does not use this config value.
#  2005-07-19 nichj   1.10  Converted to use apps esm directory structure
#                            incorporated all server-side libraries
#
#####################################################################

$version = "$0 version 1.10\n";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;
use File::Basename;

# ===================================================================
# Get Command Line Options
# ===================================================================

GetOptions(
            "status:s"    => \$vpoType,
            "node:s"      => \$vpoNodeName,
            "vpo_msgid:s" => \$vpoMsgID,
            "group:s"     => \$vpoMsgGroup,
            "sev:s"       => \$vpoMsgSev,
            "message:s"   => \$vpoMsgText,
            "v", "version",
            "h", "help",
            "d", "debug", "debugextensive"
          );

#
# Set the VPO Variables standards
#
$vpoMsgGroup = lc($vpoMsgGroup);  # VPO Message Group Field
$vpoMsgSev   = lc($vpoMsgSev);    # VPO Message Severity

# ===================================================================
# Version check
# ===================================================================
if ( $opt_v or $opt_version ) { print "$version\n";
                                exit 0; }

if ( $opt_h or $opt_help ) {
  usage();
  print "$version\n";
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

#
# Set up the standard variables
#
$preface     = "nodestatus.alert $disp_date  $vpoMsgId -";

if ($debug) {
  print "\n debug variables:\n";
  print "  vpoType     = $vpoType\n";
  print "  vpoNodeName = $vpoNodeName\n";
  print "  vpoMsgID    = $vpoMsgId\n";
  print "  vpoMsgGroup = $vpoMsgGroup\n";
  print "  vpoMsgSev   = $vpoMsgSev\n";
  print "  vpoMsgText  = $vpoMsgText\n\n";
}

%opts = (
   "a" => { cl => "-a", lf => "app=", },
   "N" => { cl => "-N", lf => "node=" },
   "n" => { cl => "-n", lf => "nodestatustype=" },
   "A" => { cl => "-A", lf => "action=" },
   "s" => { cl => "-s", lf => "sev=" },
   "z" => { cl => "-s", lf => "severity=" },
   "D" => { cl => "-D", lf => "description=" },
   "M" => { cl => "-M", lf => "delay=" },
   "G" => { cl => "-G", lf => "agent=" },
   "H" => { cl => "-H", lf => "start=" },
   "J" => { cl => "-J", lf => "stop=" },
   "d" => { cl => "-d", lf => "dayofweek=" },
   "c" => { cl => "-c", lf => "correlation=" },
);

#
# Set Time Variables
#
$now                    = time;
($sec,$min,$hour,$mday) = localtime($time);
$disp_date = get_display_date();

#
# Agent Notification Variables
#

$agtLogFile          = "$PGM_LOGS/nodestatus.alert.log";   

#
# If the debug file exists, then write debug information to the LogFile
#

if ($debug) {
    open  (AGTLOGFILE, ">>$agtLogFile");
    print "Starting debug processing\n";
    print  AGTLOGFILE ("\n\n$disp_date -- start debug --\n"); 
}

if ($debug_extensive) {
   print AGTLOGFILE ("\n ** extensive debugging on **\n");
}


if ($debug) {	
   print AGTLOGFILE ("\n");
   print AGTLOGFILE ("$preface  =  =  =  =  =  =  =  Starting Debug  =  =  =  =  =  =  =  = \n");
   print AGTLOGFILE ("$preface Parameter Name:    Passed Variables / Assigned Variables\n");
   print AGTLOGFILE ("$preface Type:              $vpoType / $vpoType\n");
   print AGTLOGFILE ("$preface Node name:         $vpoNodeName / $vpoNodeName\n");
   print AGTLOGFILE ("$preface Message Group:     $vpoMsgGroup / $vpoMsgGroup\n");
   print AGTLOGFILE ("$preface Severity:          $vpoMsgSev / $vpoMsgSev\n");
   print AGTLOGFILE ("$preface Message Text:      $vpoMsgText / $vpoMsgText\n");
}

#
# Check if Notfication Configuration has been set up for Node name
#

($chk_node, $dummy) = split(/\./, "$vpoNodeName");

$cfg_type = "nodestatustype=" . $vpoType;

@notify_recs   = `grep $chk_node $PGM_CONF/nodestatus.dat.* | grep $cfg_type`;
$notify_found += @notify_recs;

if ($debug_extensive) {
  
   print AGTLOGFILE ("$preface  variable notify_found = $notify_found\n");
   
   foreach $recfound (@notify_recs) {
      print AGTLOGFILE ("$preface  variable notify_recs = $recfound\n");
   }
   
}

if ( $notify_found > 0 ) {

   foreach $notify_record (@notify_recs) {
    
      ($filename,$notify_rec) = split(/\:/,$notify_record);
      
      $short_filename = basename($filename);
      
      chomp($notify_rec);
      
      if ($debug) {	print AGTLOGFILE ("$preface Processing notify record for $chk_node from $filename\n"); }
      
      &get_notification;
      
      &send_notification;
      
   }
   
} else {
   
   if ($debug) { print AGTLOGFILE ("$preface No $cfg_type Notification Configuration record exists for $chk_node.\n"); }
   
   $app         = $vpoMsgGroup;
   $node        = $vpoNodeName;
   $sev         = $vpoMsgSev;
   $desc        = "$node Agent Notification";
   $delay       = 0;
   $start       = 0;
   $stop        = 24;
   $correlation = "";
   
}

if ($debug) {	
   print AGTLOGFILE ("\n");
   print AGTLOGFILE ("$preface  =  =  =  =  =  =  =   Ending  Debug  =  =  =  =  =  =  =  = \n");
   close (AGTLOGFILE) or die "Unable to close $debugFile: $!\n";
}


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
  
Usage:  nodestatus.alert --status=<status> --node=<node> --vpo_msgid=<msg_id> --group=<grp> --sev=<sev> --message=<msgtext>\n

";

}
# end of usage
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
sub send_notification {
   

   if ($debug_extensive) { print AGTLOGFILE ("\n$preface -v-v- start  send_notification sub -v-v-\n"); }

   #
   # Call vposend to perform notification
   #

   $vposend = $SSM_BIN . "vposend";

   print "node = $node - $vpoNodeName\n";
   
   $vposend_rec = "-a \"$app\" -s $sev -m \"$vpoMsgText\" -n $vpoNodeName -t \"Agent Status\"";
   
   if ( "$action" ne "" ) {
     
      if ($debug_extensive) { print AGTLOGFILE ("$preface  variable action = $action\n"); }
      
      $vposend_rec = $vposend_rec . " -A " . $action;
         
   }

   if ($debug) { print AGTLOGFILE ("$preface Calling vposend with $vposend_rec.\n"); }

   if ( $delay == 0 ) {
        
      print "$vposend $vposend_rec \n";
         
      `$vposend $vposend_rec`;
         
      if ( $? == 0 ) {
          
         if ($debug) {	print AGTLOGFILE ("$preface Call to vposend completed successfully.\n"); }
            
      } else {
          
         if ($debug) {	print AGTLOGFILE ("$preface Call to vposend failed.\n"); }
      }
      
   } else {
      # 
      # Create a delay file for processing later
      #

      $delay_file = "$PGM_ROOT/status/" . $short_filename . "_delay_" . $vpoNodeName;
         
      print AGTLOGFILE ("$preface Delaying Notification for $node for $delay minutes - $delay_file\n");
         
      $delay      = $time + ($delay * 60);
         
      print AGTLOGFILE ("$preface Original time = $time New time = $delay.\n");

      $delay_rec  = $delay . "--DELAY--" . $vposend_rec;
         
      open  (delay_file, ">>$delay_file");
      print  delay_file ("$delay_rec\n");
      close (delay_file);
         
   }

   if ($debug_extensive) { print AGTLOGFILE ("\n$preface -^-^-  end  send_notification sub -^-^-\n"); }

}
# end of send_notification subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#
# Get Nofication Configuration
#

sub get_notification {

  if ($debug_extensive) { print AGTLOGFILE ("\n$preface -v-v- start get_notification sub -v-v-\n"); }

  # 
  # Get the configuration from the file
  #

  $app = $node = $action = $sev = $desc = $delay = $start = $stop = $dayofweek = $correlation = "";

  @fargs = $notify_rec;
  
  foreach $o ( keys %opts ) {
    
    $fargs[$fidx] =~ s/$opts{$o}{lf}/\t$opts{$o}{cl}\t/i;
    
  }

  #
  # Strip leading spaces from each argument
  #
  $fargs[$fidx]   =~ s/^\s*//;

  #
  # Get the arguments from the configuration record into a standard array
  #
  @PARMS          =  split /\t/,$fargs[$fidx];

  #
  # Process the argument array
  #

  foreach $a (@PARMS) {
     #
     # Strip leading AND trailing spaces per field ...arrrg
     #
     
     $a =~ s/^\s*(.*?)\s*$/$1/;
     
     if ( $arg_cnt == 1 ) {
        #
        # Set the variables used for processing
        #
        if ($debug_extensive) { print AGTLOGFILE ("$preface  processing arg $agtnotify_arg value = $a\n"); }
        
        if ( "$agtnotify_arg" eq "-a" ) { $app            = lc($a); }
        if ( "$agtnotify_arg" eq "-N" ) { $node           = $a;     }
        if ( "$agtnotify_arg" eq "-n" ) { $nodestatustype = $a;     }
        if ( "$agtnotify_arg" eq "-A" ) { $action         = $a;     }
        if ( "$agtnotify_arg" eq "-s" ) { $sev            = $a;     }
        if ( "$agtnotify_arg" eq "-z" ) { $sev            = "$a";   }
        if ( "$agtnotify_arg" eq "-D" ) { $desc           = "$a";   }
        if ( "$agtnotify_arg" eq "-M" ) { $delay          = lc($a); }
        if ( "$agtnotify_arg" eq "-H" ) { $start          = "$a";   }
        if ( "$agtnotify_arg" eq "-J" ) { $stop           = lc($a); }
        if ( "$agtnotify_arg" eq "-d" ) { $dayofweek      = lc($a); }
        if ( "$agtnotify_arg" eq "-c" ) { $correlation    = $a;     }
        
        $arg_cnt = 0;
        
     } else {
      
        $arg_cnt       = 1;
        $agtnotify_arg = $a;
        
     }
  }

  #
  # If this is a return to nomal then do not use config file severity
  #
  
  if ("$vpoMsgSev" eq "normal" ) {
     $sev = $vpoMsgSev;
  }

  if ($debug_extensive) {
     print AGTLOGFILE ("$preface  variable app            = $app\n");
     print AGTLOGFILE ("$preface  variable node           = $node\n");
     print AGTLOGFILE ("$preface  variable nodestatustype = $nodestatustype\n");
     print AGTLOGFILE ("$preface  variable action         = $action\n");
     print AGTLOGFILE ("$preface  variable sev            = $sev\n");
     print AGTLOGFILE ("$preface  variable desc           = $desc\n");
     print AGTLOGFILE ("$preface  variable delay          = $delay\n");
     print AGTLOGFILE ("$preface  variable start          = $start\n");
     print AGTLOGFILE ("$preface  variable stop           = $stop\n");
     print AGTLOGFILE ("$preface  variable dayofweek      = $dayofweek\n");
     print AGTLOGFILE ("$preface  variable correlation    = $correlation\n");

  }

  if ("$start" eq "")   {
     $start = "00";
  }
  
  if ("$stop" eq "")    {
     $stop  = "24";
  }
  
  if ($desc eq "")      {
     $desc  = "$node Agent Notifcation";
  } else {
     $desc  = "$desc Agent Notifcation";
  }
  
  chomp($sev);
  if ( "$sev" eq "" )   {
     $sev   = "major";
  }
  if ( "$sev" ne "critical" && "$sev" ne "major" && "$sev" ne "minor" && "$sev" ne "warning" && "$sev" ne "normal") {
    
     $sev   = "major";
     
  }
  
  chomp($delay);
  if ( "$delay" eq "" ) {
     $delay = "0";
  }
  
   #
   # Check if within start and stop monitor times
   #
   # If stop time is > than start time then add 24 hours to stop
   # time and to the hour to handle next day processing.
   #
   if ($stop < $start)  {
    
      if ($stop < $hour) {
        
         $stop = $stop + 48;
         
      } else {
        
         $stop = $stop + 24;
         
      }
      
      $hour = $hour + 24;
   }

   # print "check for $start $stop $hour \n";
   if (($hour >= $start) && ($hour < $stop)) {
    
      print AGTLOGFILE ("$preface Checking Notification for $node\n");
      
   } else {
    
      print AGTLOGFILE ("$preface No check for $desc.  Out of time range.  $start-$stop for $node\n");
      
      if ($debug) {	
         print AGTLOGFILE ("\n");
         print AGTLOGFILE ("$preface  =  =  =  =  =  =  =   Ending  Debug  =  =  =  =  =  =  =  = \n");
         close (AGTLOGFILE) or die "Unable to close $debugFile: $!\n";
      }
      
      exit 0;
   }
   
   
   if ($debug_extensive) { print AGTLOGFILE ("\n$preface -^-^-  end  get_notification sub -^-^-\n"); }

}
# end of get_notification subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

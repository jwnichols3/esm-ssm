###################################################################
#
#             File: nodestatus.clean_up.pl
#         Revision: 1.10
#
#           Author: Bill Dooley
#
#    Original Date: 02/05
#
#      Description: This program will check for 
#                    - nodes that are added to VPO
#                      - Create the status file for the nodestatus
#                        processing.
#                    - nodes that are deleted from VPO
#                      - Remove the status file for the nodesatus
#                        processing.
#                   
#           Usage:  nodestatus.clean_up.pl  
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  02/05      wpd           <Initial Version>
#  2005-07-19 nichj    1.10 Moved to apps esm directory structure
#                            incorporated global server-side libraries
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

$DEBUG_EXTENSIVE_ON  = "$PGM_CONF" . "nodestatus.clean_up.debugextensive"; 
$DEBUG_ON            = "$PGM_CONF" . "nodestatus.clean_up.debug";         

check_debug_settings($DEBUG_ON, $DEBUG_EXTENSIVE_ON);

# ===================================================================
# Begining of Main
# ===================================================================

if ( $opt_t or $opt_test ) {
  $debug = 1;
  $test  = 1;
  print "Running in Test Mode\n";
} 

$PGM_STATUS = "$PGM_ROOT/status";

$new_file = "$PGM_LOGS/ovo_nodes";
$old_file = "$PGM_LOGS/ovo_nodes.old";

if ( -f "$new_file" ) {
   `mv $new_file $old_file`;
} else {
   `touch $old_file`;
}

$disp_date = get_display_date();

#
# Get the nodes from VPO
#

system "($OpC_BIN/utils/opcnode -list_nodes | grep Name | sort > $new_file)";

#
# Get which nodes have been added or deleted
#

@diff = `diff $new_file $old_file`;

@old = grep(/\>/, @diff);
@new = grep(/\</, @diff);

#
# Create status file for all new nodes
#

foreach $newrec(@new) {
   chomp($newrec);
   ($dummy, $node) = split(/ = /, $newrec);
   $node_file = "$PGM_STATUS/$node";
   $temp_file = "$PGM_STATUS/new";

   if (!$test) {
      `echo $disp_date - The node $node has been added to the nodestatus monitoring. >> $PGM_LOGS/nodestatus.node.log`;

      if ($debug) { print "Checking if status file for $node already exists - $node_file\n"; }
      if ( -f "$node_file" ) {
         if ($debug) { print "Status file already exists for $node\n"; }
      } else {
         `cp -p $temp_file $node_file`;
         if ($debug) { print "Create status file for $node\n"; }
      }

   }
}

#
# Remove status file for all deleted nodes
#

foreach $newrec(@old) {
   chomp($newrec);
   ($dummy, $node) = split(/ = /, $newrec);
   if ($debug) { print "Delete status file for $node\n"; }
   if (!$test) {
      `echo $disp_date - The node $node has been removed from the nodestatus monitoring. >> $PGM_LOGS/nodestatus.node.log`;
      `rm -f $PGM_STATUS/$node`;
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
USAGE\n
";

}
# end of usage


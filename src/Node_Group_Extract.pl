###################################################################
#
#             File: Node_Group_Extract.pl
#         Revision: 1.01
#
#           Author: Bill Dooley
#
#    Original Date: 02/05
#
#      Description: This program will extract nodes from the passed
#                   node group for the nodestatus.config_populate
#                   program
#                   
#           Usage:  Node_Group_Extract -group=<vpo node group> [-group=<second vpo node group>] -h -v -d -t
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  02/05      wpd           <Initial Version>
#
#  02/2005   nichj         v1.01 - added ability to pass multiple node groups searched
#####################################################################


$version = "$0 version 1.01\n";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;
use File::Basename;

# ===================================================================
# Get Command Line Options
# ===================================================================

GetOptions(
            "group:s" => \@group,
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

$DEBUG_EXTENSIVE_ON  = "$SSM_CONF" . "Node_Group_Extract.debugextensive";
$DEBUG_ON            = "$SSM_CONF" . "Node_Group_Extract.debug";

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
# Set up local variables
#

$ovo_ng_info = $PWC_LOGS . "ovo_ng_info";

#
# Extract Node information from ITO
#

foreach $group_name (@group) {
  
  chomp($group_name);

  @nodedata = `/opt/OV/bin/OpC/utils/opcnode -list_ass_nodes group_name="$group_name" |grep Name`;

  if ($debug) { print "Nodes for $group are:\n @nodedata\n"; }
  
  foreach $node(@nodedata) {
    
     chomp($node);
     ($dummy,$node_name) = split(/ = /,$node);
     print "$node_name\n";
     
  }
  
}

exit 0;

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

Node_Group_Extract -group=<vpo node group> [-group=<second vpo node group>] -h -v -d -t
     
  options:
  -group: the VPO node group to list.  If more than one node group is needed add a second \"-group=\"
  
  -t:     test
  -d:     debug
  -h:     help and usage (this screen)
  
     
";

}
# end of usage
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ===================================================================
# End of Functions
# ===================================================================

# ===================================================================
# Developer's Notes
#  insert any comments or thought processes here
# ===================================================================



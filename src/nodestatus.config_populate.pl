###################################################################
#
#             File: nodestatus.config_populate.pl
#         Revision: 1.10
#
#           Author: 
#
#    Original Date: 02/05
#
#      Description: This program will exectute the configured
#                   program to extract the nodes for the passed
#                   application.
#                   
#           Usage:  nodestatus.config_populate.pl [-t] [-v] [-d] [-h]
#                           -group=<group to populate>
#
#           Files:  /esm/prod/nodestatus/conf/nodestatus.dat.<app name>
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  02/05      wpd           <Initial Version>
#
#  02/05     nichj          1.01 - commented out the records other than
#                             nodedown & agentdown.  Changed severities.
#  2005-07-19 nichj   1.10  Moved to apps esm directory structure
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
            "group:s" => \$group,
            "t", "test",
            "v", "version",
            "h", "help",
            "d", "debug", "debugextensive"
          );

# ===================================================================
# Version check
# ===================================================================
if ( $opt_v or $opt_version ) { print "$version\n";
                                exit 0;            }

# ===================================================================
# Usage check
# ===================================================================
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

$DEBUG_EXTENSIVE_ON  = "$PGM_CONF" . "nodestatus.config_populate.debugextensive"; 
$DEBUG_ON            = "$PGM_CONF" . "nodestatus.config_populate.debug";         

check_debug_settings($DEBUG_ON, $DEBUG_EXTENSIVE_ON);


# ===================================================================
# Begining of Main
# ===================================================================

if ( $opt_t or $opt_test ) {
  $debug = 1;
  $test  = 1;
  print "Running in Test Mode\n";
}

$config_file = "$PGM_CONF/nodestatus.config_populate.dat";

#
# Get the configuration records for the population
#

if ( "$group" eq "" ) {
  
   @config = read_file_contents($config_file);
   
} else {
  
   $group  = lc("$group");
   
   if ($debug) { print "Retrieving config records from $config_file for group=$group\n"; }
   
   @config = `grep "group=$group" $config_file`;
}

#
# Set up the hash array for the configuration records
#

%opts = (
   "p" => { cl => "-p", lf => "program=", },
   "a" => { cl => "-a", lf => "group=" },
   "r" => { cl => "-r", lf => "params=" },
);

foreach $config(@config) {
   chomp($config);
   if ($debug) { print "Processing config record $config\n"; }
   get_nodes($config);
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
nodestatus.config_populate is used to populate the default records for
the major Infrastructure groups: UNIX, Windows, Sybase, MS-SQL.

Parameters:
   nodestatus.config_populate [-v] [-h] [-t] [-d] [-group=<group to populate>]

-v: version
-h: help (this screen)
-t: test mode
-d: debug

Other files:
  The nodestatus.config_populate.dat file holds the method to get the list of
  nodes.
  
";

}
# end of usage
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
sub get_nodes {
   if ($debug) { 
      print "============================================================\n";
      print "Start get_nodes function\n";
      print "============================================================\n";
   }

   my @config_rec  = @_;
   my $config_rec  = $config_rec[0];

   $group          = $program = $params = "";

   @fargs          = $config_rec;

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
      # Strip leading AND trailing spaces per field
      #
 
      $a = trim($a);
 
      if ( $arg_cnt == 1 ) {
         #
         # Set the variables used for processing
         #
 
         if ( "$config_arg" eq "-p" ) { $program        = $a;     }
         if ( "$config_arg" eq "-a" ) { $group          = lc($a); }
         if ( "$config_arg" eq "-r" ) { $params         = $a;     }

         if ($debug_extensive) { print "processing arg $config_arg value = $a\n"; }
 
         $arg_cnt = 0;
 
      } else {
 
         $arg_cnt    = 1;
         $config_arg = $a;
      }
      
   }
   
   if ($debug) { 
      print "============================================================\n";
      print "End get_nodes function\n";
      print "============================================================\n";
   }
   
   @nodes            = nodestatus_config_extract($program,$params);

   #
   # Maintain the nodestatus configuration files
   #

   if ($debug_extensive) { 
      print "Nodes to be processed for $group are:\n"; 
      print "@nodes \n";
   }
  
   foreach $node(@nodes) {
    
      chomp($node);
      nodestatus_populate($node,$group);
      
   }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
sub nodestatus_config_extract {
   if ($debug) { 
      print "============================================================\n";
      print "Start nodestatus_config_extract function\n";
      print "============================================================\n";
   }

   my $program    = shift;
   my $params     = shift;
   my $cmd        = $program . " " . $params;

   if ($debug) { print "Run program $cmd\n"; }

   my @nodes = `$cmd`;

   if ($debug) { 
      print "============================================================\n";
      print "End nodestatus_config_extract function\n";
      print "============================================================\n";
   }
   
   return @nodes;
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
sub nodestatus_populate {
   if ($debug) { 
      print "============================================================\n";
      print "Start nodestatus_populate function\n";
      print "============================================================\n";
   }

   my $node        = shift;
   my $group       = shift;
   my $config_file = "$PGM_CONF/nodestatus.dat." . $group;

   if ($debug) { print "Checking if $node already exists in $config_file\n"; }

   if ( -f "$config_file" ) {
    
      if ($debug) { print "The config file $config_file already exists\n"; }
      
   } else {
    
      if ($debug) { print "Creating the config file $config_file\n"; }
      `cp -p $PGM_CONF/nodestatus.dat.template "$config_file"`;
      #
      # Create the VPO node group
      # 
      # if ($debug) { print "Creating the config records for $node\n"; }
      # `$OpC_BIN/opcnode -add_group group_name="$group" group_label="$group"`;
   }

   # NichJ - commenting out nodeup, agentup, and agentdegraded
   #
   $node_config_rec_down      = "node=" . $node . " app=" . $group . " sev=major nodestatustype=nodedown";
   #$node_config_rec_up        = "node=" . $node . " app=" . $group . " sev=major nodestatustype=nodeup";
   $agent_config_rec_down     = "node=" . $node . " app=" . $group . " sev=minor nodestatustype=agentdown";
   #$agent_config_rec_up       = "node=" . $node . " app=" . $group . " sev=major nodestatustype=agentup";
   #$agent_config_rec_degraded = "node=" . $node . " app=" . $group . " sev=major nodestatustype=agentdegraded";

   @found = `grep $node \"$config_file\"`;
   $found =+ @found;

   if ($found == 0) {
    
      if ($debug) { print "Creating the config records for $node\n"; }
      
      `echo $node_config_rec_down      >> "$config_file"`;
      `echo $node_config_rec_up        >> "$config_file"`;
      `echo $agent_config_rec_down     >> "$config_file"`;
      `echo $agent_config_rec_up       >> "$config_file"`;
      `echo $agent_config_rec_degraded >> "$config_file"`;
      `echo "" >> "$config_file"`;
      
      #
      # Assign the node to the VPO node group
      # 
      # if ($debug) { print "Creating the config records for $node\n"; }
      # `$OpC_BIN/opcnode -assign_node group_name="$group" node_name="$node" label="$node" net_type="NETWORK_IP"`;
   }

   if ($debug) { 
      print "============================================================\n";
      print "End nodestatus_populate function\n";
      print "============================================================\n";
   }
   
   return @nodes;
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# ===================================================================
# End of Functions
# ===================================================================

# ===================================================================
# Developer's Notes
#  insert any comments or thought processes here
# ===================================================================

###################################################################
#
#             File: chk_conf_files.pl
#         Revision: 1.10
#
#           Author: Bill Dooley
#
#    Original Date: 08/02
#
#      Description: Checks the VPO configuration files to determine
#                   if it they need updating.
#                   
#           Usage:  chk_conf_files.pl
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  08/02      wpd           <Initial Version>
#  11-2004   nichj          Added powerpath.dat.san file to the mix
#                           Redid first part of program with standard template
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
           "v", "version",
           "h", "help",
           "d", "debug",
           "test"
          ); 

# ===================================================================
# Version Check
# ===================================================================
if ( $opt_v or $opt_version ) { print "$version";
                                exit 0;           }

# ===================================================================
# Help Check
# ===================================================================
if ( $opt_h or $opt_help ) {
  usage();
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
# Determine Debug settings
# ===================================================================
## Calling the check_debug_settings will evaluate the command line options and the debug files
## $debug and/or $debug_extensive are set to true if the corresponding setting is true

# BE SURE TO CHANGE THE DEBUG TRIGGER FILE
$DEBUG_FILENAME           = "chk_conf_files.debug";
$DEBUG_EXTENSIVE_FILENAME = "chk_conf_files.debugextensive";                    
check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");

# ===================================================================
# ===================================================================
# Begining of Main
# ===================================================================
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
$status_file = "$SSM_LOGS" . "chk_conf_files.status";
status_report("$program_description", "$status_file", "start");

$conf_file = $OpC_CMD . "conf_files.dat";

@conf_dat  = read_file_contents("$conf_file");

chdir "$SSM_BIN";

foreach $conf_dat (@conf_dat) {
   #
   # Get the configuration file and the final destination
   #
   ($conf_file, $conf_loc) = split(/ /,$conf_dat);
   if ( -e $conf_file) {
      chomp($conf_loc);
      print "Processing $conf_file to $conf_loc\n";
      &chk_update;
   }
}

status_report("$program_description", "$status_file", "end_pass");
   
print "\n$program_description completed successfully\n";

exit 0;

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# ===================================================================
# ===================================================================
# End of Main
# ===================================================================
# ===================================================================


# ===================================================================
# Beginning of Functions
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#  function: chk_update
#   This function is the main processor for this program.

sub chk_update {

   # 
   # get the last modified time for the configuration file
   #
   $mtime = (stat ("$conf_file"))[9];


   #
   # get the time from the configuration file chk file and
   # determine if a different file has been created.
   #
   $chk_file = $conf_file . "\.chk";

   if ( -e "$chk_file" ) {
      
      open (conf_chk, "$chk_file");
      @conf_chk     = <conf_chk>;
      $chk_time     = $conf_chk[0];
      chomp($chk_time);
      close (conf_chk);

      # print "Checking $chk_file.  Mtime=$mtime.  Check=$chk_time.\n";
      if ($chk_time != $mtime) {
         #
         # Move the new file to its final destination
         #
         print "Updating $conf_file to $conf_loc\n";
         `$CP $conf_file $conf_loc`;
         chown ("esm", "$conf_log$conf_file");
      }
      
   } else {
      
      #
      # Install the initial file to its final destination
      #
      print "Installing $conf_file to $conf_loc\n";
      `$CP $conf_file $conf_loc`;
      chown ("esm", "$conf_log$conf_file");
      
   }

   #
   # Update the hold file with the modify time of the VPO monitor file
   #

   # print "Updating $chk_file with $mtime\n";
   open  (conf_chk, ">$chk_file");
   print  conf_chk ("$mtime\n");
   close (conf_chk);
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
This program checks the configuration files found in conf_files.dat and makes sure they are
in the conf directory.

Runtime options include:
-d(ebug)   - turn on debug.
-h(elp)    - display this screen.
-v(ersion) - display version.
\n
";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

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
   
   debug_out(" Incorporated $ssm_common_functions_file");
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: debug_out($text)
#  this function is called to output debug text if debug is on
# -------------------------------------------------------------------
sub debug_out {
   my $output = $_[0];
   
   if ($debug) {
      print "$output\n";
   }
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ===================================================================
# End of Functions
# ===================================================================

# ===================================================================
# Developer's Notes
#  insert any comments or thought processes here
# ===================================================================
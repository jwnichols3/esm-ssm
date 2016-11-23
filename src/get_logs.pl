###################################################################
#
#             File: get_logs.pl
#         Revision: 2.50
#
#           Author: Bill Dooley
#
#    Original Date: 08/02
#
#      Description: This program will return the names of the ssm
#                   logfiles that are to be monitored.
#
#            Notes:  The output of this program should be just the list of
#                    logfiles.
#                   
#           Usage:  get_logs
#
#       Conf File:  $OpC_CMD/ssm_logfiles.dat
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  08/02      wpd           <Initial Version>
#  06-2004    jwn           Converted to SSM variables
#
#  2005-04-12 nichj   2.50: Applied latest ssm_header
#                           Converted to using get_config_files()
#                           Cleaned up the functionality.
#                           Converted from using touch to a create file function.
#  2005-04-18 nichj   rev 1 added debug options.
#
#####################################################################

$version = "$0 version 2.50 rev 1\n";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;

# ===================================================================
# Get Command Line Options
# ===================================================================
GetOptions( "v", "version",
            "h", "help",
            "d", "debug", "debugextensive"
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
#
### Because the output of this program should be quiet, the debug settings are
### switched off.
$DEBUG_FILENAME           = "get_logs.debug";                        
$DEBUG_EXTENSIVE_FILENAME = "get_logs.debugextensive";               
check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");


# ===================================================================
# ===================================================================
# Begining of Main
# ===================================================================
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

## Check for the default logfile list
## 
$ssm_logfiles_source = $SSM_BIN  . "ssm_logfiles.dat";
$ssm_logfile_default = $SSM_CONF . "ssm_logfiles.dat";

if ( !-e "$ssm_logfile_default" ) {
  if ($debug)                                                        { print " $ssm_logfile_default is not found. Copying from source\n"; }
   `$CP $ssm_logfiles_src $ssm_logfile_default`;
}

## Get the list of configuration files (ssm_logfile.dat.*)
##
@ssm_logfiles = get_config_files("ssm_logfiles");

## For each logfile, read the contents into an array
##
foreach $file (@ssm_logfiles) {
  if ($debug)                                                        { print " adding $file to ssm_logfiles array\n"; }
  push (@ssm_logfile_list, read_file_contents("$file"));
}

## For each entry, make sure the logfile exists, check for a clean entry
##
foreach $logfile (@ssm_logfile_list) {
   chomp($logfile);
   $logfile =~ s/ /\\ /g;
   
   ## If the logfile doesn't exist, then create it.
   ##
   if ( -e "$logfile" ) {
    if ($debug)                                                      { print " $logfile exists\n"; }

      $logs    =  $logs . $logfile . " ";
      next;
      
   } else {

      ## Only add the logfile to the list if it can be created.
      if ($debug)                                                    { print " $logfile does not exist\n" }
      if ( create_logfile("$logfile") ) {
         
         $logs    =  $logs . $logfile . " ";
        if ($debug)                                                  { print " $logfile created\n" }
         
      }
         
   }
   
}

# Output the valid logfile names in a format that the VPO agent will read.
print "$logs\n";


exit 0;

# ===================================================================
# Beginning of Functions
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: create_logfile(@logfile)
#  this function creates a logfile (or logfiles) with nothing in it.
# -------------------------------------------------------------------
sub create_logfile {
   my @logfile_names = @_;
   my $logfile       = "";
   my $PROBLEM       = 0;
   my $OKAY          = 1;
   
   if (@logfile_names  eq "") {
      return $PROBLEM;
   }
   
   for $logfile (@logfile_names) {
      
      open (LOGFILE_TO_CREATE, ">> $logfile") || return $PROBLEM;
      print LOGFILE_TO_CREATE "\n";
      close LOGFILE_TO_CREATE
      
   }
   
   return $OKAY;
   
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
        $ov_dir = "c:/usr/OV";
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

# ===================================================================
# End of Functions
# ===================================================================

# ===================================================================
# Developer's Notes
#  insert any comments or thought processes here
# ===================================================================

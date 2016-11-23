###################################################################
#
#             File: status_reporting.pl
#         Revision: 1.10
#
#           Author: John Nichols
#
#    Original Date: 2005-03-22
#
#      Description: This program takes parameters of
#                    --status=pass|fail
#                    --file=status file
#                    --fail_reason=reason to log as failure
#                    --program=program description
#                    --sleep=nn where nn is the number of seconds to sleep between
#                               start and end
#                   
#                       the default status is pass
#                       the default file is status.log
#                       the default fail_reason is "fail reason not set"
#                       the default sleep is 15 seconds
#
#           Output: the output will show you if an alert should be sent and other data
#
# Revision History:
#
#  Date     Initials  Vers  Description of Change
#
#  2005-03-22 nichj   1.00  <Initial Version>
#
#  2005-03-30 nichj   1.10  Added sleep count and program description options
#
######################################################################

$version = "$0 version 1.10\n";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;

# ===================================================================
# Get Command Line Options
# ===================================================================
GetOptions(
            "status:s"      => \$status,
            "fail_reason:s" => \$fail_reason,
            "file:s"        => \$status_file,
            "program:s"     => \$program_description,
            "sleep:n"       => \$sleep_time,
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
# Start of MAIN
# ===================================================================

##
## Defaults
##
if ($status              eq "")     { $status              = "pass";                        }

if ($status_file         eq "")     { $status_file         = "status.log";                  }

if ($program_description eq "")     { $program_description = "Program description not set"; }

if ($sleep_time          eq "")     { $sleep_time          = 15;                            }

##
## Main if statement
##
if      ($status         eq "pass") {
  
  status_report("$program_description", "$status_file", "start");
  
  sleep $sleep_time;
  
  status_report("$program_description", "$status_file", "end_pass");

} elsif ($status         eq "fail") {

  if ($fail_reason  eq "") { $fail_reason    =  "fail reason not set";  }

  status_report("$program_description", "$status_file", "start");
  
  sleep $sleep_time;
  
  status_report("$program_description", "$status_file", "end_fail", "$fail_reason");

} else {
  
  print "\nError: The status is not set to pass or fail.\n\n";
  
}

print "Done!!!!\n";

# ===================================================================
# End of MAIN
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
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
USAGE:

status_reporting --status=pass|fail --fail_reason=\"Reason for failure\" --file=\"status_file\" --program=\"program description\" --sleep=<sleep seconds>

";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ===================================================================
# End of FUNCTIONS
# ===================================================================

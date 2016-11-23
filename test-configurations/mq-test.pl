#####################################################################
#
#             File: mq-test.pl
#         Revision: 1.00
#
#           Author: Nichols, John
#
#    Original Date: 2005-05-12
#
#      Description: Testing the modifications to the MQ perl script
#                   
#                   
#            Usage: See Usage Function
#
#     Dependancies: 
#
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  2005-0512 nichj    1.00 
#  
#####################################################################

$version             = "$0 version 1.00\n";
$program_description = "MQ Perl Test";

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

#$DEBUG_FILENAME           = "";                                       ## Change this to reflect the proper file
#$DEBUG_EXTENSIVE_FILENAME = "";                                       ## Change this to reflect the proper file
#check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");


# ===================================================================
# ===================================================================
# Begining of Main
# ===================================================================
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

#$status_file    = "$SSM_LOGS" . "";                 ## Change the file name ##
#status_report("$program_description", "$status_file", "start");

$config_file = "$SSM_CONF/mqtest.txt";
@contents    = read_file_contents($config_file);

for $line (@contents) {

  #@results=();

	$line =~ s/\#.*$//g;
	$line =~ s/\s+/ /g;

	@elements=split(/\s/,$line);

	#$hash_ref={};

	foreach $element ( @elements ) {
    
	    ($key,$value)=split(/\=/,$element);
	    $hash_ref->{$key}=$value;
      
	}
  
	push(@results,$hash_ref);

}

foreach $todo (@results) {
  
  %todo=%$todo;
  
  $app = $todo{app};
  $sev = $todo{sev};
  $eml = $todo{emailonly};
  $que = $todo{queue};
  
  print "\napp = $app\n";
  print "sev = $sev\n";
  print "eml = $eml\n";
  print "que = $que\n";
  
}


#status_report("$program_description", "$status_file", "end_pass");

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
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
  
Program USAGE:

<program name> --debug | --debug_extensive | --help | --version

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
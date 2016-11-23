#####################################################################
#
#             File: get_ssm_config_test.pl
#         Revision: 1.00
#
#           Author: Nichols, John
#
#    Original Date: 2005-06-08
#
#      Description: Test the process of getting ssm_config records
#                   
#                   
#            Usage: See Usage Function
#
#     Dependancies: 
#
#
# Revision History:
#
#  
#####################################################################

$version             = "$0 version 1.00\n";
$program_description = "Test getting SSM config";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;

# ===================================================================
# Get Command Line Options
# ===================================================================
GetOptions( "v", "version",
            "h", "help",
            "d", "debug", "debugextensive",
            "prefix:s" => \$ssm_prefix
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

$DEBUG_FILENAME           = "";                                       ## Change this to reflect the proper file
$DEBUG_EXTENSIVE_FILENAME = "";                                       ## Change this to reflect the proper file
check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");


# ===================================================================
# ===================================================================
# Begining of Main
# ===================================================================
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

print "Incoming prefix variable: $ssm_prefix\n\n";

@ssm_prefix = split /,/, $ssm_prefix;

chomp(@ssm_prefix);
@ssm_prefix = trim(@ssm_prefix);

print "Prefix array after conversion\n\n";
print_array(@ssm_prefix);

if (not @ssm_prefix) {
  @ssm_prefix = ("filesys", "fileage", "process");
}


=head2 Purpose of this program

 The purpose of this program is to run through a series of test for alert config parsing,
 evaluating, and processing.
 
 the output from this program will be the results of this.
 
=cut

foreach $prefix_config (@ssm_prefix) {
  $i = 1;
  
  $config_ref = alert_config_array_of_hashes($prefix_config);
  
  @config_ref = @$config_ref;
  
  print "\n\nv v v Config entries for $prefix_config v v v\n\n";

  foreach $config (@config_ref) {
    
    print "Number: $i\n";
    
    %config = %$config;
    
    print_hash_formatted(\%config);
    
      $actions = $config->{'action'};
      
      if (defined($actions)) {
        print "-- Actions --\n";
        @actions = @$actions;
        print_array(@actions);
      }
      
      print "\n\t- ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... -\n";
      print   "\t- ... - ... - ... - ... This is where the logic goes for checking - ... - ... - ... - ... - ... -\n";
      print   "\t- ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... - ... -\n\n";

      print "\n=  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  =  = \n\n";
    
      $i++;
    
  }
  
  print "\n\n^ ^ ^ Config entries for $prefix_config ^ ^ ^\n\n";

}

print "Done for now!\n";

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
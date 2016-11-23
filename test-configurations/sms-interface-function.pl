#####################################################################
#
#             File: sms-interface-function
#         Revision: 1.00
#
#           Author: Nichols, John
#
#    Original Date: 2005-05-09
#
#      Description: Testing / creating a function that sends SMS alert files
#                   to the ESM server via ftp.
#                   
#                   
#            Usage: See Usage Function
#
#     Dependancies: Net::FTP
#
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  2005-05-09 nichj    1.00 original
#  
#####################################################################

$version             = "$0 version 1.00\n";
$program_description = "SMS Interface Function";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;
use Net::FTP;
use File::Basename;

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

$sms_phone   = "+19256980520";
$sms_message = "Testing the new function";

if (not sms_alert($sms_phone, $sms_message)) {
  
  print "There was an error!\n";
  
} else {
  
  print "The message was sent okay\n";
  
}

print "\n$program_description completed successfully\n";

exit 0;


# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# ===================================================================
# ===================================================================
# End of Main
# ===================================================================
# ===================================================================





#status_report("$program_description", "$status_file", "end_pass");



# ===================================================================
# Beginning of Functions
# ===================================================================

## v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
## Function: sms_alert($sms_phone_number, $message_to_send)
##  Call this function when you want to send a message via SMS
##  It returns TRUE if successful, FALSE if not.
##
##  ********************************************
##  *** This requires Net::FTP to be loaded. ***
##  ********************************************
##
## -------------------------------------------------------------------
#sub sms_alert ($$) {
#  my @sms_info;
#  my $retval       = 1;
#  @sms_info        = ($_[0], $_[1]);
#   
#  #$user     = `perlpass_get smsuser`;
#  #chomp($user);
#  #$pass     = `perlpass_get smspass`;
#  #chomp($pass);
#  my $ftp_server   = "esm";
#  my $user         = "sms";
#  my $pass         = "alarmpointsms";
#  my $destdir      = "/sms";
#  #my $fromfile     = $SSM_TMP . $FROM_TMPFILE;
#  #my $destfile     = $TO_TMPFILE;
#
#  my $FROM_TMPFILE = write_sms_file(@sms_info);
#  my $TO_TMPFILE   = basename($FROM_TMPFILE);
#  
#  if (not ftp_file($FROM_TMPFILE, $ftp_server, $destdir, $TO_TMPFILE, $user, $pass)) {
#    $retval = 0;
#
#  } else {
#
#    if ($debug) { print "ftp of $FROM_TMPFILE to $ftp_server\:$destdir/$TO_TMPFILE successful\n"; }
#
#  }
#  
#  unlink "$FROM_TMPFILE";
#  
#  return $retval;
# 
#  # = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 
#  # Beginning of sub-Functions
#  # = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 
#
#  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#  # Function: generate_sms_temp_file()
#  #  this function generates a temporary file name based on the
#  #  hostname, epoch time, and a randomly genrated number
#  # -------------------------------------------------------------------
#  sub generate_sms_temp_file_name {
#    my ($retval, $timefile, $rnd);
#    
#    ##
#    ## generate a file based on $hostname and epoch time and random number
#    ##
#    $timefile = time;
#    $rnd      = int( rand(510) );
#    
#    $retval   = lc "$HOSTNAME" . "$timefile" . "$rnd";
#    
#    return $retval;
#    
#  }
#  # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
#  
#  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#  # Function: write_sms_file(@array_to_write_to_file)
#  #
#  ## The incoming array is made up elements which will be written to the temp file.  Each
#  ##  element will be written to each line.
#  ##  
#  ## The temp file name will created, populated, then the temp file name will be returned
#  ##  to the calling program.
#  ##
#  sub write_sms_file {
#    my @incoming_data = @_;
#    my $tmpfile       = "$SSM_TMP" . generate_sms_temp_file_name();
#    my $retval        = $tmpfile;
#    my $item;
#    
#    if (-e "$tmpfile") {
#      
#      warn "Error! $tmpfile already exists\n";
#      
#    } else {
#      
#      open  (TMPFILE, ">$tmpfile");
#      foreach $item (@incoming_data) {
#        print TMPFILE "$item\n";
#      }
#      
#      close (TMPFILE);
#    }
#    
#    return $retval;
#      
#  }
#  # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
#
#  # = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 
#  # End of sub-Functions
#  # = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 
#
#}
## ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
#
## v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
## Function: ftp_file($from_file, $to_server, $to_dir, $to_file, $ftp_user, $ftp_pass)
##  This will return FALSE if there is a problem, TRUE if successful.
##
##  ********************************************
##  *** This requires Net::FTP to be loaded. ***
##  ********************************************
##
## -------------------------------------------------------------------
#sub ftp_file ($$$$$$) {
#  my @incoming_array = @_;
#  my $retval         = 1;
#  
#  my $from_file = $incoming_array[0];
#  my $to_server = $incoming_array[1];
#  my $to_dir    = $incoming_array[2];
#  my $to_file   = $incoming_array[3];
#  my $to_user   = $incoming_array[4];
#  my $to_pass   = $incoming_array[5];
#  
#  if (not $ftp=Net::FTP->new($to_server,Timeout=>240)) {
#    
#    warn "Can't connect to $to_server: $!\n";
#    $retval = 0;
#  
#  } else {
#    if ($debug)                                                      { print "Connected to $to_server $!\n"; }
#    
#    if (not $ftp->login($to_user, $to_pass)) {
#      
#      warn "Can't login to $to_server: $!\n";
#      $retval = 0;
#      
#    } else {
#      if ($debug)                                                    { print "Login to $to_server $!\n"; }
#      
#      if (not $ftp->cwd("$to_dir")) {
#
#        warn "Unable to change directories to $to_dir: $!\n";
#        $retval = 0;
#        
#      } else {
#        
#        if (not $ftp->put("$from_file","$to_file")) {
#
#        warn "Unable to send file $to_file: $!\n";
#        $retval = 0;
#        
#        } else {
#          if ($debug)                                                { print "Transfer of $from_file to $to_dir/$to_file on $to_server $!\n"; }
#          
#          $ftp->quit();
#          
#        }
#      }
#    }
#  }
#  
#  return $retval;
#  
#}
## ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

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
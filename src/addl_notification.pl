###################################################################
#
#             File: addl_notification.pl
#         Revision: 2.60
#
#           Author: John Nichols (original shell by DoolBil)
#
#    Original Date: 05-2004
#
#      Description: This program will perform the additional 
#                   notification requested by SSM.
#                   This is called via the vpo template for vposend/opcmsg
#                   
#           Usage:  see usage
#
#           Notes:  This only runs on the VPO server.
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  05-2004    jwn           Converted from shell script
#             jwn           1.03 - pull just the server name from fqn
#
#  2005-04-12 nichj   2.50: Brought up to current standards
#
#  2005-06-07 nichj   2.60  Converted to use email_alert function and to fix logging
#
#####################################################################

$version             = "$0 version 2.50\n";
$program_description = "addl notification";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;
use Mail::Sendmail;

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
$DEBUG_FILENAME           = "$SSM_CONF" . "addl_notification.debug";
$DEBUG_EXTENSIVE_FILENAME = "$SSM_CONF" . "addl_notification.debugextensive";
check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");

$debug_logfile            = "/var/opt/OV/log/addl_notification.log";
if ($debug) {
  open (AN_LOGFILE, ">>$debug_logfile");
}


# ===================================================================
# ===================================================================
# Begining of Main
# ===================================================================
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

## if nothing is specified on the command line, return
## the usage info.
$det = $ARGV[1];
if ( "$det" eq "" ) {
   usage();
   exit 1;
}


## if we're here then we have at least one paramter!
if ($debug ) {
   print AN_LOGFILE "\n\n=== Debug Starting ===\n\n";
   $start_time = localtime(time);
   print AN_LOGFILE "\tstart:    $start_time (local)\n";
}

# Assign variables to corresponding switches.
#  since this program is called from the vpo template via precanned.pl it is expected
#  that a level of error checking has happened prior to calling this program, hence the lack
#  of extensive error checking here.
$action   = lc($ARGV[0]);  # this is the action to take, e.g. email, emailfyi, comfort, notify...
$detail   = lc($ARGV[1]);  # this variable has the details, such as group, address, email subject, etc.
$message  =    $ARGV[2] ;  # this is the message that will be sent
$vpoid    =    $ARGV[3] ;  # this has to be passed to alarmpoint
$severity =    $ARGV[4] ;  # this is passed on to alarmpoint
@host     =    split(/\./, $ARGV[5]); # the system name
$system   =    $host[0];   # get just the server name

@dtl      = split(/;/,$detail);  # split the detail variable into an arry at the semicolon

if ($debug) {
   print AN_LOGFILE "\tAction:   $action\n";
   print AN_LOGFILE "\tDetail:   $detail\n";
   print AN_LOGFILE "\tMessage:  $message\n";
   print AN_LOGFILE "\tMsgID:    $vpoid\n";
   print AN_LOGFILE "\tSeverity: $severity\n";
   print AN_LOGFILE "\tSystem:   $system\n\n";
}

## create some default values, just in case
if ($severity eq "") {
   $severity = "2";
   if ($debug) {
      print AN_LOGFILE "\tnote: default severity set.\n";
   }
}

if ($system eq "") {
   $system = `hostname`;
   chomp ($system);
   if ($debug) {
      print AN_LOGFILE "\tnote: default system set.\n";
   }
}
## end of default catches

#########################
##  EMAIL and EMAILfyi ##
#########################

if (( $action eq "email" ) || ( $action eq "emailfyi" )) {
   # the second parameter is the details.  These are split as follows:
   #  "email address1, email address2; subject line"
   ## strip leading spaces of all elements
   $r = "";
   foreach $r (@dtl) {
      $r =~ s/^\s*//;
   }

   $email_to      = $dtl[0];
   $email_subject = $dtl[1];
   $from          = "vpo\@barclaysglobal.com";
   $cc            = "";
   
   $email_to      = email_domain_check($email_to);
   
   if ($debug) {
      print AN_LOGFILE "\t\n";
      print AN_LOGFILE "\temail Address: $email_to\n";
      print AN_LOGFILE "\temail Subject: $email_subject\n";
      #print AN_LOGFILE "\temail command: /usr/bin/mailx -r \"openview_notification\" -s \"$emailSubject\" \"$emailAddress\"\n";
      print AN_LOGFILE "\temail text:    $message\n";
   }
   
   #$status = `echo "$message" | /usr/bin/mailx -r "openview_notification" -s "$emailSubject" "$emailAddress"`;
   $status = mail_alert($from, $email_to, $cc, $email_subject, $message);

   if ($debug)                                                       { print AN_LOGFILE "\temail status:  $status\n";  }
   # something that would be good to add here is a $status check, but I'm not sure about
   #  what different status messages might be, so i'm leaving it out for now.  nichj
   # if ($status) ne 0 {
   #  exit 1;
   # }
}
#########################
## end EMAIL/EMAILfyi  ##
#########################


#########################
##       COMFORT       ##
#########################

if ( $action eq "comfort" ) {
   # the incoming comfort message includes the alarmpoint user/group to send to and the
   #  method of message delivery.
   # since alarmpoint deals with sms and pager messages as pager, there will be a conversion
   #  here.
   # if nothing is specified, then both pager and email will be used.

   $apGroup  = $dtl[0];
   $apMethod = lc($dtl[1]);
   $apMethod =~ s/^\s*//; 

   if (($apMethod eq "") || ($apMethod eq "all") || ($apMethod eq "both")) {
      $apMethod = "email, pager";
   }
   
   if ($debug) {
      print AN_LOGFILE "\t\n";
      print AN_LOGFILE "\tap group input:  $apGroup\n";
      print AN_LOGFILE "\tap method input: $apMethod\n";
   }

   @apGrp    = split(/,/,$apGroup);
   @apMth    = split(/,/,$apMethod);
   
   
   ## strip leading spaces of all elements
   $r = "";
   foreach $r (@apMth) {
      $r =~ s/^\s*//;
      # check for sms and change to pager
      if ($r eq "sms") {
         $r = "pager";
      }
   }
   
   $r = "";
   foreach $r (@apGrp) {
      $r =~ s/^\s*//;
   }
   ## end leading space strip
   
   ## process through the method array and remove duplicates
   %seen = (); # hash key 
   @uMth = (); # unique method array
   
   foreach $item (@apMth) {
      unless ($seen{$item}) {
        # if we get here, we have not seen it before
        $seen{$item} = 1;
        push(@uMth, $item);
      }
   }
   ## end of remove duplicates

   if ($debug) {
      print AN_LOGFILE "\tArray Group:     @apGrp\n";
      print AN_LOGFILE "\tArray Method:    @apMth\n";
   }
   

   ## Loop through all unique methods
   ##  while going through each method, loop through all destination addresses
   ##   send message to each destination via each method
   foreach $method (@uMth) {
      foreach $destination (@apGrp) {
         if ($debug) {
            print AN_LOGFILE "\t\n";
            print AN_LOGFILE "\tAlarmpoint destination: $destination\n";
            print AN_LOGFILE "\tAlarmpoint method:      $method\n";
            print AN_LOGFILE "\tAlarmpoint command:     /opt/OV/apagent/APClient --map-data comfort \"BGI Comfort\" \"$destination\" \"$vpoid\" \"$system\" \"$method\" \"$message\" \"$severity\" \n\n";
            print AN_LOGFILE "\tAlarmpoint text:        $message\n";
            print AN_LOGFILE "\tvpo message id:         $vpoid\n";
            print AN_LOGFILE "\tvpo severity:           $severity\n\n";
         }

      $status = `/opt/OV/apagent/APClient --map-data comfort "BGI COMFORT" "$destination" "$vpoid" "$system" "$method" "$message" "$severity"`;

      if ($debug) {
         print AN_LOGFILE "\tcomfort status:         $status\n";
      }

      }
   }
   
}
#########################
##   end COMFORT       ##
#########################


if ($debug ) {
   $end_time = localtime(time);
   print AN_LOGFILE "\tend:      $end_time (local)\n";
   print AN_LOGFILE "\n=== Debug Ending ===\n";
   close(AN_LOGFILE) || die "cannot close: $!\n";
}

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
# Function: email_domain_check($email_address(es))
#  checks to see if domain is suffixed, adds if needed.
#
# *** NOTE *** This isn't working at this time.
# -------------------------------------------------------------------
sub email_domain_check ($) {
  my $incoming_address         = $_[0];
  my $default_domain_name      = '@barclaysglobal.com';
  my ($email, $domain, $address, $retval);
  
  @addresses = split ( /,/, $incoming_address);
  @addresses = trim(@addresses);
  
  foreach $address (@addresses) {
    ($email, $domain) = split ( /@/, $address );
    
    if (not $domain) {
      $domain = $default_domain_name;
    }
    
    $email_address = $email . $domain;
    
    push @email_list, $email_address;

  }
  
  ##
  ## This is funky - how is the best way to take an array and put commas inbetween each element?
  
  return $incoming_address;
  
}
  


# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
  *************************************************************************************************
  
  Usage: addl_notification <action> <detail> <message_text> <vpo_msgid> <vpo_sev> <system>
   <action> =
   
     email    <detail> 
     emailfyi <detail> 
      <detail> = \"<email addresses>; <subject>\" 
         <email addresses> = email addresses delimited by comma
         <subject>         = the subject of the email
     

     comfort  <detail>
      <detail> = \"<destination> (alarmpoint persons or groups); <method(s)>\"
     
         <destination> = Alarmpoint group name(s) or Alarmpoint Person ID(s) delimited by commas.
      
         <method(s)> = email, sms, and/or pager || all || blank* (multiple delimited by comma)
           all   - or blank (default) send via all comfort channels (email and pager/sms)
           email - send via email only
           sms   - send via sms (same as pager)
           pager - send via pager (same as sms)
   
   <message>   = Message to send
    
   <vpo_msgid> = the vpo message id (for tracking purposes in Alarmpoint)
    
   <vpo_sev>   = the severity of the message coming from vpo.
    
   <system>    = the system orginating the event.

  Example: emailfyi
  addl_notification \"emailfyi\" \"userid\@barclaysglobal.com; this is the subject\" /
                               \"This is the message to send\" \"1234-1234-1234-1234\" /
                               \"major\" \"calntesm001\"

  Example: comfort
  addl_notification \"comfort\"  \"ap_group_name, 9999444; sms, email\" /
                               \"This is the message to send\" \"1234-1234-1234-1234\" /
                               \"major\" \"calntesm001\"
   

  **************************************************************************************************
  
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

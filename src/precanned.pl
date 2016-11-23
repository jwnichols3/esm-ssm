###################################################################
#
#             File: precanned.pl
#         Revision: 2.50
#
#           Author: Bill Dooley
#
#    Original Date: 07/02
#      Update Date: 2004 May 14
#
#      Description: This program will take command line switch
#                   data and then perform the appropriate action 
#                   based on the action.
#                   
#           Usage:  see usage
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  07/02      wpd           <Initial Version>
#  Jun 2004   jwn           Added action of COMFORT & debugging
#             jwn           added start time to logging
#
# 2005-04-12  nichj   2.50: Brought up to current standards
#
#####################################################################

$version             = "$0 version 2.50\n";
$program_description = "precanned action";                            ## enter a short description of this program

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

$DEBUG_FILENAME           = "$SSM_CONF" . "precanned.debug";
$DEBUG_EXTENSIVE_FILENAME = "$SSM_CONF" . "precanned.debugextensive";
check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");


# ===================================================================
# ===================================================================
# Begining of Main
# ===================================================================
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

$opcmsg = $OpC_BIN . "opcmsg";

$chk_date = get_display_date();

#
# Get the arguments
#

$det = $ARGV[1];
if ( "$det" eq "" ) {
   $log_msg = "$chk_date :: Action Details are required for Canned Action $action";
   &print_log;
   usage();
   exit 1;
}

if ($debug) {
   $start_time = localtime(time);
   $log_msg =  "
=== Starting Debug ===
   start:    $start_time (local)";
   &print_log;   
}

@detail = split(/\._/, $det);
$node   = $ARGV[2];
$appl   = $ARGV[3];
$grp    = $ARGV[4];
$obj    = $ARGV[5];
# $msgid  = $ARGV[6];
$msgid  = "ID";
$sev    = $ARGV[7];
$text   = $ARGV[8];
# $create = $ARGV[9];
$create = "1";
# $type   = $ARGV[10];
$type   = "2";
chomp($type);

$n = 0;
@act    = split(/\.\_/,$ARGV[0]);

if ($debug) {
   
   $log_msg = "
     Detail: @detail
     Node:   $node
     Appl:   $appl
     Grp:    $grp
     Obj:    $obj
     Msgid:  $msgid
     Sev:    $sev
     Text:   $text
     Create: $create
     Type:   $type
     Act:    @act
     ";
     
     &print_log;
}

#
# if $appl = test then exit
#

if ( "$obj" eq "test" ) {
   
   print "No precanned action will be performed for test events\n";
   if ($debug) {
      $log_msg = "No precanned action will be performed for test events\n";
      &print_log;
   }
   
   exit 0;
}

# 
# Process each action with the appropriate Details
#

foreach $action(@act) {
   if ( "$action" ne "email"      &&
        "$action" ne "emailfyi"   &&
        "$action" ne "runprog"    &&
        "$action" ne "escalation" &&
        "$action" ne "broadcast"  &&
        "$action" ne "comfort"    &&
        "$action" ne "none" ) {
      $log_msg = "$chk_date :: Invalid Canned Action $action";
      &print_log;
      usage();
      exit 1;
   }
   if ( "$action" eq "none" ) {
   if ($debug) {
      $log_msg = "Action is none, exiting\n";
      &print_log;
   }
      exit 0;
   }

   print "Processing Action = $action Detail = $detail[$n]\n";
   if ($debug) {
      $log_msg = "Processing Action = $action Detail = $detail[$n]\n";
      &print_log;
   }


   &$action;
   $n++;
}

exit 0;

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# ===================================================================
# ===================================================================
# End of Main
# ===================================================================
# ===================================================================

# ===================================================================
# Start of SUBROUTINES
# ===================================================================

########################
sub email {
########################

   # 
   # Perform email parameter validations
   #

   if ( "$sev" eq "" ) {
      $log_msg = "$chk_date :: Invalid Severity $sev for Canned Action $action - $detail [$n]";
      &print_log;
      usage();
      exit 1;
   }

   if ($debug) {
      $log_msg = "Sending: $opcmsg a=\"$appl\" o=\"$obj\" msg_grp=\"$grp\" msg_text=\"$err_msg.-.$detail[$n].-.$text\" sev=\"major\"";
      &print_log;
   }

   $status = `$opcmsg a="$appl" o="$obj" msg_grp="$grp" msg_text="CANNED$action.-.$detail[$n].-.$text" sev="$sev" 2>&1`;
 
   if ( $? != 0 ) {
      chomp($status);
      $log_msg = "$chk_date :: Error processing Canned Action $action - $status";
      &print_log;
      $err_msg = "The execution of the $action failed due to $status";
      if ($debug) {
         $log_msg = "Error. Now sending: $opcmsg a=\"$appl\" o=\"$obj\" msg_grp=\"$grp\" msg_text=\"$err_msg.-.$detail[$n].-.$text\" sev=\"major\"";
         &print_log;
      }
      `$opcmsg a="$appl" o="$obj" msg_grp="$grp" msg_text="$err_msg.-.$detail[$n].-.$text" sev="major"`;
   } else {
      $log_msg = "$chk_date :: Successful processing Canned Action $action with $detail[$n]";
      &print_log;
   }
}

########################
sub emailfyi {
########################

   if ( "$sev" eq "" ) {
      $log_msg = "$chk_date :: Invalid Severity $sev for Canned Action $action - $detail [$n]";
      &print_log;
      usage();
      exit 1;
   }

   $status = `$opcmsg a="$appl" o="$obj" msg_grp="$grp" msg_text="CANNED$action.-.$detail[$n].-.$text" sev="$sev" 2>&1`;
    
   if ( $? != 0 ) {
      chomp($status);
      $log_msg = "$chk_date :: Error processing Canned Action $action - $status";
      &print_log;
      $err_msg = "The execution of the $action failed due to $status";
      `$opcmsg a="$appl" o="$obj" msg_grp="$grp" msg_text="$err_msg.-.$detail[$n].-.$text" sev="major"`;
   } else {
      $log_msg = "$chk_date :: Successful processing Canned Action $action with $detail[$n]";
      &print_log;
   }
}
   
########################
sub runprog {
########################

   @result = `$detail[$n]`;
 
   if ( $? != 0 ) {
      chomp(@result);
      $log_msg = "$chk_date :: Error processing Canned Action $action - $detail[$n] :: @result";
      &print_log;
      $err_msg = "The execution of the $action - $detail[$n] failed :: STDOUT = @result";
      `$opcmsg a="$appl" o="$obj" msg_grp="$grp" msg_text="$err_msg .-. $text" sev="major"`;
   } else {
      $log_msg = "$chk_date :: Successful processing Canned Action $action with $detail[$n] :: STDOUT = @result";
      &print_log;
   }
}

########################
sub comfort {
########################
# the parameters for comfort are
#  ap user or group
#  method of contact: email or pager or sms or all.
#   If blank, then all used.
#   the sms method translates to pager in alarmpoint.
#
#  By definition a comfort message is something that is non-interruptive
#   therefore doesn't include phone calls.

# prototype discussion: validation
#  The best way to process these messages
#  is to validate the user/group exsits within alarmpoint and send
#  a message back to the application if it doesn't.  The challenges with that
#  are twofold: 1) how quick is the validation, and 2) what kind of
#  methods and parameters will be required to alert a group (how often,
#  how, etc.).  My direction is this: put in place the direct interface
#  without extensive validation, but include the validation logic placeholders
#  so if it is obviously needed we have a starting place.

# prototype discussion: connectivity method
#  I would like to see communication happening via xml.  However, 
#  this appears to require a secondary response program to validate
#  and clear reply messages from AP.  This isn't something we
#  should look to do at this point.
#

   print "Processing action type $action with $detail[$n].\n";
   print "\n";
   print "The command will be:
      $opcmsg
      a=\"$appl\"
      o=\"$obj\"
      msg_grp=\"$grp\"
      msg_text=\"CANNED$action.-.$detail[$n].-.$text\"
      sev=\"$sev\"";
   $status = `$opcmsg a="$appl" o="$obj" msg_grp="$grp" msg_text="CANNED$action.-.$detail[$n].-.$text" sev="$sev" 2>&1`;

}

########################
sub escalation {
########################

   print "Processing action type $action with $detail[$n].\n";
 
}

########################
sub broadcast {
########################

   print "Processing action type $action with $detail[$n].\n";
 
}

########################
sub print_log {
########################

   print "$log_msg\n";
   `echo '$log_msg' >> $SSM_LOGS/cannedaction.log`;
 
}
# ===================================================================
# End of SUBROUTINES
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
Usage: precanned <parameters>
    where parameters are:
         <action>
            This is the action that will be acted on by this 
            program.  Valid values are (none, email, emailfyi, 
            runprog, escalation, broadcast, and comfort).
            Multiple actions my be combined using a \"._\" as separators.
            This should be compined in conjunction with multiple
            details.  Use $OPTION(action).
         <action details>
            This is the detail information required by the 
            action. (e.g. e-mail addresses). Multiple details 
            may be combined using a \"._\" as separators.  This
            should be combined in conjunction with multiple
            actions.  Use $OPTION(detail).
         <managed node name>
            OVO Node. Use the $MSG_NODE_NAME variable.
         <Application>
            OVO Application. Use the $MSG_APPL variable.
         <Message Group>
            OVO Message Group. Use the $MSG_GRP variable.
         <Object>
            OVO Object. Use the $MSG_OBJECT variable.
         <Internal Message Id>
            OVO Interal Message ID. Use the $MSG_ID.
         <Severity>
            OVO Severity. use the $MSG_SEV variable.
         <Message Text>
            OVO Message Text. Use the $MSG_TEXT variable.
         <Message Time Created>
            OVO Time Created. Use the $MSG_TIME_CREATED variable.
         <Message Type>
            OVO Message Type. Use the $MSG_TYPE variable.
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

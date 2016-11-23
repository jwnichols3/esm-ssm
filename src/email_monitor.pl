###################################################################
#
#             File: email_monitor.pl
#         Revision: 1.0
#
#           Author: Bill Dooley
#          Company: Pepperweed Consulting, LLC
#                   © Pepperweed Consulting, LLC
#
#    Original Date: 08/02
#
#      Description: This program will check configured users for 
#                   new email.  It will then use who sent the email
#                   for the OVO application, the Subject to determine
#                   who the message should be sent to and the text 
#                   of the message as the message to be sent.
#                   
#           Usage:  email_monitor.pl  
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  08/02      wpd           <Initial Version>
#####################################################################

# ===================================================================
# Begining of Main
# ===================================================================

#
# Set up the standard variables
#
$platform = "$^O";
chomp ($platform);

# print "Setting variables for $platform from setvar.pm\n";

if ( "$platform" eq "MSWin32" ) {
   require "/usr/OV/bin/OpC/cmds/setvar.pm";
} elsif ( "$platform" eq "aix" ) {
   require "/var/lpp/OV/OpC/cmds/setvar.pm";
} else {
   require "/var/opt/OV/bin/OpC/cmds/setvar.pm";
}

$vposend = $PWC_BIN . "vposend";

#
# Read the configuration file email.dat to determine which mail
# users to monitor.
#

$email_conf = $PWC_ETC . "email.dat";
$init_file = $PWC_BIN . "email.dat";

unless (open (email_conf, "$email_conf")) {
   if ( -e "$init_file" ) {
      print "Installing $email_conf\n";
      `$CP $init_file $PWC_ETC`;
   } else {
      print "No configuration file exists\n";
      exit 0;
   }
}

@email_users = <email_conf>;
close email_conf;

$mail_dir = "/var/mail/";

foreach $inrec (@email_users) {
   #
   # Check for blank line
   #
   $inrec =~ s/^\s+//;
   $blank = (substr($inrec, 0, 1));
   if ("$blank" eq "") {next;};

   #
   # Check for comment line
   #
   $comment   = (substr($inrec, 0, 1));
   if ("$comment" eq "#") {next;}
   if ("$comment" eq "\n") {next;}

   #
   # Process input record
   #
   chomp($inrec);
   ($user, $type) = split(/ /, $inrec);
   chomp($user);
   chomp($type);

   $text_read = 0;
   $msg_text = "";
   $mail_file = $mail_dir . $user;
   `ls -l $mail_file`;
   print "Checking for $user in $mail_file.\n"; 

   if ( -e "$mail_file" ){
      #
      # Get the mail for the user
      #
      open (mail, "$mail_file");
      @mail = <mail>;
      close $mail;

      #
      # Clear the mail just read for the user
      #
      `> $mail_file`;

      #
      # Process the messages
      #

      $n=0;

      foreach $mail_rec (@mail) { 
         chomp($mail_rec);
         $mail_rec =~ s/^\s*(.*?)\s*$/$1/;
         if ("$mail_rec" eq "") {
            next;
         }
         ($tag,$rest) = split(/ /,$mail_rec);
         if ( "$tag" eq "From" ) {
            if ( $n >= 1 ) {
               &check_ssm;
            }
            $text_read = 0;
            $n=0;
            $msg_text = "";
         }
         if ( "$tag" eq "From:" ) {
            ($dummy, $from) = split(/: /,$mail_rec);
            next;
         }
         if ( "$tag" eq "Subject:" ) {
            ($dummy, $recipients) = split(/: /,$mail_rec);
            $text_read = 1;
            next;
         }
         if ( $text_read == 1 ) {
            chomp($mail_rec);
            if ("$mail_rec" eq "") { next; }
            $msg_text = $msg_text . "\n" . $mail_rec;
            push (@msg_text, "$mail_rec");
            $n++;
            next;
         }
      }
   }
   if ( $n >= 1 ) {
      &check_ssm;
      $n = 0;
   }
}

#################################
# check_ssm
#################################

sub check_ssm {
   $first = $msg_cnt = 0;
   $App = $Sev = $Message = $Key = $Action = $Type = "";
   foreach $ssm_rec(@msg_text) {
      ($tag, $tag_rec) = split(/=/, $ssm_rec);
      $tag = lc($tag);
      if ( "$tag" eq "app" ) {
         $App = lc($ssm_rec . " ");
         $first++;
      } elsif ( "$tag" eq "sev" or "$tag" eq "severity") {
         $Sev = lc($ssm_rec . " ");
         $first++;
      } elsif ( "$tag" eq "message" ) {
         if ( $msg_cnt == 0 ) {
            $Message = $ssm_rec . " ";
            $msg_cnt++;
         } else {
            $Message = $Message . " " . $tag_rec . " ";
         }
         $first++;
         $msg_cnt++;
      } elsif ( "$tag" eq "key" ) {
         $Key = $ssm_rec . " ";
      } elsif ( "$tag" eq "action" ) {
         $Action = $Action . $ssm_rec . " ";
      }
   }
   if ( $first > 2 ) {
      $vposend_rec = "$App $Sev $Key $Action Type=$user email $Message";
   } else {
      $from = lc($from);
      $vposend_rec = "App=$from Sev=Minor Message=$msg_text Type=$user email";
   }

   $vposend_rec =~ s/"//g;
   print "vposend_rec = $vposend_rec\n";
   print "Processing information for \n\`$vposend -f \"$vposend_rec\"\n";
   `$vposend -f \"$vposend_rec\"`;
   $first = $msg_cnt = 0;
   $App = $Sev = $Message = $Group = $Key = $Action = $Type = $Node = "";
   @msg_text="";

} #### end of check_ssm

exit 0;

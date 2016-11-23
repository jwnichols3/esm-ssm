=head1 TITLE

    Alternate Notification module

=head1 DESCRIPTION

    Used in the TTI perl script to process alternate notifications

=head1 USAGE



=head1 TODO




=head1 REVISIONS

CVS Revision: $Revision: 1.8 $

  #####################################################################
  #  2005-10-05 - nichj - Migrated to Perl Module
  #  2006-05-17 - makskri - Chaneg severity from 3,4,5 to 3,4
  #  2008-07-30 - makskri - Added logic to process Sev 25 events
  #####################################################################
 
=cut

##############################################################################
### Package Name #############################################################
package BGI::ESM::VpoServer::AlternateNotification;
##############################################################################

##############################################################################
### Module Use Section #######################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os);
##############################################################################

##############################################################################
### Require Section ##########################################################
require Exporter;
##############################################################################

##############################################################################
### Who is this ##############################################################
our @ISA = qw(Exporter BGI::ESM::VpoServer);
##############################################################################

##############################################################################
### Public Exports ###########################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

    
);
##############################################################################

##############################################################################
### VERSION ##################################################################
our $VERSION = (qw$Revision: 1.8 $)[-1];
##############################################################################

##############################################################################
# Public Variables
##############################################################################



##############################################################################
# Public Methods / Functions
##############################################################################


=head2 alternate_notification(\%vpo_data, $bypass_peregrine_flag)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function: alternate_notification(\%vpo_data, $bypass_peregrine)
  #
  #  \%vpo_data is the %vpo_data structure
  #  $bypass_peregrine is used when Peregrine is unavailable and this is called for bypassing peregrine
  #   if set to 1 then the peregrine bypass function is called
  #   otherwise the message is evaluated for alternate notification flags
  #
  # Returns: ($status, $send_to_ap_if_peregrine_down, $ticket_to_peregrine)
  #
  #  $ticket_to_peregrine is set to 1 (TRUE) by default.  Change this to 0 if a Peregrine ticket should not be created.
  #  
  # -------------------------------------------------------------------

=cut

sub alternate_notification {
  my  $incoming_hash        = shift;
  my  %incoming_hash        = %{$incoming_hash};
  my  $bypass_peregrine     = shift;                           # sent as part of the function
  my  $status_retval        = 1;
  our $send_to_ap_if_p_down = 1;                               # set to 0 if ap notifications should NOT be
                                                              #  created if Peregrine is down
  my  $ticket_to_peregrine  = 1;                               # set to 0 (FALSE) if no peregrine ticket should be created.
  
  our $msgid                = $incoming_hash{'msgid'         };
  our $vpo_cma              = $incoming_hash{'cma'           };
  our $message_group        = $incoming_hash{'message_group' };
  our $node                 = $incoming_hash{'node'          };
  our $message_text         = $incoming_hash{'message_text'  };
  our $node_type            = $incoming_hash{'node_type'     };
  our $vpo_appl             = $incoming_hash{'appl'          };
  our $vpo_obj              = $incoming_hash{'obj'           };
  our $severity             = $incoming_hash{'severity'      };
  
  ###############################################
  ##### Main processing starts here        ######
  ###############################################
  our @parsed_cma = parse_cma($vpo_cma);
  
  our %cma        = @parsed_cma;
  
  our $an_type    = alternate_notification_type();
      $an_type    = lc $an_type;                        # lower case to make sure
  
  if ($bypass_peregrine) {
  
  	bypass_peregrine();
  
  } elsif ($an_type) {
    
    ##
    ## If other alternate notification types are defined, add them here
    ##
    if ($an_type eq "netiq") {
  
    	my $status = netiq_alert();
      
        my $annotate_text = "Message slated for alternate-notification: $an_type\n\n".
                         "Status of alternate-notification: $status\n";
        
        $status = vpo_annotate($msgid, $annotate_text);
      
    }
  	
	} else {

      #if ($debug_extensive)                                          { print AN_LOGFILE " *** Not a netiq event ***\n"; }
  
  }
  
  
  #if ($debug_extensive) {
  #
  #  print AN_LOGFILE "\tProcess Status:               $status_retval\n"        ;
  #  print AN_LOGFILE "\tSend to AP if Peregrine Down: $send_to_ap_if_p_down\n";
  #  print AN_LOGFILE "\tTicket to Peregrine:          $ticket_to_peregrine\n" ; 
  #
  #  print AN_LOGFILE "
  #======================================================================
  #  ";
  #  
  #  close AN_LOGFILE;
  #}
  
  
  return ($status_retval, $send_to_ap_if_p_down, $ticket_to_peregrine);

  ###############################################
  ##### Main processing ends here          ######
  ###############################################
    
    
  # ====================================================================  
  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Sub-function: netiq_alert()
  #
  # Requires:
  #  This assumes the data structures, logfiles, etc are present and accounted for
  #
  # Returns:
  #  status of function (TRUE (1) or FALSE (0))
  #
  #  Updates:
  #   2005-07-01 - nichj - Changed Alarmpoint alertable events to NetIQ sev 3, 4, and 5.
  #
  #   2005-07-01 - nichj - added "catchall" logic which will send all NetIQ alerts outside of the defined parameters to the netIQ admins.
  #                         To turn off, change $catchall variable to 0.
  #   2008-07-30 - KMM   - Added NetIQ sev 25 
  # -------------------------------------------------------------------
  sub netiq_alert {
    
    my (
          $email_dl, $email_cc,
          $netiq_sev, $netiq_jobid, $netiq_kscat,
          $netiq_ksname, $netiq_occurence, $netiq_eventid,
          $long_message, $netiq_specifics,
          %ap_data,
          $email_from
        );
    
    my $retval     = 1;
    my $catchall   = 1;                                               # Used to flag sending all events outside of alertable parameters to the netIQ admins.
    
      $email_dl    =  "bgiglobalwindowssystems\@barclaysglobal.com";
      $email_cc    =  "";
      
      if (strip_domain($HOSTNAME) eq "rdcuxsrv005") {
        $email_dl  = "nichj\@barclaysglobal.com";                     # Used for testing purposes.
      }
          
      $email_from  =  "alarmpoint\@barclaysglobal.com";
  
      #if ($debug_extensive)                                            { print AN_LOGFILE "\t\tThis is a NetIQ message and the sev = $cma{'netiq_severity'}\n"; }
      
         $send_to_ap_if_p_down = 0;
      
        $netiq_sev       = $cma{'netiq_severity'   };                    #
        $netiq_jobid     = $cma{'netiq_jobid'      };                    #
        $netiq_kscat     = $cma{'netiq_kscat'      };                    #
        $netiq_ksname    = $cma{'netiq_ksname'     };                    #
        $netiq_occurence = $cma{'netiq_occurence'  };                    #
        $netiq_eventid   = $cma{'netiq_eventid'    };                    #
        $long_message    = $cma{'z_netiq_longmsg'  };                    # Because of the interesting text in the long message, this has to be last, hence the z_ prefix
    
        $netiq_specifics = "NetIQ JobID=$netiq_jobid";                   # This is included in the email for reference.

      # The alarmpoint data structure 
      #
      %ap_data = (
                  'map_data'        => "",
                  'script'          => "",
                  'groupname'       => "",
                  'eventid'         => "",
                  'messagetext'     => "",
                  'longmessage'     => "",
                  'host'            => "",
                  'severity'        => "",
                  'ticket'          => "",
                  'logfile'         => "",
                  'contact_device'  => "",
                  'netiq_severity'  => "",
                  'netiq_specifics' => "",
                  'contact_options' => "",
                  'behavior'        => ""
                 );
      
      #
      # General functionality is based on the netiq_severity ranges.
#      
      if (($netiq_sev == 3) || ($netiq_sev == 4))        {
        ##
        ## Note: due to the interesting long messages, these are being sent via email as well as going to AP for phone calls.
        ##       Alarmpoint is having a hard time dealing with the CRLF and other interesting characters.
        ##
        
        #if ($debug_extensive)                                          { print AN_LOGFILE "\t\tGE 03 and LE 05\n"; }
        
        my $email_from    = $email_from;
        my $email_to      = $email_dl;
        my $email_cc      = $email_cc;
        my $email_subject = "$node : $message_text";
        my $email_body    = "NetIQ severity: ${netiq_sev}\n\n${long_message}\n\n${netiq_specifics}";
        
        my $status = mail_alert($email_from, $email_to, $email_cc, $email_subject, $email_body);

        #if ($debug_extensive)                                          { print AN_LOGFILE "\t\tStatus of sending email:    $status\n"; }
    
        my %ap_data = (
                    'map_data'        => "alternate-notification",
                    'script'          => "BGI NetIQ",
                    'groupname'       => "Windows On-Call FTS",
                    'eventid'         => "$msgid",
                    'messagetext'     => "$message_text",
                    'longmessage'     => "$long_message",
                    'host'            => "$node",
                    'severity'        => "$severity",
                    'ticket'          => "TBA",
                    'logfile'         => "",
                    'contact_device'  => "PHONE",
                    'netiq_severity'  => "$netiq_sev",
                    'netiq_specifics' => "$netiq_specifics",
                    'contact_options' => "",
                    'behavior'        => ""
                   );
        
        $status = alarmpoint_alert(\%ap_data);
      
        #if ($debug_extensive)                                          { print AN_LOGFILE "\t\tGoing for the phone!:       $status\n"; }
      
      ## v v v 
      ## Commented out, per instructions from Windows team.
      ##
      #} elsif (($netiq_sev >= 6) && ($netiq_sev <= 10)) {
      #  
      #  if ($debug_extensive)                                          { print AN_LOGFILE "\tGE 6 and LE 10\n"; }
      #
      #  %ap_data = (
      #              'map_data'        => "alternate-notification",
      #              'script'          => "BGI NetIQ",
      #              'groupname'       => "Windows On-Call FTS",
      #              'eventid'         => "$msgid",
      #              'messagetext'     => "$message_text",
      #              'longmessage'     => "$long_message",
      #              'host'            => "$node",
      #              'severity'        => "$severity",
      #              'ticket'          => "TBA",
      #              'logfile'         => "",
      #              'contact_device'  => "EMAIL",
      #              'netiq_severity'  => "$netiq_sev",
      #              'netiq_specifics' => "$netiq_specifics",
      #              'contact_options' => "emailonly",
      #              'behavior'        => ""
      #             );
      #  
      #  $status = alarmpoint_alert(\%ap_data);
      #
      #  if ($debug_extensive)                                          { print AN_LOGFILE "\tGoing for the normal escalation!: $status\n"; }
      ## ^ ^ ^
        
      }
      elsif ($netiq_sev == 17) {
        ##
        ## Note: due to the interesting long messages, these are being sent via email.  Alarmpoint is having a hard time dealing with the CRLF and other
        ##       interesting characters.
        ##
        
        if ($debug_extensive)                                          { print AN_LOGFILE "\t\tEQ 17\n"; }
        
        $email_from    = $email_from;
        $email_to      = $email_dl;
        $email_cc      = $email_cc;
        $email_subject = "$node : $message_text";
        $email_body    = "NetIQ severity: ${netiq_sev}\n\n${long_message}\n\n${netiq_specifics}";
        
        $status = mail_alert($email_from, $email_to, $email_cc, $email_subject, $email_body);
			  $send_to_ap_if_p_down = 0;                               # If Peregrine is down, don't send to AP

        if ($debug_extensive)                                          { print AN_LOGFILE "\t\tStatus of sending email:     $status\n"; }

        #%ap_data = (
        #            'map_data'        => "alternate-notification",
        #            'script'          => "BGI NetIQ",
        #            'groupname'       => "Windows On-Call FTS",
        #            'eventid'         => "$msgid",
        #            'messagetext'     => "$message_text",
        #            'longmessage'     => "$long_message",
        #            'host'            => "$node",
        #            'severity'        => "$severity",
        #            'ticket'          => "TBA",
        #            'logfile'         => "",
        #            'contact_device'  => "EMAIL",
        #            'netiq_severity'  => "$netiq_sev",
        #            'netiq_specifics' => "$netiq_specifics",
        #            'contact_options' => "emailonly",
        #            'behavior'        => ""
        #           );
        
      
        #$status = alarmpoint_alert(\%ap_data);
        
      
        if ($debug_extensive)                                          { print AN_LOGFILE "\t\tGoing for the email only!:   $status\n"; }
        
      }
      elsif ($netiq_sev == 22)  {
        ##
        ## Note: due to the interesting long messages, these are being sent via email.  Alarmpoint is having a hard time dealing with the CRLF and other
        ##       interesting characters.
        ##
    
        if ($debug_extensive)                                          { print AN_LOGFILE "\t\tThis is a sev 22 event.\n"; }
        
        $email_from    = 'alarmpoint@barclaysglobal.com';
        $email_to      = 'appmgradmin@barclaysglobal.com';
        $email_cc      = '';
        $email_subject = "$node : $message_text";
        $email_body    = "NetIQ severity: ${netiq_sev}\n\n${long_message}\n\n${netiq_specifics}";
        
        $status = mail_alert($email_from, $email_to, $email_cc, $email_subject, $email_body);
    
        
        if ($debug_extensive)                                          { print AN_LOGFILE "\t\tGoing for the email to netiq admins only!:  $status\n"; }
        vpo_ack_event($msgid);
	$send_to_ap_if_p_down = 0;                               # If Peregrine is down, don't send to AP
        $ticket_to_peregrine  = 0;
        
      }
      elsif ($netiq_sev == 25)  {
        ##
        ## Added sev 25 at request of Windows team - KMM 28-07-08
        ##       interesting characters.
        ##
    
        if ($debug_extensive)                                          { print AN_LOGFILE "\t\tThis is a sev 25 event.\n"; }
        
        $email_from    = 'alarmpoint@barclaysglobal.com';
        $email_to      = 'bgiitwindowsglobal@barclaysglobal.com';
        $email_cc      = '';
        $email_subject = "$node : $message_text";
        $email_body    = "NetIQ severity: ${netiq_sev}\n\n${long_message}\n\n${netiq_specifics}";
        
        $status = mail_alert($email_from, $email_to, $email_cc, $email_subject, $email_body);
    
        
        if ($debug_extensive)                                             { print AN_LOGFILE "\t\tGoing for the email to netiq admins only!:  $status\n"; }
        vpo_ack_event($msgid);
	$send_to_ap_if_p_down = 0;                               # If Peregrine is down, don't send to AP
        $ticket_to_peregrine  = 0;
        
      }
      else {
        
        ## Nichj, 2005-07-01, Add this logic per request by Windows group to have all messages go to netIQ admin team.
        ##
        if ($catchall) {

            $send_to_ap_if_p_down = 0;                               # If Peregrine is down, don't send to AP
          if ($debug_extensive)                                        { print AN_LOGFILE "\t\tThis is a catch-all event.\n"; }
          
          $email_from    = 'alarmpoint@barclaysglobal.com';
          $email_to      = 'appmgradmin@barclaysglobal.com';
          $email_cc      = '';
          $email_subject = "$node : $message_text";
          $email_body    = "NetIQ severity: ${netiq_sev}\n\n${long_message}\n\n${netiq_specifics}";
          
          $status = mail_alert($email_from, $email_to, $email_cc, $email_subject, $email_body);

          if ($debug_extensive)                                        { print AN_LOGFILE "\t\tGoing for the email to netiq admins only!:  $status\n"; }
          vpo_ack_event($msgid);
          $ticket_to_peregrine  = 0;

          
        }
        else {
        
          if ($debug_extensive)                                          { print AN_LOGFILE "\t\t** This event fell outside of alertable parameters **\n"; }
          vpo_ack_event($msgid);
          $ticket_to_peregrine  = 0;
          
        }
  
      }
      
      return $retval;
    
  }
  # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

  # ====================================================================  
  # Sub Function: alternate_notification_type()
  #
  #  Assumes \%vpo_data and %cma are populated
  #  
  # Returns: alternate_notification_type of
  #           netiq   - if a netiq message
  #           <blank> - (or NULL) if not destined for alternate notification
  #
  # -------------------------------------------------------------------
  sub alternate_notification_type {
    my $retval = 0;
    
    if ($cma{'netiq_severity'}) { $retval = "netiq"; }
    
    return $retval;
    
  }
  # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^



}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 bypass_peregrine()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function: bypass_peregrine()
  #  This assumes the data structures, logfiles, etc are present and accounted for
  #
  # -------------------------------------------------------------------
  
=cut

sub bypass_peregrine {
  if ($debug_extensive)                                              { print AN_LOGFILE "\t\tBypassing Peregrine and going directly to Alarmpoint\n"; }

    my $ap_group_name = get_ap_group_name($message_group);
    
    if ($debug_extensive)                                            { print AN_LOGFILE "\t\tThe alarmpoint group name is $ap_group_name\n"; }
    # The alarmpoint data structure 
		#
    %ap_data = (
                'map_data'        => "peregrine",
                'script'          => "BGI On-Call",
                'groupname'       => "$ap_group_name",
                'eventid'         => "$msgid",
                'messagetext'     => "$message_text",
                'longmessage'     => "$message_text",
                'host'            => "$node",
                'severity'        => numeric_sev("$severity"),
                'ticket'          => "TBA",
                'logfile'         => "",
                'contact_device'  => "",
                'contact_options' => "",
                'behavior'        => ""
               );

	if ($ap_data{'severity'} > 3) {

    if ($debug_extensive)                                              { print AN_LOGFILE "\t\tThe severity of this message ($ap_data{'severity'}) is insufficient to send to Alarmpoint\n"; }

  } else {
  
    if ($debug_extensive)                                              { print AN_LOGFILE "\t\tSending to Alarmpoint for notification. Severity = $ap_data{'severity'}\n"; }
    $status = alarmpoint_alert(\%ap_data);
    if ($debug_extensive)                                              { print AN_LOGFILE "\t\tStatus of sending to Alarmpoint:            $status\n"; }

  }

	return 1;

}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


#####################################################################
# Do not change this.  Required for successful require load
return 1;
#####################################################################


__END__


#Function template:
#
#=head2 function_name($options)
#
#	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#	#
#	# Function:     
#	#
#	# Description:  
#	#
#	# Returns:      
#	#
#	# Requires:     
#	#
#	# -------------------------------------------------------------------
#	
#=cut
#
#sub function_name {
#
#
#
#}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

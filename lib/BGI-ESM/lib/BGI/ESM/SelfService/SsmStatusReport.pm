###################################################################
##
## 2005-08-22: Nichj: TODO: Make into Package

#
#             File: ssm_status_report.pm
#         Revision: 1.21
#
#           Author: John Nichols
#
#    Original Date: 2005-03-28
#
#      Description: This is a set of functions supporting status reporting
#                   
#            Usage: require "ssm_status_report.pm";
#
#     Requirements: ssm_common.pm module usually loads this
#                   
#
# Revision History:
#
#  Date     Initials  Vers  Description of Change
#
#  2005-03-28 nichj   1.00  <Initial Version>
#
#  2005-03-28 nichj   1.10  Added historical logging of status
#
#  2005-04-04 nichj   1.11  Added SUCCESS_COUNT to status fields.
#
#  2005-04-05 nichj   1.12  Added return to normal notification
#
#  2005-05-06 nichj   1.13  Changed the fail count to 3
#                           Fixed the still running hours number format
#
#  2005-05-07 nichj   1.20  Added option for dealing with always running programs.
#
#  2005-05-18 nichj   1.21  removed alerting as this will be handled by VPO templates.
#
######################################################################

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: status_report($program_name, $status_file, $status, $status_reason)
#
#  
#  $program_description  :: The name of the calling program
#  $status_file          :: the file that holds the status information
#  $status               :: start    - the program started
#                           end_pass - the program ended properly
#                           end_fail - the program ended with a problem
#  $fail_reason          :: The descriptiong of why the program failed.
#
# -------------------------------------------------------------------
sub status_report {
  
  my $status_report_version = "$0 version 1.21";
     $program_description   = $_[0];
  my $status_file           = $_[1];
  my $status_history_file   = "$status_file" . ".history";
  my $incoming_status       = lc $_[2];
     $fail_reason           = $_[3];
  my $EPOCH_MIN             = 60;
  my $EPOCH_HOUR            = $EPOCH_MIN * 60;
  my $ALERT_COUNT_TO_SEND   = 3;
  my $ALERT_HOURS_TO_SEND   = 6;
  my $ALERT_PARAMETERS      = '-a esm -s minor -A "emailfyi, bgiitesm@barclaysglobal.com"';
  my $RTN_PARAMETERS        = '-a esm -s normal -A "emailfyi, bgiitesm@barclaysglobal.com"'; # Return to Normal (RTN) alert parameters
  
  ## Error Checking: The file name must be set
  ##
  if ($status_file eq "") {
    print " Error with status_report function: improper arguments. No status file\n\n";
    return 1;
  }
  
  ##
  ## The main if statement
  ##
  
  if       ($incoming_status eq "start") {
    ##
    ## If the status is Start then update the start fields
    ##
    get_status_file_header_list();                                         # get the list of fields in the status file

    get_status_information();                                              # populate the status fields hash
    
    ## Updated values
    $start_time_epoch          = time();                                       # fields specific to the start status
    $start_time_display        = epoch_to_display($start_time_epoch, "local"); #
    
    ## Keeping previous values
    $end_time_epoch            = "";
    $end_time_display          = "";
    $last_success_epoch        = $status_fields {"LAST_SUCCESS_EPOCH"};
    $last_success_display      = $status_fields {"LAST_SUCCESS_DISPLAY"};
    $success_count             = $status_fields {"SUCCESS_COUNT"};
    $fail_count                = $status_fields {"FAIL_COUNT"};
    $fail_alert_count          = $status_fields {"FAIL_ALERT_COUNT"};
    $fail_alert_sent_epoch     = $status_fields {"FAIL_ALERT_SENT_EPOCH"};
    $fail_alert_sent_display   = $status_fields {"FAIL_ALERT_SENT_DISPLAY"};
    $status_of_run             = $status_fields {"STATUS"};
    $fail_reason               = $status_fields {"FAIL_REASON"};

    update_status_fields();                                                # update the status fields hash with new information
    
    update_status_file();                                                  # update the status file
    
  } elsif ($incoming_status eq "end_pass") {
    ##
    ## If the status is End_Pass (ending with a pass) then update the success fields
    ##
    
    get_status_file_header_list();

    get_status_information();
    
    if ($fail_count ge $ALERT_COUNT_TO_SEND) {
      #
      # If the previous run was a fail the alert with a return to normal.
      # 
      %alert_params           = (
                                 "ALERT_SEND_PARAMS" => $RTN_PARAMETERS
                                );
      status_report_return_to_normal();
    }
        
    ## Updated values
    $end_time_epoch            = time();
    $end_time_display          = epoch_to_display($end_time_epoch, "local");
    $last_success_epoch        = $end_time_epoch;
    $last_success_display      = $end_time_display;
    $fail_count                = "0";
    $fail_alert_count          = "0";
    $fail_alert_sent_epoch     = "";
    $fail_alert_sent_display   = "";
    $status_of_run             = "SUCCESS";
    if ($status_fields {"SUCCESS_COUNT"} eq "") {
      $success_count            = 1;
    } else {
      $success_count            = $status_fields {"SUCCESS_COUNT"} + 1;
    }

    ## Keeping previous values
    $start_time_epoch          = $status_fields {"START_TIME_EPOCH"};
    $start_time_display        = $status_fields {"START_TIME_DISPLAY"};
    
    update_status_fields();                                                # update the status fields hash with new information
    
    update_status_file();                                                  # update the status file
    
    update_status_history("$status_history_file");                         # update the status history file
    
  } elsif ($incoming_status eq "end_fail") {
    ##
    ## If the status is End_Fail then update the failed field and leave the success fields alone.
    ##
    get_status_file_header_list();

    get_status_information();
    
    %alert_params          = (
                              "ALERT_COUNT_TO_SEND" => $ALERT_COUNT_TO_SEND,
                              "ALERT_HOURS_TO_SEND" => $ALERT_HOURS_TO_SEND,
                              "ALERT_SEND_PARAMS"   => $ALERT_PARAMETERS
                             );

    if ($fail_reason eq "") {
      $fail_reason         = "fail reason not set";
    }
    
    ## Updated values
     $fail_count                = $status_fields {"FAIL_COUNT"} + 1;
    ($fail_alert_count,
     $fail_alert_sent_epoch,
     $fail_alert_sent_display)  = status_report_alert(%alert_params);
  
     $status_of_run             = "FAIL";
     $end_time_epoch            = time();
     $end_time_display          = epoch_to_display($end_time_epoch, "local");
     
     ## Keeping previous values
     $start_time_epoch          = $status_fields {"START_TIME_EPOCH"};
     $start_time_display        = $status_fields {"START_TIME_DISPLAY"};
     $sucess_count              = $status_fields {"SUCCESS_COUNT"};
     
     update_status_fields();                                                # update the status fields hash with new information
    
     update_status_file();                                                  # update the status file

     update_status_history("$status_history_file");                         # update the status history file

  } else {
    
    print " Error with status_report function: improper arguments.\n\n";
    return 1;
    
  }
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_status_file_header_list()
#  this function is called to populate the status_file_header_list hash.
# -------------------------------------------------------------------
sub get_status_file_header_list {
  
  @status_file_header_list = (                 # The list of fields that should always be in the status file
                  "START_TIME_EPOCH",
                  "START_TIME_DISPLAY",
                  "END_TIME_EPOCH",
                  "END_TIME_DISPLAY",
                  "STATUS",
                  "LAST_SUCCESS_EPOCH",
                  "LAST_SUCCESS_DISPLAY",
                  "SUCCESS_COUNT",
                  "FAIL_COUNT",
                  "FAIL_ALERT_COUNT",
                  "FAIL_ALERT_SENT_EPOCH",
                  "FAIL_ALERT_SENT_DISPLAY",
                  "FAIL_REASON"
                 );
  
}  
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: update_status_fields()
#  this function is called to update the status_fields hash.
#  It validates that all fields are populated
# -------------------------------------------------------------------
sub update_status_fields {
  
  # the corresponding fields should be populated prior to calling this function.
  #  otherwise the status file will have blanks.
  #
  %status_fields = (
                    "START_TIME_EPOCH"        => $start_time_epoch,
                    "START_TIME_DISPLAY"      => $start_time_display,
                    "END_TIME_EPOCH"          => $end_time_epoch,
                    "END_TIME_DISPLAY"        => $end_time_display,
                    "LAST_SUCCESS_EPOCH"      => $last_success_epoch,
                    "LAST_SUCCESS_DISPLAY"    => $last_success_display,
                    "SUCCESS_COUNT"           => $success_count,
                    "FAIL_COUNT"              => $fail_count,
                    "STATUS"                  => $status_of_run,
                    "FAIL_ALERT_COUNT"        => $fail_alert_count,
                    "FAIL_ALERT_SENT_EPOCH"   => $fail_alert_sent_epoch,
                    "FAIL_ALERT_SENT_DISPLAY" => $fail_alert_sent_display,
                    "FAIL_REASON"             => $fail_reason
                   );
  
  ###
  ### Validate all values are set properly before writing out to the file
  ###
  my $counter          = 0;
  my $header_not_found = "";
  
  # Make sure each header item is accounted for
  #
  foreach $header_item (@status_file_header_list) {
    
    if (exists $status_fields{"$header_item"}) {
      
      if ($debug_extensive)                                          { print " header found in file: $header_item\n"; }
      
    } else {
      
      $header_not_found[$counter] = $header_item;
    }
    
  }
  
  # if any of the header items are not accounted for, populate
  #  the item with a blank
  #
  if ($header_not_found[0] ne "") {
    if ($debug_extensive)                                            { print "\nThe following item(s) were not found in the status array and will be assigned a blank value:\n"; }
    
    foreach $header_item_not_found (@header_not_found) {
      
      if ($debug_extensive)                                          { print " $header_item_not_found not found\n"; }
      
      $status_fields{"$header_item_not_found"} = "";
      
    }
    
  }
  
  if ($debug_extensive) {
                                                                       print "\nThe updated values are:\n\n";
                                                                      
                                                                       foreach $key (sort keys %status_fields) {
                                                                         $value = $status_fields{$key};
                                                                         print "$key => $value\n";
                                                                       }
  }
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_status_information()
#  this function is called to read the status file and populate the status_fields hash.
# -------------------------------------------------------------------
sub get_status_information {
  
  @status_file_contents = read_file_contents("$status_file");       # read the contents of the status file into an array
  
  if ($debug_extensive)                                             { print "$status_file contents:\n"; }
  
  ###
  ### Some assumptions about the status file:
  ###  each line will have status information in named value pairs
  ###  delimited by an equal (=).
  ###
  
  %status_fields = get_status_fields(@status_file_contents);                         # convert the array with the contents of the file into a hash
  
  if ($debug_extensive)                                             {
    
                                                                      print "\nThe incoming status fields are:\n\n";
  
                                                                      while (($key, $value) = each(%status_fields)) {
                                                                        print "$key :: $value\n";
                                                                      }
                                                                      
  }
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_status_fields()
#  this function is called to split the status file into a hash.
#
# -------------------------------------------------------------------

sub get_status_fields {
  
  my $item       = "";
  my $line       = "";
  my $fieldsplit = "";
  
  for $item (@status_file_contents) {
    
    chomp($item);
    
    $item = trim($item);
    @line = split /=/, $item;
    
    if ($line[1] ne "") {
      
      $fieldsplit{"$line[0]"} = $line[1];
      
    }
    
    if ($debug_extensive)                                            { print "$item\n"; }
  }
  
  return %fieldsplit;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: update_status_file()
#  this function is called to update the status_file.
# -------------------------------------------------------------------
sub update_status_file {

  open (STATUS_FILE, ">$status_file");

  foreach $key (sort keys %status_fields) {
    $value = $status_fields{$key};
    print STATUS_FILE "$key=$value\n";
  }

  close  STATUS_FILE;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: update_status_history()
#  this function is called to write the history of the run
#
# -------------------------------------------------------------------
sub update_status_history {
  
  my $status_history_file = $_[0];
  my $fail_text           = "";
  my $status_history      = "";
  my $status_filler       = $status_of_run;                          # used to make sure all fields line up for the most part
  my $duration            = $end_time_epoch - $start_time_epoch;
  
  if ($status_of_run eq "FAIL") {
    $fail_text = ".. Fail reason: $fail_reason";
    $status_filler = "FAIL   ";
  } 
  
  $status_history         = "$end_time_display .. Status: $status_filler .. Start: $start_time_display .. End: $end_time_display .. Duration: $duration $fail_text\n";
  
  open (STATUS_HISTORY, ">>$status_history_file");
  
  print STATUS_HISTORY "$status_history";
  
  close STATUS_HISTORY;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: status_report_alert(%alert_params)
#  this function is called to setup all standard variables.
# -------------------------------------------------------------------
sub status_report_alert {
  #  this assumes the following variables are set:
  ## %status_fields
  ## It will return the following values in this order:
  ##  $fail_alert_count,        This is incremented if an alert is sent
  ##  $fail_alert_sent_epoch,   This is set if an alert is sent
  ##  $fail_alert_sent_display  This is set if an alert is sent 
  
  my %alert_params                = @_;
  my $DEFAULT_ALERT_COUNT_TO_SEND = 3;
  my $DEFAULT_ALERT_HOURS_TO_SEND = 6;
  my $DEFAULT_ALERT_SEND_PARAMS   = '-a esm -s minor -A "emailfyi, bgiitesm@barclaysglobal.com"';
  my $alert_message               = "";
  my $TRUE                        = 1;
  my $FALSE                       = 0;
  my $send_alert                  = $FALSE;
  
  ### Make sure the alert params are set.  If not then set defaults

  if  (
       (  not exists $alert_params{"ALERT_COUNT_TO_SEND"}        ) ||
       ( (    exists $alert_params{"ALERT_COUNT_TO_SEND"}      )   &&
         (           $alert_params{"ALERT_COUNT_TO_SEND"} eq "") )
      ) {
    
    $alert_params{"ALERT_COUNT_TO_SEND"} = $DEFAULT_ALERT_COUNT_TO_SEND;
   
  }
  
  if  (
       (  not exists $alert_params{"ALERT_HOURS_TO_SEND"}        ) ||
       ( (    exists $alert_params{"ALERT_HOURS_TO_SEND"}      )   &&
         (           $alert_params{"ALERT_HOURS_TO_SEND"} eq "") )
      ) {
    
    $alert_params{"ALERT_HOURS_TO_SEND"} = $DEFAULT_ALERT_HOURS_TO_SEND;
   
  }

  if  (
       (  not exists $alert_params{"ALERT_SEND_PARAMS"}          ) ||
       ( (    exists $alert_params{"ALERT_SEND_PARAMS"}        )   &&
         (           $alert_params{"ALERT_SEND_PARAMS"}   eq "") )
      ) {
    
    $alert_params{"ALERT_SEND_PARAMS"}   = $DEFAULT_ALERT_SEND_PARAMS;
   
  }

  if ($debug) {
                                                                        print "\nThe Alert Params values are:\n\n";
                                                                        
                                                                        foreach $key (sort keys %alert_params) {
                                                                          $value = $alert_params{$key};
                                                                          print "$key => $value\n";
                                                                        }
  }

  ### Test for count
  ###
  ### An alert is sent when the %status_file{Fail_alert_count} is less than 1
  ###  and the $fail_count is = ALERT_COUNT_TO_SEND
  if ($fail_count eq $alert_params{"ALERT_COUNT_TO_SEND"}) {
    $send_alert = $TRUE;
    $alert_text = "It appears $program_description has failed to complete after $fail_count tries on $HOSTNAME.  Please investigate. Fail reason: $fail_reason.";
  }
  
  ### Test for time
  ###
  ### Send an alert if $fail_count > 0 and
  ###  The amount of time passed since the last send is greater than the
  ###  ALERT_HOURS_TO_SEND
  if ($fail_count gt $alert_params{"ALERT_COUNT_TO_SEND"}) {
    
    # calculate the amount of seconds passed since the last alert was sent
    $time_passed = $status_fields{"START_TIME_EPOCH"} - $status_fields{"FAIL_ALERT_SENT_EPOCH"};
    # get the number of hours passed since the last alert was sent.
    $time_passed = sprintf "%.1f", ($time_passed / 360);
    
    # if the number of hours since the last alert was sent is greater than or equal to
    #  the ALERT_HOURS_TO_SEND then send the message
    if ($time_passed ge $alert_params{"ALERT_HOURS_TO_SEND"}) {
      $send_alert = $TRUE;
      $alert_text = "It appears $program_description still has not completed successfully after $time_passed hours on $HOSTNAME. Please investigate. Fail reason: $fail_reason.";
    }
  }
  
  if ($send_alert eq $TRUE) {
    
    # update the alert send params for the status file
    # set the fields to return the updated values
    $fail_alert_count        = $status_fields{"FAIL_ALERT_COUNT"} + 1;
    $fail_alert_sent_epoch   = time();
    $fail_alert_sent_display = epoch_to_display("$fail_alert_sent_epoch", "local");
    #`$SSM_BIN/vposend $alert_params{"ALERT_SEND_PARAMS"} -m \"$alert_text\"`;
    
    } else {
    
    $fail_alert_count        = $status_fields{"FAIL_ALERT_COUNT"};
    $fail_alert_sent_epoch   = $status_fields{"FAIL_ALERT_SENT_EPOCH"};
    $fail_alert_sent_display = $status_fields{"FAIL_ALERT_SENT_DISPLAY"};
    
  }

  return "$fail_alert_count", "$fail_alert_sent_epoch", "$fail_alert_sent_display";
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: status_report_return_to_normal()
#  this function is called to setup all standard variables.
# -------------------------------------------------------------------
sub status_report_return_to_normal {
  
  return 1;
  
  #my $alert_text = "It appears $program_description on $HOSTNAME is working properly now after $fail_count failures.";
  
  #`$SSM_BIN/vposend $alert_params{"ALERT_SEND_PARAMS"} -m \"$alert_text\"`;

}

return 1;

# ===================================================================
# End of FUNCTIONS
# ===================================================================
#
# 2005-04-05: NichJ :
#  I created the main if statement with redundant options so the program wouldn't unnecessarily process
#  file reads.  
#
#  The structure of this program needs work.  I know the variable assumptions I've used are not good
#  programming.  
#
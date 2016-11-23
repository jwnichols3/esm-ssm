
=head1 NAME

Test module for BGI ESM Common E2E (end-to-end) methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::E2E methods

=head1 REVISIONS

CVS Revsion: $Revision: 1.1 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2009-02-28   nichj   Developing
  #  2009-03-09   nichj   Clean up and documenting status of the tests.
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:
	
=cut

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
use Carp;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;

my @subs = qw(
    checkmail
    sendopcmsg
    store_statistics
    insert_stats_db
    opcagt_running
    e2e_alert
    e2e_log
    ticket_from_text
 );

BEGIN { use_ok('BGI::ESM::Common::E2E', @subs); };

#########################

can_ok( __PACKAGE__, 'checkmail');
can_ok( __PACKAGE__, 'sendopcmsg');
can_ok( __PACKAGE__, 'store_statistics');
can_ok( __PACKAGE__, 'insert_stats_db');
can_ok( __PACKAGE__, 'opcagt_running');
can_ok( __PACKAGE__, 'e2e_alert');
can_ok( __PACKAGE__, 'e2e_log');
can_ok( __PACKAGE__, 'ticket_from_text');

OPCAGT_RUNNING:
{
    # Status: partial. Remaining is to shutoff the agent and test for a 0 return.
    my $opcagt_status_result = 1;
    my $opcagt_status = opcagt_running();
    is ($opcagt_status, $opcagt_status_result, 'opcagt_running( ) should return true: ' . $opcagt_status);
}

SENDOPCMSG:
{
    # Status: Partial. Sending the message is testing, but testing to see if the event made it to OVO is not.
    my $ctime = time;
    my $message_text = "BGI-ESM-Common-E2E test $ctime";
    my $eventid;
    
    my %opcparms = (
        severity        => "warning",
        app             => "endtoend",
        obj             => "test",
        message_group   => "notification_sc",
        message_text    => $message_text,
        id              => 1,
        
    );
    
    if (not opcagt_running()) {
        print "OPC Agent Not Running!\n";
    }
    else {
        $eventid = sendopcmsg(\%opcparms);
        print "Message ID = $eventid - use http://esm/vpo/vpo-event-details.cfm?vpoEventID=$eventid&vpo=dev to test\n";
    }

    is ($eventid, $eventid, "sendopcmsg should return the event id :" . $eventid . " use http://esm/vpo/vpo-event-details.cfm?vpoEventID=$eventid&vpo=dev to test\n");
    
}

E2E_ALERT:
{
    # Status: Not written.
    # Logic: generate email alert, test to see if alert was received in email. Test all thresholds and options.
    # generate email
    print "E2E_ALERT\n";
    is (1,1, "e2e_alert test not completed");
}

CHECKMAIL:
{
    # Status: Not written.
    # Logic: send email, check to see if email was received.
    #  send email, change search criteria to not find email and get not-found return.
    print "CHECKMAIL\n";
    # check mail from alert
    # check and delete email from alert
    is (1,1, "checkmail test not completed");
    
}

E2E_LOG:
{
    # Status: Not written.
    # Logic: write an entry to the E2E log. Read the E2E log to verify the entry was added.
    print "E2E_LOG\n";
    is (1,1, "e2e_log test not completed");

}

TICKET_FROM_TEXT:
{
    # Status: complete.
    # set a ticket number inside a string of text as it appears from Alarmpoint
    # send that string of text to ticket_from_text

    my ($ticket_text, $expected_ticket, $ticket_returned);
    
    $expected_ticket = "null";
    $ticket_text = "Peregrine Major Ticket null";
    $ticket_returned = ticket_from_text($ticket_text);
    is ($expected_ticket, $ticket_returned, "ticket_from_text - Expected ticket: $expected_ticket versus ticket returned: $ticket_returned\n");
    
    $expected_ticket = "IM001000";
    $ticket_text = "Peregrine Major Ticket IM001000";
    $ticket_returned = ticket_from_text($ticket_text);
    is ($expected_ticket, $ticket_returned, "ticket_from_text - Expected ticket: $expected_ticket versus ticket returned: $ticket_returned\n");
}


STORE_STATISTICS:
{
    # Status: Partial. Missing the validation routine.
    my $t               = time;
    my $DATE            = _get_formatted_date();
    my $severity        = "normal",
    my $stats_file      = "store_stats_test.log";
    my $expected_status = 1;
    my %stats = (
        finish_date     => $DATE,              
        finish_status   => "Success", 
        elapsed_time    => $t,
        event_id        => "ovoeventid " . $t, 
        ticket_num      => "IM" . $t,
        severity        => $severity,
        environment     => "dev",    #optional - will set to prod if blank
        stats_file      => $stats_file,
    );

    my $status = store_statistics(\%stats);
    
    is ($status, $expected_status, "store_statistics returned $status\n");        

    print "Pausing to let a few seconds pass, so the primary key doesn't conflict...\n";
    sleep 3;
    
    $t = time;
    $severity = "failure";

    %stats = (
        finish_date     => $DATE,              
        finish_status   => "Failure", 
        elapsed_time    => 1720,
        event_id        => "ovoeventid" . $t,
        ticket_num      => "",
        severity        => $severity,
        environment     => "dev",    #optional - will set to prod if blank
        stats_file      => $stats_file,
    );

    $status = store_statistics(\%stats);
    
    is ($status, $expected_status, "store_statistics returned $status\n");        
}


###########################################################################
## Internal Routines
###########################################################################

sub _get_formatted_date {
    my ($seconds, $minute, $hour, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
    
    $month = $month + 1;
    $year  = $year  + 1900;
    
    my $retval = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $minute, $seconds);
    
    return $retval;
}
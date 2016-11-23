
=head1 NAME

BGI ESM Common Shared Methods: E2E functions

=head1 SYNOPSIS

This library is used in the end-2-end monitoring script.

=head1 REVISIONS

CVS Revision: $Revision: 1.19 $
    Date:     $Date: 2009/03/10 20:20:44 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2009-02-27   nichj   Create
  #  2009-03-10   nichj   Updated e2e_alert with hostname
  #
  #####################################################################

=head1 TODO

##
##

=cut


###############################################################################
### Package Name ##############################################################
package BGI::ESM::Common::E2E;
###############################################################################

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Win32::MAPI;
use DBI;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type print_array_file trim get_formatted_date_time scalar_from_array mail_alert sms_alert_send get_hostname);
use BGI::ESM::Common::Variables qw(agent_variables);
no strict "subs";
no strict "vars";

###############################################################################

###############################################################################
### Require Section ###########################################################
require Exporter;
###############################################################################

###############################################################################
### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::Common);
###############################################################################

###############################################################################
### Public Exports ############################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    checkmail
    sendopcmsg
    store_statistics
    insert_stats_db
    opcagt_running
    e2e_alert
    e2e_log
    ticket_from_text
);
###############################################################################

###############################################################################
### VERSION ###################################################################
our $VERSION = (qw$Revision: 1.19 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################
#our $ssm_vars                     = ssm_variables();
our $agent_vars                   = agent_variables();
#our $agent_version                = get_agent_version();
#our $agent_comm_type              = get_agent_comm_type();


###############################################################################
# Public Methods / Functions
###############################################################################

=head2 checkmail( \%checkmail_options )

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     checkmail( \%checkmail_options )
	# Description:  sets a hash array with various variables based on the version of the agent version.
	# Returns:      either false (if not found) or a pointer to the message data hash
	# Requires:     Win32::MAPI, Outlook profile
        # Refactor:     
        
        #heckmail Options Hash        
        #%checkmail_options = (
        #    profile         => Outlook profile
        #    password        => password to login to Outlook profile
        #    subject_search  => the expression to search for in the subject
        #    msgtext_search  => the expression to search for in the message text
        #    delete          => (1 (yes) or 0 (no) ) = if the message is found, delete - DEFAULT = N
        #    times_to_check  => How many times to check for the message
        #    sleep_btw_check => How long to sleep between checks
        #);
  # -------------------------------------------------------------------

=cut
sub checkmail($) {
    my ($arg_ref) = @_;
    
    my $profile         = _not_blank($arg_ref->{profile});
    my $password        = _not_blank($arg_ref->{password});
    my $subject_search  = $arg_ref->{subject_search};
    my $msgtext_search  = $arg_ref->{msgtext_search};
    my $delete          = $arg_ref->{delete};
    my $times_to_check  = $arg_ref->{times_to_check};
    my $sleep_btw_check = $arg_ref->{sleep_btw_check};
    my $debug           = $arg_ref->{debug};

    my ($data, $found, %data, $i);
    
    if (not $times_to_check) {
        $times_to_check = 1;
    }

    if (not $sleep_btw_check) {
        $sleep_btw_check = 0;
    }

    my($obj)=new Win32::MAPI(Profile => $profile, Password => $password);
    
    $obj->Logon() or die "Can't logon! __vpo__ app=esm sev=minor message=problem checking end-to-end email.";
    
    our %options=(LeaveUnread=>1,NoAttachments=>1,UnreadOnly=>0,HeaderOnly=>0);
    
    $obj->SetReadOptions(\%options);
    
    for ($i = 1; $i <= $times_to_check; $i++) {
        
        my $unread = $obj->CountUnread();

        if ($debug) { print "Number of unread messages: $unread\n"; }
        if ($debug) { print "Checking $times_to_check times. Check number $i\n"; }
    
        while ($obj->Next()) {
        
            $obj->Read(\%data);
            
            if ($debug) { print $data{Subject} . "\n"; }
            
            my $subject = $data{Subject};
            my $text    = $data{Text};
            
            if ($debug) {

                print "subject:        $subject\n";
                print "subject search: $subject_search\n";
                print "text:           $text\n";
                print "text search:    $msgtext_search\n";

            }
            
            #if (( $data{Subject} =~ m/($subject_search)/) and ( $data{Text} =~ m/($msgtext_search)/)) {
            if (( $subject =~ m/($subject_search)/) and ( $text =~ m/($msgtext_search)/)) {
              
                if ($debug) {print "Found the criteria\n";}
                
                if ($delete) {
                    $obj->Delete();
                }
                
                # Exit the while loop
                $found = \%data;
                last;
            
            }
            else {
                if ($debug) { print "Not found...\n"; }
            }
        
        }

        if ($found) {
            last;
        }
        
        sleep $sleep_btw_check;
        
    }
    
    if ($debug) { print "Complete...\n"; }
    
    return $found;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  sendopcmsg( \%opcmsg_options )

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     sendopcmsg( \%opcmsg_options )
	# Description:  sets a hash array with various variables based on the version of the agent version.
	# Returns:      result of opcmsg command - will return the ovo message id if the id hash value is set to 1
	# Requires:     OVO agent
        # Refactor:     
        
        opcmsg options hash
        %opcmsg_options = (
            severity        => normal, warning, minor, major, critical
            app             => ovo application
            obj             => ovo object
            message_group   => ovo message group
            message_text    => ovo message text
            id              => (1 or 0 - defaults to 0) will return the id if 1
        );
  # -------------------------------------------------------------------
=cut
sub sendopcmsg($) {
    my ($arg_ref) = @_;
    
    my $severity        = _not_blank($arg_ref->{severity});
    my $app             = _not_blank($arg_ref->{app});
    my $obj             = _not_blank($arg_ref->{obj});
    my $message_group   = _not_blank($arg_ref->{message_group});
    my $message_text    = _not_blank($arg_ref->{message_text});
    my $id              = $arg_ref->{id};
    my $debug           = $arg_ref->{debug};

    if ($id) {
        $id = "-id";
    }
    my $opcmsg_parms   = "$id severity=$severity app=$app obj=$obj msg_grp=$message_group msg_text=\"$message_text\"";
    my $opcmsg_cmd     = $agent_vars->{'OpC_BIN'} . "/opcmsg";
    
    my $opcmsg_status = `$opcmsg_cmd $opcmsg_parms 2>&1`;
    chomp($opcmsg_status);
    
    if ($debug) { print "Opcmsg Status: $opcmsg_status"; }
    
    return $opcmsg_status;
   
}


# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 store_statistics( \%hash_reference )
    Function:     store_statistics
    Description:  this function will take information passed in the hash reference and send it to a logfile and to the stats database
    Returns:      status
    Requires:   

    Hash reference:
    %hash_to_pass = (
        finish_date     => <date>,              #required
        finish_status   => <Success | Failure>, #required
        elapsed_time    => <seconds> }          #required
        event_id        => ovo event id         #optional
        ticket_num      => sc ticket num        #optional
        severity        => severity of test     #optional
        stats_file      => statistics file      #optional - defaults to e2e_stats.log if blank
        environment     => "prod | dev | qa"    #optional - will set to prod if blank
        debug           => $debug,              #optional
    );    
=cut
sub store_statistics ($) {
    my ($arg_ref) = @_;
    
    my $finish_date     = _not_blank($arg_ref->{finish_date});
    my $status          = _not_blank($arg_ref->{finish_status});
    my $elapsed_time    = _not_blank($arg_ref->{elapsed_time});
    my $event_id        = _make_spaces($arg_ref->{event_id});
    my $ticket_num      = _make_spaces($arg_ref->{ticket_num});
    my $severity        = _make_spaces($arg_ref->{severity});
    my $statistics_file = _make_spaces($arg_ref->{stats_file});
    my $db_env          = $arg_ref->{db_env};
    my $environment     = $arg_ref->{environment};
    my $debug           = $arg_ref->{debug};

    my ($redir, $STATLOG);

    if (not $statistics_file) {
        my $statistics_file = "e2e_stats.log";
    }

    if (not $environment) {
        $environment = "prod";
    }
    
    if (not $db_env) {
        $db_env = "prod";
    }
    
    if (-e $statistics_file) {
        $redir = ">>";
    }
    else {
        $redir = ">";
    }

    if (not (open ($STATLOG, "$redir $statistics_file") ) ) {
        warn "Unable to open $statistics_file: $!";
        return 1;
    }
    
    print $STATLOG "| $finish_date | $status | $elapsed_time | $event_id | $ticket_num | $severity | $environment\n";
    
    close $STATLOG or warn "Unable to close $statistics_file: $!";
    
    #my $db_status = insert_stats_db({finish_date=>$finish_date, finish_status=>$status, elapsed_time=>$elapsed_time });
    my $db_status = insert_stats_db($arg_ref);
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 insert_stats_db({finish_date=>$finish_date, finish_status=>$status, elapsed_time=>$elapsed_time, debug=>$debug })
    Function:    insert_stats_db
    Description:  
    Returns:      status
    Requires:     
    
    Hash reference:
    %hash_to_pass = (
        finish_date     => <date>,              #required
        finish_status   => <Success | Failure>, #required
        elapsed_time    => <seconds> }          #required
        event_id        => ovo event id         #optional
        ticket_num      => sc ticket num        #optional
        severity        => severity of test     #optional
        stats_file      => statistics file      #optional - defaults to e2e_stats.log if blank
        environment     => "prod | dev | qa"    #optional - will set to prod if blank
        debug           => $debug,              #optional
    );
=cut
sub insert_stats_db ($) {
    my ($arg_ref) = @_;
    
    my $finish_date     = _not_blank($arg_ref->{finish_date});
    my $status          = _not_blank($arg_ref->{finish_status});
    my $elapsed_time    = _not_blank($arg_ref->{elapsed_time});
    my $event_id        = _make_spaces($arg_ref->{event_id});
    my $ticket_num      = _make_spaces($arg_ref->{ticket_num});
    my $severity        = _make_spaces($arg_ref->{severity});
    my $statistics_file = _make_spaces($arg_ref->{stats_file});
    my $db_env          = $arg_ref->{db_env};
    my $environment     = $arg_ref->{environment};
    my $debug           = $arg_ref->{debug};

    my ($dbh, $sth, $database_dbi, $retry_count, );
    my $counter = time;  #use for counter in db
    my $retry_threshold = 3;

    if (not $environment) {
        $environment = "prod";
    }

    if (not $db_env) {
        $db_env = "prod";
    }
    
    $database_dbi = "DBI:ODBC:esm_stats_" . $db_env;

    my %attr = (
                PrintError => 1,
                RaiseError => 0,
               );
    
    my $select_statement = "INSERT INTO esm_stats_e2e VALUES ( $counter, '$finish_date', '$status', '$elapsed_time', '$event_id', '$ticket_num', '$severity', '$environment' )";
    
    until   ( $dbh = DBI->connect( $database_dbi, "esm_stats", "HYPertext01", \%attr ) )
    {
            warn "Can't connect to ms-ssql database: $DBI::errstr. Pausing before retrying.\n";
            sleep ( 30 );
            $retry_count++;
            
            if ($retry_count > $retry_threshold) { return 0; }  #exit if can't connect to db after 3 attempts.
    
    }
    
    $sth = $dbh->prepare( $select_statement );
    
    $sth->execute( );
    
    $dbh->disconnect;

    return 1;
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  opcagt_running()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:    opcagt_running()
	# Description: checks to see if the opcagt process is running
	# Returns:     true if it is running, false if not
	# Requires:     
  # -------------------------------------------------------------------

=cut
sub opcagt_running {
    my $retval = 1;
    my $OPCUP;
    my $opcagtstatus_cmd = $agent_vars->{'OpC_BIN'} . '\opcagt -status 2>&1';
    
    $OPCUP = `$opcagtstatus_cmd`;
    
    if ($OPCUP=~/Agent Service is not running/) {
        $retval = 0;
    }

    return $retval;
}


=head2 e2e_alert (
    severity        => normal | warning | minor | major | critical | failure,
    action          => email | sms,
    email_list      => reference to array of email addresses in single variable,
    sms_list        => reference to array of sms numbers in comma delimited format,
    time_elapsed    => how long has elapsed,
    logfile         => logfile to status,
    debug           => $debug   (optional)
    )
=cut
sub e2e_alert {
    my ($arg_ref) = @_;
    
    my $severity        = _not_blank($arg_ref->{severity});
    my $action          = $arg_ref->{action};
    my $email_list      = $arg_ref->{email_list};
    my $sms_list        = $arg_ref->{sms_list}; # have to split and trim
    my $time_elapsed    = $arg_ref->{time_elapsed};
    my $logfile         = $arg_ref->{logfile};
    my $debug           = $arg_ref->{debug};
    
    my $hostname        = get_hostname();
    my $alert_text = "$severity error - e2e has not been successful for $time_elapsed seconds on $hostname";
    my $DATE = get_formatted_date_time();
    my %sms_params;
    my $TMPLOG;
    my @logwrite;

    if ($severity eq "failure") {
        if ($debug) { print "e2e_alert: $severity - $alert_text\n"; }
    }
    
    @logwrite = "$DATE : $severity error - e2e has not been successful for $time_elapsed seconds __VPO__ app=endtoend sev=$severity message=e2e has not been successful for $time_elapsed seconds\n";
    e2e_log( $logfile, \@logwrite );

    print "Alert level $severity\n";

    if ($action eq "email") {
        my @email_list = @$email_list;
        my $send_email = scalar_from_array(\@email_list, ";");
        my $from    = "alarm.point\@barclaysglobal.com";
        my $to      = $send_email;
        my $cc      = "";
        my $subject = "E2E Alert: $severity from $hostname";
        my $body    = $alert_text;
        
        if ($debug) { print "e2e_alert: mail_alert params from: $from, to: $to, cc: $cc, subject: $subject, body: $body)\n"; }
        mail_alert($from, $to, $cc, $subject, $body);
        
    }
    
    if ($action eq "sms") {
        my @sms_numbers = @$sms_list; #split /,/, $sms_list;

        foreach my $sms_number (@sms_numbers) {
            %sms_params = (
                sms_number  => trim($sms_number),
                message     => $alert_text,
            );
            sms_alert_send(\%sms_params);
        }
    }
    
    return 1;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  e2e_log($filename, \@arraytolog)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Description: logs e2e messages
	# Returns:     
	# Requires:    print_array_file in BGI::ESM::Common::Shared
  # -------------------------------------------------------------------

=cut
sub e2e_log ($$) {
    my $filename       = shift;
    my $incoming_array = shift;
    my @incoming_array = @$incoming_array;
    
    open ( $TMPLOG, ">> $filename") || warn "can't open log file: $!";
    print_array_file($TMPLOG, \@incoming_array);
    close  $TMPLOG;
    
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 ticket_from_text($text)
    Description: parses the message text of an Alarmpoint message and returns the ticket number
    Returns: scalar with the ticket number (null if a ticket number isn't found)
    
=cut
sub ticket_from_text ($) {
    my ($text) = @_;
    my ($prefix, $ticket) = split /Ticket/, $text;
    return trim($ticket);
}


# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################

=head2  _function_name

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:    _function_name
	# Description:  
	# Returns:      
	# Requires:     
  # -------------------------------------------------------------------

=cut


# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _not_blank
    Description: ensures that a passed parameter is not blank
    Croaks if it is.
=cut
sub _not_blank{
    my ($var_to_check) = @_;
    
    if (not $var_to_check) {
        croak "Error: Variable must be set.";
    }
    
    return $var_to_check;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _make_spaces
    Description: assigns a non-null value to the variable passed. 
=cut
sub _make_spaces {
    my ($var_to_check) = @_;
    
    if (not $var_to_check) {
        $var_to_check = "";
    }
    
    return $var_to_check;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


sub _get_formatted_date {
    my ($seconds, $minute, $hour, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
    
    $month = $month + 1;
    $year  = $year  + 1900;
    
    my $retval = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $minute, $seconds);
    
    return $retval;
}

#################################################################################
### End of Private Methods / Functions ##########################################
#################################################################################


#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES


=cut



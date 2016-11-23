
=head1 NAME

BGI ESM Common Shared Methods: Stats functions

=head1 SYNOPSIS

This library is used in Stats scripts.

=head1 REVISIONS

CVS Revision: $Revision: 1.1 $
    Date:     $Date: 2009/03/12 00:17:36 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2009-03-11   nichj   Create
  #
  #####################################################################

=head1 TODO

##
##

=cut


###############################################################################
### Package Name ##############################################################
package BGI::ESM::Common::Stats;
###############################################################################

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use DBI;
use Date::Manip;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type print_array_file trim get_formatted_date_time scalar_from_array get_hostname);
#use BGI::ESM::Common::Variables qw(agent_variables);
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
    yesterday
    store_statistics
    insert_stats_db
);
###############################################################################

###############################################################################
### VERSION ###################################################################
our $VERSION = (qw$Revision: 1.1 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################
#our $ssm_vars                     = ssm_variables();
#our $agent_vars                   = agent_variables();
#our $agent_version                = get_agent_version();
#our $agent_comm_type              = get_agent_comm_type();


###############################################################################
# Public Methods / Functions
###############################################################################

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



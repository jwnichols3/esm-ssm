=head1 NAME

BGI ESM SelfService Shared Modules

=head1 SYNOPSIS

This library is something all SSM programs will load

=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.4 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-12-06   nichj   Initial Version
  #  2005-12-07   nichj   Adding functionality around getting alert times
  #
  #####################################################################

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::SelfService::SsmShared;

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared;
use BGI::ESM::Compile::Ssm qw(get_program_exe_list_os);
#################################################################################

###############################################################################
### Require Section ###########################################################
require Exporter;
###############################################################################

###############################################################################
### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::SelfService);
###############################################################################

###############################################################################
### Public Exports ############################################################
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    ssm_program_versions
    ssm_log_when_alert
    ssm_transpose_file_name
    get_when_alert_log_file
    search_when_alert_log_file
    clear_when_alert_log_file
    get_time_passed_between_last_alerts
    get_last_alert_time
    get_time_since_last_alert
    get_all_alert_times
);

###############################################################################
### VERSION ###################################################################
our $VERSION = (qw$Revision: 1.4 $)[-1];

###############################################################################
# Public Variables
###############################################################################

###############################################################################
# Public Methods / Functions
###############################################################################

=head2 ssm_program_versions()
    
=cut

sub ssm_program_versions {
    my @return_array;
    my $ssm_var = ssm_variables();
    my $SSM_BIN = $ssm_var->{'SSM_BIN'};
    
    my $monitor_programs = get_program_exe_list_os();

    foreach my $monitor_command (@{$monitor_programs}) {
        my $version = `$SSM_BIN/$monitor_command -v`;
        chomp($version);
        push @return_array, $version;
    }
    
    return \@return_array;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 ssm_log_when_alert({ key=>$key, prefix=>$prefix })

    use when wanting to log when an alert was sent.
    
    key=>$key       = the unique key that identifies the message (e.g. $app:$sev:$node:$file)
    prefix=>$prefix = the monitor prefix (e.g. fileage)
    
    returns 1 if successfully written, croaks if not successful.
    
=cut

sub ssm_log_when_alert {
    my ($arg_ref)     = @_;
    
    my $key           = _not_blank($arg_ref->{key});
    my $prefix        = _not_blank($arg_ref->{prefix});
    
    my $when_log_file = get_when_alert_log_file({ prefix=>$prefix });
    
    my $splitter      = _get_when_log_splitter();
    
    my @content       = "$key $splitter " . time;
    
    my $status        = write_file_contents($when_log_file, \@content);
    
    if ($status) {
        return 1;
    }
    else {
        croak "Unable to write file contents to $when_log_file; $!:";
    }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 ssm_transpose_file_name($file_to_transpose)

    use when needing to transpose a file name into a variable devoid of
    invalid characters.
    
    : is translated to _
    \ is translated to .
    
    returns transposed scalar

=cut

sub ssm_transpose_file_name {
    my ($filename_to_trans) = @_;
    
    $filename_to_trans      =~ tr/\/\\\:/.._/;
    
    return $filename_to_trans;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_when_alert_log_file({ prefix=>$prefix })

    use when needing the "when alert logfile" name
    
    prefix=>$prefix = the monitor prefix (e.g. fileage)
    
    returns a scalar with the "when alert log file"

=cut

sub get_when_alert_log_file {
    my ($arg_ref) = @_;
    my $prefix    = _not_blank($arg_ref->{prefix});

    my $ssm_vars  = ssm_variables();
    my $SSM_LOG   = $ssm_vars->{'SSM_LOGS'};
    
    return "$SSM_LOG/ssm_when_$prefix.log";
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_message_age_stat_base_file_name({ key=>$key, prefix=>$prefix })

    use when needing to get the message age stat file based on the
    prefix and the key
    
    returns the message_age_stat_base_file_name

=cut

sub get_message_age_stat_base_file_name {
    my ($arg_ref) = @_;
    
    my $key       = _not_blank($arg_ref->{key});
    my $prefix    = _not_blank($arg_ref->{prefix});
    my $transpose = _set_default_transpose($arg_ref->{transpose});
    
    if ($transpose) {
        $key = ssm_transpose_file_name($key);
    }
    
    return ("${prefix}_${key}");
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_message_age_stat_full_file_name({ key=>$key, prefix=>$prefix })

    use when needing to get the full path to message age stat
    file based on the prefix and the key
    
    returns the message_age_stat_full_file_name

=cut

sub get_message_age_stat_full_file_name {
    my ($arg_ref) = @_;
    
    my $key       = _not_blank($arg_ref->{key});
    my $prefix    = _not_blank($arg_ref->{prefix});
    my $transpose = _set_default_transpose($arg_ref->{transpose});

    my $ssm_vars       = ssm_variables();
    my $SSM_LOG        = $ssm_vars->{'SSM_LOGS'};
    my $base_file      = get_message_age_stat_base_file_name({ key=>$key, prefix=>$prefix, transpose=>$transpose });

    return ("$SSM_LOG/$base_file");
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 search_when_alert_log_file({ prefix=>$prefix, search=>$search_term })

    use this when wanting to search the 'when alert log file'
    
    the log file is assembled based on the prefix
    
    prefix=>$prefix = the monitor prefix, e.g. fileage
    search=>$search = the search term
    
    returns
    - in SCALAR a count of records
    - in LIST   a list of found records

=cut

sub search_when_alert_log_file {
    my ($arg_ref) = @_;
    
    my $prefix      = _not_blank($arg_ref->{prefix});
    my $search_term = _not_blank($arg_ref->{search});
    my $search_file = get_when_alert_log_file({ prefix=>$prefix });
    my @alert_when_contents = read_file_contents($search_file);
    my @found       = grep /$search_term/, @alert_when_contents;
    
    return @found;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 clear_when_alert_log_file({ prefix=>$prefix })

    use this when wanting to clear the 'when alert log file'
    
    prefix=>$prefix is used to assemble the 'when alert log file'

=cut

sub clear_when_alert_log_file {
    my ($arg_ref) = @_;

    my $prefix    = _not_blank($arg_ref->{prefix});
    
    my $log_file  = get_when_alert_log_file({ prefix=>$prefix });
    
    my @contents  = ("#");

    if (write_file_contents($log_file, \@contents, 'replace')) {
        return 1;
    }
    else {
        return;
    }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_time_passed_between_last_alerts({ prefix=>$prefix, key=>$key, format=>[minutes | seconds] })

    use when needing to know how much time has passed between the last two alerts
    produced by the <alert> based on the <key>
    
    prefix=>$prefix             = the monitor prefix (e.g. fileage)
    key=>$key                   = the search key that identifies the unique messages
    format=>[minutes | seconds] = seconds (default) or minutes
    
    returns
     - if alerts found, scalar with number of seconds or minutes (based on <format>) 
     - if alerts not found, 0
     - if less than two alert records, 1
    
=cut

sub get_time_passed_between_last_alerts {
    my ($arg_ref) = @_;

    my $prefix      = _not_blank($arg_ref->{prefix});
    my $key         = _not_blank($arg_ref->{key});
    my $time_format = _set_time_passed_format_default($arg_ref->{'format'});
    
    my @results     = search_when_alert_log_file({ prefix=>$prefix, search=>$key });
    
    if (not @results) {
        return;
    }
    
    @results = trim(@results);
    chomp(@results);

    my @time_results   = _get_when_alert_time_fields(\@results);
    @time_results      = reverse sort @time_results;
    
    my $number_of_results = @time_results;
    
    if ($number_of_results < 2) {
        return 1;
    }
    
    my $last_time   = $time_results[0];
    my $time_before = $time_results[1];
    
    my $passed_seconds = $last_time - $time_before;
    
    if ((index $time_format, 'min') >= 0) {
        my $passed_minutes = ($passed_seconds / 60);
        return "%.2f", $passed_minutes;
    }
    else {
        return $passed_seconds;
    }
    
}

=head2 get_last_alert_time({ prefix=>$prefix, key=>$key})

    use when needing to know when the last alert was sent
    produced by the <alert> based on the <key>
    
    prefix=>$prefix             = the monitor prefix (e.g. fileage)
    key=>$key                   = the search key that identifies the unique messages
    
    returns
     - scalar with epoch time of the last alert
     - if alerts not found, 0
    
=cut

sub get_last_alert_time {
    my ($arg_ref) = @_;

    my $prefix      = _not_blank($arg_ref->{prefix});
    my $key         = _not_blank($arg_ref->{key});

    my @results     = search_when_alert_log_file({ prefix=>$prefix, search=>$key });
    
    if (not @results) {
        return;
    }
    
    @results = trim(@results);
    chomp(@results);

    my @time_results   = _get_when_alert_time_fields(\@results);
    @time_results      = reverse sort @time_results;
    
    return $time_results[0];
}


=head2 get_time_since_last_alert({ prefix=>$prefix, key=>$key, format=>[minutes | seconds] })

    use when needing to know how much time has passed since the last alert
    produced by the <alert> based on the <key>
    
    prefix=>$prefix             = the monitor prefix (e.g. fileage)
    key=>$key                   = the search key that identifies the unique messages
    format=>[minutes | seconds] = seconds (default) or minutes
    
    returns
     - scalar with number of seconds or minutes (based on <format>) since the last alert was sent
     - if alerts not found, 0
    
=cut

sub get_time_since_last_alert {
    my ($arg_ref) = @_;

    my $prefix      = _not_blank($arg_ref->{prefix});
    my $key         = _not_blank($arg_ref->{key});
    my $time_format = _set_time_passed_format_default($arg_ref->{'format'});
    my ($time_passed);
    my $now = time;
    
    my $last_alert_time = get_last_alert_time({ prefix=>$prefix, key=>$key});
    
    if ($last_alert_time > 0) {
        $time_passed = $now - $last_alert_time;
    }
    
    if ((index $time_format, 'min') >= 0) {
        $time_passed = $time_passed / 60;
    }
    
    return $time_passed;
    
}

=head2 get_all_alert_times({ prefix=>$prefix, key=>$key})

    use when needing to know all the alert times
    produced by the <prefix> based on the <key>
    
    prefix=>$prefix             = the monitor prefix (e.g. fileage)
    key=>$key                   = the search key that identifies the unique messages
    
    returns
     - list with epoch times of all alerts
     - if alerts not found, 0
    
=cut

sub get_all_alert_times {
    my ($arg_ref) = @_;

    my $prefix       = _not_blank($arg_ref->{prefix});
    my $key          = _not_blank($arg_ref->{key});
    
    my @results      = search_when_alert_log_file({ prefix=>$prefix, search=>$key });

    my @time_results = _get_when_alert_time_fields(\@results);
    
    if (@time_results) {
        return @time_results;
    }
    else {
        return;
    }
    
}
###############################################################################
### End of Public Methods / Functions #########################################
###############################################################################


###############################################################################
### Private Methods / Functions ###############################################
###############################################################################

sub _get_when_alert_time_fields {
    my ($results_ref) = @_;
    my @results = @{$results_ref};
    
    my $splitter  = _get_when_log_splitter();
    my (@time_results);

    foreach my $item (@results) {
        my ($local_key, $item_time) = split /$splitter/, $item;
        push @time_results, $item_time;
    }
    
    if (@time_results) {
        chomp(@time_results);
        @time_results = trim(@time_results);
    }
    
    return @time_results;
}

sub _not_blank{
    my ($var_to_check) = @_;
    
    if (not $var_to_check) {
        croak "Error: Variable must be set.";
    }
    
    return $var_to_check;
    
}

sub _set_time_passed_format_default {
    my ($var_to_check) = @_;
    my $default_format = 'seconds';
    
    if (not $var_to_check) {
        return $default_format;
    }
    
    return $var_to_check;
    
}

sub _set_default_transpose {
    my ($var_to_check) = @_;
    my $default_format = 1;
    
    if (not $var_to_check) {
        return $default_format;
    }
    
    return $var_to_check;
    
}

sub _get_when_log_splitter {
    
    return '__SPLIT__';
    
}
#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES

NICHJ: 2005-12-06: After reviewing perl best practices I chose to create many of these
methods with a named parameter list:

get_some_thing({ first=>$first, second=>$second })

There are many advantages to this style of method, the most prominate being
the ability to move parameters around.

=cut

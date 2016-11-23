=head1 NAME

BGI ESM SelfService Process Methods

=head1 SYNOPSIS

This module will be used for gathering and reporting information about processes


=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.4 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-12-14   nichj   Starting
  #  2005-12-15   nichj   Finished for Windows
  #
  #####################################################################

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::SelfService::Process;

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use Carp;
use Time::Local;

use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared qw(os_type check_os trim);
###############################################################################

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
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	ssm_get_process_list
	ssm_is_process_running
	ssm_process_running_count
	ssm_process_running_time
);
###############################################################################

###############################################################################
### VERSION ###################################################################
my $VERSION = (qw$Revision: 1.4 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################

###############################################################################
# Public Methods / Functions
###############################################################################

# ===========================================================================
# ===========================================================================

=head2 ssm_get_process_list()

	arguments:	<none>
	returns:	reference to an array with the running processes.
	usage:
		my $process_list = ssm_get_process_list();
		foreach my $process (@{$process_list}) {
			print "$process is running\n";
		}
		
=cut

sub ssm_get_process_list {

    if (os_type() eq 'WINDOWS') {
        return _get_process_list_windows();
    }
    else {
        return _get_process_list_unix();
    }
    
}
# ===========================================================================
# ===========================================================================

=head2 ssm_is_process_running({ process=><process to check>, process_list=>\@process_list })

	arguments:	process=><process to check> - what process you want to check
				process_list=>\@process_list - OPTIONAL - a reference to an array with the process list to search

	returns:	reference to an array with the running processes.

	usage:
	 - without a process list passed -
	 
		my $process_to_check = "inet";
		if (ssm_is_process_running({ process=>$process_to_check })) {
			print "$process_to_check is running!\n";
		}
		else {
			print "$process_to_check is NOT running!\n";
		}
	
	 - with a process list passed -	
		my $process_list = ssm_get_process_list();
		my $process_to_check = "inet";
		if (ssm_is_process_running({ process=>$process_to_check, process_list=>$process_list })) {
			print "$process_to_check is running!\n";
		}
		else {
			print "$process_to_check is NOT running!\n";
		}

=cut

sub ssm_is_process_running {
    my ($arg_ref) = @_;
    
    my $process_to_check = _no_blanks_allowed($arg_ref->{'process'});
    my $process_list     = $arg_ref->{'process_list'};
    
    if (not $process_list) {
        $process_list = ssm_get_process_list();
    }
    
    my @results = grep /$process_to_check/, @{$process_list};
    
    if (@results) {
        return 1;
    }
    else {
        return 0;
    }
}
# ===========================================================================
# ===========================================================================

=head2 ssm_process_running_count({ process=><process to check>, process_list=>\@process_list })

	arguments:	process=><process to check> - what process you want to check
				process_list=>\@process_list - OPTIONAL - a reference to an array with the process list to search

	returns:	scalar with the number of processes running, undef if none

	usage:
	 - without a process list passed -
	 
		my $process_to_check = "inet";
		my $process_count    = ssm_process_running_count({ process=>$process_to_check })) {
		if ($process_count) {
			print "$process_to_check has $process_count instances running!\n";
		}
		else {
			print "$process_to_check is NOT running!\n";
		}
	
	 - with a process list passed -	
		my $process_list = ssm_get_process_list();
		my $process_to_check = "inet";
		my $process_count    = ssm_process_running_count({ process=>$process_to_check, process_list=>$process_list })) {
		if ($process_count) {
			print "$process_to_check has $process_count instances running!\n";
		}
		else {
			print "$process_to_check is NOT running!\n";
		}
		
=cut

sub ssm_process_running_count {
    my ($arg_ref) = @_;
    
    my $process_to_check = _no_blanks_allowed($arg_ref->{'process'});
    my $process_list     = $arg_ref->{'process_list'};
    
    if (not $process_list) {
        $process_list = ssm_get_process_list();
    }

    my @results = grep /$process_to_check/, @{$process_list};
    
    my $count = @results;
    
    return $count;
    
}
# ===========================================================================
# ===========================================================================

=head2 ssm_process_running_time({ process=><process to check>, process_list=>\@process_list, time_format=><time_format> })

	arguments:	process=><process to check> - what process you want to check
				process_list=>\@process_list - OPTIONAL - a reference to an array with the process list to search
				time_format=><time format> - epoch (default), minute, hour, day

	returns:	scalar with the epoch value of the amount of number of processes running, undef if none

	usage:
	 - without a process list passed -
	 
		my $process_to_check = "inet";
		my $process_running  = ssm_process_running_time({ process=>$process_to_check })) {
		if ($process_count) {
			print "$process_to_check has been running $process_running seconds!\n";
		}
		else {
			print "$process_to_check is NOT running!\n";
		}
	
	 - with a process list passed -	
		my $process_list = ssm_get_process_list();
		my $process_to_check = "inet";
		my $process_running  = ssm_process_running_time({ process=>$process_to_check, process_list=>$process_list })
		if ($process_running) {
			print "$process_to_check has been running $process_running seconds!\n";
		}
		else {
			print "$process_to_check is NOT running!\n";
		}
		
	 - with a time_format passed -	
		my $process_list = ssm_get_process_list();
		my $process_to_check = "inet";
		my $time_format      = "minutes";
		my $process_running  = ssm_process_running_time({ process=>$process_to_check,
		                                                  process_list=>$process_list,
														  time_format=>$time_format   })
		if ($process_running) {
			print "$process_to_check has been running $process_running minutes!\n";
		}
		else {
			print "$process_to_check is NOT running!\n";
		}
		
=cut

sub ssm_process_running_time {
    my ($arg_ref) = @_;
    
    my $process_to_check = _no_blanks_allowed($arg_ref->{'process'});
    my $process_list     = $arg_ref->{'process_list'};
	my $time_format      = _set_default_time_format($arg_ref->{'time_format'});
    
    if (not $process_list) {
        $process_list = ssm_get_process_list();
    }

    my @results = grep /$process_to_check/, @{$process_list};

    if (@results) {
        my ($running_time) = _get_process_running_time({ results=>\@results });
		$running_time      = _convert_time_format({ time=>$running_time, time_format=>$time_format });
        return $running_time;
    }
    else {
        return 0;
    }
    
}
# ===========================================================================
# ===========================================================================

###############################################################################
### End of Public Methods / Functions #########################################
###############################################################################


###############################################################################
### Private Methods / Functions ###############################################
###############################################################################

# ===========================================================================

sub _get_process_running_time {
    my ($arg_ref) = @_;
    
    my $process = _no_blanks_allowed($arg_ref->{'results'});
    
    my ($epoch_run_time);
    
    if (os_type() eq 'WINDOWS') {
        $epoch_run_time = _get_process_running_time_win({ process_list=>$process });
    }
    elsif (os_type() eq 'LINUX') {
        $epoch_run_time = _get_process_running_time_unix({ process_list=>$process });
    }
    else {
        $epoch_run_time = _get_process_running_time_unix({ process_list=>$process });
    }
    
    return $epoch_run_time;
}

# ===========================================================================

sub _get_process_list_windows {
    my $commands = get_command_hash();
    my $ps_command = $commands->{'PS'};
    my $sv_command = $commands->{'PS_NT'};
    
    my @process_list = `$ps_command`;
    my @service_list = `$sv_command`;
    
    push (@process_list, @service_list);
    
    chomp(@process_list);
    
    return \@process_list;
    
}

# ===========================================================================

sub _get_process_list_unix {
    
}

# ===========================================================================

sub _no_blanks_allowed {
	my ($incoming) = @_;
	
	if (not $incoming) {
		croak "No blanks allowed here!";
	}
	
	return $incoming;
}

# ===========================================================================

sub _get_process_running_time_win {
    my ($arg_ref) = @_;
    
    my $process_list     = $arg_ref->{'process_list'};
	
	my ($running_time);
	
	foreach my $process (@{$process_list}) {
	
    # Remove Idle & System lines
        $process =~ s/\t/ /;
        $process =~ s/^\s*//;
        my ($proc, $proc_pid, $threads, $pri, $cpu, $proc_d, $proc_t) = split(/\s+/, $process);
        
		if ( ($proc_d) and ($proc_t) ) {
			my $proc_time = "$proc_d $proc_t";
			
			my $day = substr($proc_time,0,2);
			my $mon = (substr($proc_time,3,2) - 1);
			my $yr  = substr($proc_time,6,4);
			my $hr  = substr($proc_time,11,2);
			my $min = substr($proc_time,14,2);
			my $sec = substr($proc_time,17,2);
	
			$running_time  = timegm($sec,$min,$hr,$day,$mon,$yr);
			my $current_time  = time;
            
            $running_time = $current_time - $running_time;
            
            if ($running_time) {
                last;
            }

		}
		else {
			next;
		}
	}
	
	if ($running_time) {
		return $running_time;
	}
	else {
		return;
	}
	
}

# ===========================================================================

sub _convert_time_format {
	my ($arg_ref) = @_;
	
	my $time_to_convert = _no_blanks_allowed($arg_ref->{'time'});
	my $time_format     = _set_default_time_format($arg_ref->{'time_format'});

	if ($time_format eq 'epoch') {
		return $time_to_convert;
	}
	elsif ($time_format eq 'minute') {
		$time_to_convert = ($time_to_convert / 60);
		$time_to_convert = sprintf "%.3f", $time_to_convert;
		return $time_to_convert;
	}
	elsif ($time_format eq 'hour') {
		$time_to_convert = (($time_to_convert / 60) / 60);
		$time_to_convert = sprintf "%.3f", $time_to_convert;
		return $time_to_convert;
	}
	elsif ($time_format eq 'day') {
		$time_to_convert = ((($time_to_convert / 60) / 60) / 24);
		$time_to_convert = sprintf "%.3f", $time_to_convert;
		return $time_to_convert;
	}
	else {
		carp "Invalid time format specified: $time_format";
		return $time_to_convert;
	}
}

# ===========================================================================

sub _valid_time_format_options {
	my @valid_options = qw(epoch minute hour day);
	return @valid_options;
}

# ===========================================================================

sub _set_default_time_format {
	my ($incoming) = lc shift;
	my $default_time_format = 'epoch';
	my @valid_options = _valid_time_format_options();
	
	if (not $incoming) {
		return $default_time_format;
	}
	
	my @check = grep /$incoming/, @valid_options;
    my $check = @check;
	
	if (not $check) {
		return $default_time_format;
	}
	else {
		return $incoming;
	}
	
}

# ===========================================================================


###############################################################################
### End of Private Methods / Functions ########################################
###############################################################################

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES

=cut
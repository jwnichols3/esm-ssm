=head1 NAME

BGI ESM Testing SsmShared Modules

=head1 SYNOPSIS

This library is something all SSM testing programs will load

=head1 TODO

	- message_age_check will need validation on the use of the key

=head1 REVISIONS

CVS Revision: $Revision: 1.8 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-12-07   nichj   Initial Version
  #  2005-12-08   nichj   Correcting some minor bugs
  #
  #####################################################################

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::Testing::SsmShared;

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use warnings;
use strict;
use Carp;
use Time::localtime;

use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Compile::Common;
use BGI::ESM::Common::Shared qw(os_type read_file_contents);
use BGI::ESM::SelfService::AlertConfig;
use BGI::ESM::Common::Variables;
use BGI::ESM::SelfService::SsmShared;
use BGI::ESM::Common::Debug;

#################################################################################

###############################################################################
### Require Section ###########################################################
require Exporter;
###############################################################################

###############################################################################
### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::Testing);
###############################################################################

###############################################################################
### Public Exports ############################################################
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	message_age_check
	start_time_check
	stop_time_check
	dayofweek_check
	return_day_of_week
	description_check
	time_passed_since_run
	get_logfile_location
	time_of_run
	get_file_stats
);

###############################################################################
### VERSION ###################################################################
our $VERSION = (qw$Revision: 1.8 $)[-1];

###############################################################################
# Public Variables
###############################################################################

###############################################################################
# Public Methods / Functions
###############################################################################


=head2 message_age_check({ filename=>$filename, message_age=>$message_age, app=>$app, severity=>$severity })

=cut

sub message_age_check {
	my ($arg_ref) = @_;
	
	my $alert_key   = _no_blanks_allowed($arg_ref->{'key'});
	my $app         = _no_blanks_allowed($arg_ref->{'app'});
	my $prefix      = _no_blanks_allowed($arg_ref->{'prefix'});
	my $message_age = $arg_ref->{'message_age'};
	my $sev         = $arg_ref->{'severity'};
	
	my $now = time;
    
	my $message_age_check = 1;  # this is set to 0 if message age is greater than the time passed;

	
	# Here's what the key in the 'alert sent log file' looks like:
	#  esm_00000:.var.opt.OV.conf.ssm_logfiles.dat:warning
	
	my $transformed_key =  $alert_key;
	   $transformed_key =~ tr/\/\\\:/.._/;  # sub back slashes and colons for periods

	my $key = "$app:$transformed_key:$sev";

	#my $message_age_stat_file_base =  $filename;
	#   $message_age_stat_file_base =~ tr/\/\\\:/.._/;  # sub back slashes and colons for periods
	#   $message_age_stat_file_base =  "fileage_${app}.${message_age_stat_file_base}";
	
	#my @returned_times = get_all_alert_times({ key=>$message_age_stat_file_base, prefix=>$prefix });
	
	my $last_alert_time = get_last_alert_time({ key=>$key, prefix=>$prefix });
	
	if ($last_alert_time ) {
		my $last_alert_time_min              = int ($last_alert_time / 60);
		
		my $time_passed_since_last_alert     = ($now - $last_alert_time);
		my $time_since_monitor_run           = time_passed_since_run({ prefix=>$prefix });
	
		   $time_passed_since_last_alert     = $time_passed_since_last_alert  + $time_since_monitor_run;
		   
		my $time_passed_since_last_alert_min = int ($time_passed_since_last_alert / 60);
	
		if ( ($last_alert_time_min < $message_age) and ($time_passed_since_last_alert_min < $message_age) ) {
			$message_age_check = 0;
		}
	}
	
	return ($message_age_check);
	
}

sub start_time_check {
	my ($arg_ref) = @_;
	
	my $start  = $arg_ref->{'start'};
	my $prefix = $arg_ref->{'prefix'};
	
	my $ran_time  = time_of_run({ prefix=>$prefix, want_hash=>1 });
	
    my $tm        = localtime($ran_time->{'mtime'});
    my $hour      = $tm->hour;
	
	if ($hour >= $start) {
		return 1;
	}
	else {
		return 0;
	}
	
}

sub stop_time_check {
	my ($arg_ref) = @_;
	
	my $stop   = $arg_ref->{'stop'};
	my $prefix = $arg_ref->{'prefix'};
	
    my $log_file_loc = get_logfile_location($prefix);

	my $ran_time  = time_of_run({ prefix=>$prefix, want_hash=>1 });
	
    my $tm        = localtime($ran_time->{'mtime'});
    my $hour      = $tm->hour;
	
	if ($hour < $stop) {
		return 1;
	}
	else {
		return 0;
	}
}

sub dayofweek_check {
	my ($arg_ref) = @_;
	
	my $dayofweek = $arg_ref->{'dayofweek'};
	my $prefix    = $arg_ref->{'prefix'};

	my ($tday);
	
	my $ran_time  = time_of_run({ prefix=>$prefix, want_hash=>1 });
	
    my $tm        = localtime($ran_time->{'mtime'});
    my $day       = $tm->wday;
	
	$tday         = return_day_of_week($day);
	
	my $dow_found = index $dayofweek, $tday;
	
	if ($dow_found >= 0) {
		return 1;
	}
	else {
		return 0;
	}
}

sub return_day_of_week {
	my ($day) = @_;
	my ($tday);
	# Establish day
	if ($day == 0) {
		$tday = "sun";
	}
	elsif ($day == 1) {
		$tday = "mon";
		
	}
	elsif ($day == 2) {
		$tday = "tue";
		
	}
	elsif ($day == 3) {
		$tday = "wed";
		
	}
	elsif ($day == 4) {
		$tday = "thu";
		
	}
	elsif ($day == 5) {
		$tday = "fri";
		
	}
	elsif ($day == 6) {
		$tday = "sat";
		
	}
	
	return $tday;
}

sub description_check {
	my ($description, $entry);
	
	if (not $entry) {
		return 1;
	}
	
	if (grep $description, @{$entry}) {
		return 1;
	}
	else {
		return 0;
	}
}

sub time_passed_since_run {
	my ($arg_ref) = @_;
    
    my $prefix = $arg_ref->{'prefix'};
    my $file   = $arg_ref->{'file'};
    
    if ( (not $prefix) and (not $file) ) {
        croak "Incorrect parameters set in time_passed_since_run!";
    }
	
    if (not $file) {
        $file = get_logfile_location($prefix);
    }
    
	my $run_time = time_of_run({ file=>$file, want_hash=>1, prefix=>$prefix });
	
	my $now = time;
	
	my $passed = int ($now - $run_time->{'mtime'});
	
	return $passed;
	
}

sub get_logfile_location {
	my ($prefix) = shift;
    my $ssm_vars = ssm_variables();
    my $SSM_LOGS = $ssm_vars->{'SSM_LOGS'};
	
	return "$SSM_LOGS/ssm-test-${prefix}.log";
	
}

sub time_of_run {
	my ($arg_ref) = @_;
    
    my $prefix    = $arg_ref->{'prefix'};
    my $file      = $arg_ref->{'file'};
    my $want_hash = $arg_ref->{'want_hash'};
    
    if ( (not $prefix) and (not $file) ) {
        croak "Incorrect parameters set in time_passed_since_run!";
    }
	
    if (not $file) {
        $file = get_logfile_location($prefix);
    }
	
	if ($want_hash) {
		my $file_hash = get_file_stats({ file=>$file, want_hash=>1 });
		return $file_hash;
	}
	else {
		my (@file_array) = get_file_stats({ file=>$file });
		return (@file_array);
	}

}

sub get_file_stats {
	my ($arg_ref) = @_;
	
	my $file      = _no_blanks_allowed($arg_ref->{'file'});
	my $want_hash = $arg_ref->{'want_hash'};
	my ($time_hash);
	
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev,
		$size, $atime, $mtime, $ctime, $blksize, $blocks)
	= stat "$file";

	if ($want_hash) {
		$time_hash = {
			'dev'     => $dev,
			'ino'     => $ino,
			'mode'    => $mode,
			'nlink'   => $nlink,
			'uid'     => $uid,
			'gid'     => $gid,
			'rdev'    => $rdev,
			'size'    => $size,
			'atime'   => $atime,
			'mtime'   => $mtime,
			'ctime'   => $ctime,
			'blksize' => $blksize,
			'blocks'  => $blocks,
		};
		
		return $time_hash;
	}
	else {
		return ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev,
		$size, $atime, $mtime, $ctime, $blksize, $blocks);
	}
}
###############################################################################
### End of Public Methods / Functions #########################################
###############################################################################


###############################################################################
### Private Methods / Functions ###############################################
###############################################################################

sub _no_blanks_allowed {
	my ($incoming) = @_;
	
	if (not $incoming) {
		croak "No blanks allowed here!";
	}
	
	return $incoming;
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

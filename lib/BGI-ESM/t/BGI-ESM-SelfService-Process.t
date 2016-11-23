
=head1 NAME

Test module for BGI ESM Common Debug methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::SelfService::Diskspace

=head1 REVISIONS

CVS Revsion: $Revision: 1.2 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-12-15   nichj   Developing
  #  2005-12-15   nichj   Finsished for Windows
  #
  #####################################################################

=head1 TODO

- Write tests for the following:
	
=cut

#########################

use warnings;
use strict;
use Data::Dumper;
use Carp;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared qw(os_type);

my @subs = qw(
	ssm_get_process_list
	ssm_is_process_running
	ssm_process_running_count
	ssm_process_running_time
);

BEGIN { use_ok('BGI::ESM::SelfService::Process', @subs); };

#########################

can_ok( __PACKAGE__, 'ssm_get_process_list');
can_ok( __PACKAGE__, 'ssm_is_process_running');
can_ok( __PACKAGE__, 'ssm_process_running_count');
can_ok( __PACKAGE__, 'ssm_process_running_time');


#########################
#########################

my ($process_to_check, $service_to_check);

if (os_type() eq 'WINDOWS') {
	$process_to_check = "explorer.exe";
	$service_to_check = "";
}
else {
	$process_to_check = "explorer.exe";
	$service_to_check = "";
}

print "\n\nGet Process List\n\n";

my $process_list = ssm_get_process_list();

print Dumper $process_list;

print "\n\nIs Process Running\n\n";

print "Searching for $process_to_check without passed process list\n\n";

my $status = ssm_is_process_running({ process=>$process_to_check });

is ($status, 1, 'ssm_is_process_running( ) should return 1 if running. Note: without process_list passed: ' . $status);

$status = ssm_is_process_running({ process=>$process_to_check, process_list=>$process_list });

is ($status, 1, 'ssm_is_process_running( ) should return 1 if running. Note: with process_list passed: ' . $status);

print "\n\nNumber of processes running\n\n";

my $process_count = ssm_process_running_count({ process=>$process_to_check });

cmp_ok($process_count, 'gt', 0,
	   'ssm_process_running_count( ) should return the number of running processes for ' . $process_to_check . '. Note: no process_list passed. ' . $process_count);

$process_count = ssm_process_running_count({ process=>$process_to_check, process_list=>$process_list });

cmp_ok($process_count, 'gt', 0,
	   'ssm_process_running_count( ) should return the number of running processes for ' . $process_to_check . '. Note: process_list passed. ' . $process_count);


print "\n\nProcess Run Time\n\n";

my $process_run_time = ssm_process_running_time({ process=>$process_to_check, process_list=>$process_list });

cmp_ok($process_run_time, 'gt', 0,
	   'ssm_process_running_time( ) should return the amount of time the process ' . $process_to_check . ' has been running: ' . $process_run_time);

print "\n\nProcess Run Time with time formats\n\n";
my @time_formats = qw(epoch minute hour day bad);

foreach my $time_format (@time_formats) {
	
	print "\n\nprocess time check with time format of $time_format\n\n";
	
	my $process_run_time = ssm_process_running_time({ process=>$process_to_check, process_list=>$process_list, time_format=>$time_format });
	
	cmp_ok($process_run_time, 'gt', 0,
		   'ssm_process_running_time( ) should return the amount of time the process ' . $process_to_check . ' has been running with a format of '
		   . $time_format . ': ' . $process_run_time);
	
}


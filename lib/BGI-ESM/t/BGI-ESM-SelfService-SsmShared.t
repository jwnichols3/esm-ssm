
=head1 NAME

Test module for BGI ESM SelfService Common module

=head1 SYNOPSIS

This is test suite for BGI::ESM::SelfService::Common

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.2 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-12-06   nichj   Starting
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
use Getopt::Long;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared;

my @subs = qw(
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

BEGIN { use_ok('BGI::ESM::SelfService::SsmShared', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'ssm_program_versions');
can_ok( __PACKAGE__, 'ssm_log_when_alert');
can_ok( __PACKAGE__, 'ssm_transpose_file_name');
can_ok( __PACKAGE__, 'get_when_alert_log_file');
can_ok( __PACKAGE__, 'search_when_alert_log_file');
can_ok( __PACKAGE__, 'clear_when_alert_log_file');
can_ok( __PACKAGE__, 'get_time_passed_between_last_alerts');
can_ok( __PACKAGE__, 'get_last_alert_time');
can_ok( __PACKAGE__, 'get_time_since_last_alert');
can_ok( __PACKAGE__, 'get_all_alert_times');

#####################################
## pre-processing set up ############
#####################################
our ($opt_no_version,);

# =============================================================================
# Get Command Line Options
# =============================================================================
our ($opt_notdry);
GetOptions(
            "no_version",
			
          );


PREPROCESS:
{
    my $retval;
}

our $ssm_prefix = "test_monitor";
our @keys       = qw(
		APP:ESM:FILE:SEV
		APP2:c_esm2.major.25525
		STATIC_KEY
	);

my @sleep_times = qw(2 5 10 12 1);

#####################################
#####################################
SSM_LOG_WHEN_ALERT:
{
	print "\nssm_log_when_alert\n";
	
	my @repeats    = qw(1 2 3);
	my $repeat_count = 0;
	
	foreach my $time_to_run (@repeats) {
		
		
		print "\n\nLooped $time_to_run through\n\n";
		
		foreach my $key (@keys) {
			print "\nKey:    $key\n";
			print "Prefix: $ssm_prefix\n";
			
			my $log_when_status = ssm_log_when_alert({ key=>$key, prefix=>$ssm_prefix });
			
			is ($log_when_status, 1,
				'ssm_log_when_alert({ key=>$key, prefix=>$ssm_prefix }) should return 1 if successful: ' . $log_when_status);
		
			my $search_results = search_when_alert_log_file({ prefix=>$ssm_prefix, search=>$key });
			
			cmp_ok ($search_results, "gt", 0,
				'search_when_alert_log_file({ prefix=>$ssm_prefix, search=>$key }) should return the number of found records in scalar context: ' . $search_results);
			
			my @search_results = search_when_alert_log_file({ prefix=>$ssm_prefix, search=>$key });
			my $result_matches = @search_results;
			
			cmp_ok ($result_matches, "gt", 0,
					'search_when_alert_log_file({ prefix=>$ssm_prefix, search=>$key }) should return a list of found records in list context: ' . $search_results);
	
			print "\n";
	
			print "Search Results:\n";
			print Dumper \@search_results;
	
			print "\n";
		}
		
		print "Sleeping " . $sleep_times[$repeat_count] . "...\n";
		sleep $sleep_times[$repeat_count];

		$repeat_count++;
		
	}
	print "\nget_when_alert_log_file\n";
	
	my $when_log_alert_file = get_when_alert_log_file({ prefix=>$ssm_prefix });

	my @log_when_contents = read_file_contents($when_log_alert_file);
	
	print "\nContents of when alert file $when_log_alert_file\n";
	
	print Dumper \@log_when_contents;
	
}

#####################################
#####################################
GET_TIME_PASSED:
{
	print "\n\nGet Time Passed Between Alerts\n\n";
	my $fudge_factor_seconds = 1;
	my $fudge_factor_minutes = .01;
	
	my @time_formats       = qw(seconds minutes);
	my $sleep_time_index   = @sleep_times - 2;
	my $sleep_time_compare_seconds = $sleep_times[$sleep_time_index]      + $fudge_factor_seconds;
	my $sleep_time_compare_minutes = ($sleep_times[$sleep_time_index]/60) + $fudge_factor_minutes;
	$sleep_time_compare_minutes    = sprintf "%.2f", $sleep_time_compare_minutes;
	
	foreach my $time_format (@time_formats) {
		foreach my $key (@keys) {
			my $time_passed = get_time_passed_between_last_alerts({ prefix=>$ssm_prefix, key=>$key, format=>$time_format });
			#print "\nTime passed: $time_passed $time_format\n";
			
			if ($time_format eq 'seconds') {
				cmp_ok($time_passed, "<=", ($sleep_time_compare_seconds), 
					   'time_passed_between_alerts( ) should return the number of seconds between alerts (with fudge factor): '
					   . $time_passed . ' against ' . $sleep_time_compare_seconds);
			}
			else {
				cmp_ok($time_passed, "<=", ($sleep_time_compare_minutes), 
					   'time_passed_between_alerts( ) should return the number of minutes between alerts (with fudge factor): '
					   . $time_passed . ' against ' . $sleep_time_compare_minutes);
			}
		}
	}
}

#####################################
#####################################
GET_LAST_MESSAGE_TIME:
{
	print "\n\nget_last_alert_time\n\n";
	my @time_formats = qw(seconds minutes);
	my $sleep_time = 3;
	
	foreach my $key (@keys) {
		my $returned_time = get_last_alert_time({ key=>$key, prefix=>$ssm_prefix });
		cmp_ok($returned_time, ">", 0,
			   'get_last_alert_time( ) should return the time of the last alert: ' . $returned_time);
	}

	print "Sleeping $sleep_time...\n";
	sleep $sleep_time;
	
	print "\n\nget_time_since_last_alert\n\n";

	foreach my $time_format (@time_formats) {
		foreach my $key (@keys) {
			my $returned_time = get_time_since_last_alert({ key=>$key, prefix=>$ssm_prefix, format=>$time_format });
			cmp_ok($returned_time, ">=", 0,
				   'get_time_since_last_alert( ) should return the time since the last alert: ' . $returned_time);
		}
	}
	
	print "\n\nget_all_alert_times\n\n";

	foreach my $key (@keys) {
		my @returned_times = get_all_alert_times({ key=>$key, prefix=>$ssm_prefix });
		my $num_returned_times = @returned_times;
		cmp_ok($num_returned_times, ">", 0,
			   'get_all_alert_times( ) should return a list of alert times: ');

		print "\nReturned times:\n";
		print Dumper \@returned_times;
		print "\n";
	}
	
}

#####################################
#####################################
SSM_TRANSPOSE_FILE_NAME:
{
	print "\nssm_transpose_file_name\n";
	
	my @pre_fns = qw(
		'c:/usr/ov/bin/OpC/cmds'
		'e:\\bgi\\apps\\orbis\\'
		'/var/opt/OV/bin/OpC/cmds'
	);

	foreach my $file_to_trans (@pre_fns) {
		
		my $expected = $file_to_trans;
		$expected    =~ tr/\/\\\:/.._/;
		my $got      = ssm_transpose_file_name($file_to_trans);
		
		is ($expected, $got,
			'ssm_transpose_file_name(' . $file_to_trans . ') should return transposed value: ' . $got);
		
	}
	
}

#####################################
#####################################
CLEAR_WHEN_ALERT_FILE:
{
	my $status = clear_when_alert_log_file({ prefix=>$ssm_prefix });
	
	is ($status, 1, 'clear_when_alert_log_file({ prefix=>$prefix }) will return 1 if file successfully cleared.');
	
	my $file_to_check = get_when_alert_log_file({ prefix=>$ssm_prefix });
	
	my @file_contents = read_file_contents($file_to_check);
	
	@file_contents = strip_comments_from_array(@file_contents);
	
	my $number_of_lines = @file_contents;
	
	is ($number_of_lines, 0, 'Validating clear_when_alert_log_file( ) worked.');
}



#####################################
#####################################
if (not $opt_no_version) {
	SSM_PROGRAM_VERSIONS:
	{
		print "\nssm_program_versions\n";
		my $output = ssm_program_versions();
		
		print Dumper $output;
		
		is ($output, $output, 'ssm_program_versions( ) should return a list of all program versions');
	}
}
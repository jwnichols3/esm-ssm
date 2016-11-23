#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME

Test module for BGI ESM Common Shared Methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::Shared

=head1 REVISIONS

CVS Revsion: $Revision: 1.31 $
    Date:    $Date: 2005/11/29 17:40:38 $
    
    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2005-mm-dd   nichj   Developing release 1
    #  2005-09-07   nichj   Split network functions into BGI::ESM::Common::Network
    #  2005-09-09   nichj   Added copy_file testing.
    #  2005-09-12   nichj   Added remove_file testing.
    #  2005-09-22   nichj   Added get_hostname testing
    #                        added ftp_file, but not testing
    #  2005-10-11   nichj   Added testing for get_display_date and get_common_shared_version
    #  2005-11-14   nichj   Added print_array
    #  2005-10-20   nichj   Added print_hash_formatted(_file)
    #  2005-10-26   nichj   Added tests for test_output_header, footer, and process_vposend_lf
    #  2005-10-27   nichj   Added Linux Logic
	#  2005-11-16   nichj   Added chk_running, nfs_error
    #  2005-11-28   nichj   Cross referenced what is done and what needs test code added (see can_ok section)
    #####################################################################

=head1 TODO
	
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

my @subs = qw(
	chk_running
	check_os
	copy_file
	dir_listing
	file_modified_younger
	flip_slashes_to_back
	flip_slashes_to_single_back
	ftp_file
	get_common_shared_version
	get_check_date
	get_display_date
	get_hostname
	get_process_list
   	get_test_output_log
	is_process_running
	kill_process
	lc_array
	mail_alert
	matching_entries_in_arrays
	mount_share
    move_file
	nfs_error
	nonmatching_entries_in_arrays
	os_type
	perlpass_get
	print_array
	print_array_file
	print_hash_formatted
	print_hash_formatted_file
	process_count_running
    process_vposend_lf
	read_file_contents
	remove_array_from_array
	remove_file
	say
	source_host_check
	strip_comments_from_array
	test_check
    test_output_header
    test_output_footer
	trim
	unique_list_elements
	write_file_contents
 );

BEGIN { use_ok('BGI::ESM::Common::Shared', @subs); };

#########################

can_ok( __PACKAGE__, 'chk_running'                  ); # done
can_ok( __PACKAGE__, 'check_os'                     ); # done
can_ok( __PACKAGE__, 'copy_file'                    ); # done
can_ok( __PACKAGE__, 'dir_listing'                  ); # done
can_ok( __PACKAGE__, 'ftp_file'                     );
can_ok( __PACKAGE__, 'flip_slashes_to_back'         ); # done
can_ok( __PACKAGE__, 'flip_slashes_to_single_back'  ); # done
can_ok( __PACKAGE__, 'get_common_shared_version'    ); # done
can_ok( __PACKAGE__, 'get_check_date'               ); # done
can_ok( __PACKAGE__, 'get_display_date'             ); # done
can_ok( __PACKAGE__, 'get_hostname'                 ); # done
can_ok( __PACKAGE__, 'get_process_list'             ); # done
can_ok( __PACKAGE__, 'get_test_output_log'          );
can_ok( __PACKAGE__, 'is_process_running'           ); # done, but might need refinement
can_ok( __PACKAGE__, 'mail_alert'                   ); # done
can_ok( __PACKAGE__, 'matching_entries_in_arrays'   );
can_ok( __PACKAGE__, 'move_file'                    ); # done
can_ok( __PACKAGE__, 'nfs_error'                    ); # done
can_ok( __PACKAGE__, 'nonmatching_entries_in_arrays'); 
can_ok( __PACKAGE__, 'os_type'                      ); # done
can_ok( __PACKAGE__, 'perlpass_get'                 ); # done
can_ok( __PACKAGE__, 'print_array'                  );
can_ok( __PACKAGE__, 'print_array_file'             );
can_ok( __PACKAGE__, 'print_hash_formatted'         );
can_ok( __PACKAGE__, 'print_hash_formatted_file'    );
can_ok( __PACKAGE__, 'process_count_running'        ); # done, but might need refinement
can_ok( __PACKAGE__, 'process_vposend_lf'           ); # done
can_ok( __PACKAGE__, 'read_file_contents'           ); # done
can_ok( __PACKAGE__, 'remove_file'                  ); # done
can_ok( __PACKAGE__, 'say'                          );
can_ok( __PACKAGE__, 'source_host_check'            ); # done
can_ok( __PACKAGE__, 'strip_comments_from_array'    ); # done
can_ok( __PACKAGE__, 'test_check'                   ); # done
can_ok( __PACKAGE__, 'test_output_header'           ); # done
can_ok( __PACKAGE__, 'test_output_footer'           ); # done
can_ok( __PACKAGE__, 'trim'                         ); # done
can_ok( __PACKAGE__, 'unique_list_elements'         ); # done
can_ok( __PACKAGE__, 'write_file_contents'          ); # done

####################################
## os_type #########################
my ($os, $chk_os);

if ($^O eq "MSWin32") {
	$os = "WINDOWS";
}
elsif ( lc $^O eq "linux" ) {
    $os = "LINUX";
}
else {
	$os = "UNIX";
}

our $chk_os = os_type();

our $agent_vars = agent_variables();
our $ssm_vars   = ssm_variables();

is ($os, $chk_os, 'os_type( ) should return WINDOWS, LINUX or UNIX.');

#####################################
## check_os #########################
CHECK_OS:
{
	print "\nCheck OS\n";
	my $os_got     = check_os();
	my $current_os = os_type();
	is ($os_got, $current_os, 'check_os( ) should return the current os if nothing is passed.');
	
	my $os_expected = 'WINDOWS';
	   $os_got      = check_os($os_expected);
	
	is ($os_got, $os_expected, 'check_os( $os ) should return the value specified in $os if a value is passed');
}
####################################
## trim ############################
TRIM:
{
	my $chk_trim = "this is the value";
	my $trim_var = "  this is the value  ";
	my $trimmed  = trim($trim_var);
	
	is ($trimmed, $chk_trim, 'trim( ) should return a value without trailing and leading spaces');
	
	my @chk_trim_array = ("this is the value 001", "this is the value 002", "this is the value 003");
	my @trim_var_array = ("   this is the value 001   ", "  this is the value 002  ", " this is the value 003 ");
	my @trimmed_array  = trim(@trim_var_array);
	
	is (@trimmed_array, @chk_trim_array, 'trim( ) should return an array whose elements do not have trailing and leading spaces');
}
####################################
## say #############################
SAY:
{
	print "\nSAY\n";
	my $line_to_print   = "This is the line to print";
	
	my $expected_output = $line_to_print . "\n";
	
	say($line_to_print);
	
	#is ($expected_output, $returned_output, 'say( ) prints text plus newline.');
}

####################################
## perlpass_get ####################
PERLPASS_GET:
{
	my $user = "zzito";
	
	my $test_user = perlpass_get('fileageuser');
	
	is ($test_user, $user, 'perlpass_get( ) should return a corresponding value');
}

#############################################################
### These tests are intermingled ###########################
FILE_TESTS:
{
	###################################
	## write_file_contents ############
	my $append     = time;
	my $write_file = "temp" . $append . ".txt";
	my (@write_text, @expected);
		
	$write_text[0] = "Write this to a file";
	$write_text[1] = "# Commented line 001";
	$write_text[2] = "; Commented line 002";
	$write_text[3] = "' Commented line 003";
		
	$expected[0] = "Write this to a file\n";
	$expected[1] = "# Commented line 001\n";
	$expected[2] = "; Commented line 002\n";
	$expected[3] = "' Commented line 003\n";
	
	my $write_method = "replace";
	my $status       = write_file_contents($write_file, \@write_text, $write_method);
	is ( $status, 1, 'write_file_contents( ) should return TRUE (1) if successful');
	
	my @file_contents = read_file_contents($write_file);
	
	is_deeply ( \@file_contents, \@expected, 'write_file_contents( ) replace');
	
	$write_method = "append";
	$status       = write_file_contents($write_file, \@write_text, $write_method);
	is ( $status, 1, 'write_file_contents( ) should return TRUE (1) if successful');
	
	@file_contents = read_file_contents($write_file);
	@expected      = (@expected, @expected);
	is_deeply ( \@file_contents, \@expected, 'write_file_contents( ) append');
	 
	##################################
	## read_file_contents ############
	
	my @file_contents_test = read_file_contents($write_file);
	
	is_deeply( \@file_contents_test, \@expected, 'read_file_contents( )');
	
	## Strip comments from array
	@expected    = ();
	$expected[0] = "Write this to a file";
	$expected[1] = "Write this to a file";
	
	my @stripped_array = strip_comments_from_array(@file_contents_test);
	is_deeply ( \@stripped_array, \@expected, 'strip_comments_from_array( ) should return an array without commented lines.');
	
	##################################
	## Clean up temp files
	unlink $write_file;
}
### end of intermingled tests ###############################
#############################################################

###################################
## get_process_list ###############
GET_PROCESS_LIST:
{
	my $process_list = get_process_list();
	#print "Process list results:\n";
	#print Dumper ($process_list);
	
	my $process_list_file = $ssm_vars->{'SSM_LOGS'} . "/process_list";
	my @process_list_file_contents = read_file_contents($process_list_file);
	chomp (@process_list_file_contents);
	
	is_deeply ($process_list, \@process_list_file_contents, 'get_process_list( ) populates the process_list file');
}
####################################
## is_process_running ###########
PROCESS_METHODS:
{
	my ($process_search);
	
	if ($os eq 'WINDOWS') {
		$process_search = "explorer.exe";
	}
    elsif ($os eq 'LINUX') {
        $process_search = "sshd";
    }
	else {
		$process_search = "sshd";
	}
	
	my $process_search_status = is_process_running($process_search);
	
	is ($process_search_status, 1, 'is_process_running( ) should return 1 if process ' . $process_search . ' is running');

	#####################################
	## process_count_running ############
	
	my $running_count = process_count_running($process_search);
	
	print "\nnumber of processes running: " . $running_count . "\n";
	
	is ($running_count, $running_count,
		'process_count_running( $process ) should return the number of processes running: ' .
		$process_search . ' has ' . $running_count . ' processes running.');

}
#####################################
## unique_list_elements #############
UNIQUE_LIST_ELEMENTS:

my @unique_list_to_test  = qw/one two three one two three 1 2 3 1 2 3/;
my @unique_list_expected = qw/one two three 1 2 3/;

my $unique_list_got      = unique_list_elements(@unique_list_to_test);

is_deeply($unique_list_got, \@unique_list_expected, 'unique_list_elements( ) should return a unique list of elements from a list');

#####################################
## copy_file ########################
COPY_FILE:

my $tmpext = time;
my $file_from = "copytest_from_" . $tmpext . ".txt";
my $file_to   = "copytest__to__" . $tmpext . ".txt";

print "\nTesting successful copy\n";
open my $COPYFILE, ">", "$file_from" or croak "Unable to open $file_from: $!\n";
print $COPYFILE "Adding information to this file at " . time . "\n";
close $COPYFILE or croak "Unable to close $file_from: $!\n";

my $copy_file_status_01 = copy_file($file_from, $file_to);
is ($copy_file_status_01, 1, 'copy_file($from, $to) will return 1 if successful');

my $file_from_bad = "copytest_from_" . $tmpext . "_bad.tmp";
my $copy_file_status_02 = copy_file($file_from_bad, $file_to);
print "\nTesting unsuccessful copy\n";
is ($copy_file_status_02, 0, 'copy_file($from, $to) will return 0 if unsuccessful');

####################################
## remove_file #####################
print "\n\nTesting remove_file";

print "Testing bad remove\n";
my $remove_status_expected = 0;
my $remove_status_got      = remove_file($file_from_bad);

is ($remove_status_got, $remove_status_expected, 'remove_file( $file_name ) should return 0 if the file does not exist.');

print "Testing good remove #01\n";
$remove_status_expected = 1;
$remove_status_got      = remove_file($file_from);

is ($remove_status_got, $remove_status_expected, 'remove_file( $file_name ) should return 1 if the file is removed.');

print "Testing good remove #02\n";
$remove_status_expected = 1;
$remove_status_got      = remove_file($file_to);

is ($remove_status_got, $remove_status_expected, 'remove_file( $file_name ) should return 1 if the file is removed.');

my $file_exists;

if (-e $file_from) {
	$file_exists = 1;
}
else {
	$file_exists = 0;
}

is ($file_exists, 0, 'Validating remove_file actually removed the file ' . $file_from);

if (-e $file_to) {
	$file_exists = 1;
}
else {
  $file_exists = 0;
}

is ($file_exists, 0, 'Validating remove_file actually removed the file ' . $file_to);

####################################
## Test Check ######################
TEST_CHECK:

print "\nTest Check\n";

my $num_bit_masks            = 2;

#  If we know how many true/false attributes there are, we know how many combinations to test for
my $num_possible_combinations = 2**$num_bit_masks;


#  Set up the array of bitmasks
my (@bitmasks, $bitmasks, $counter);
for ( $counter = 0; $counter < $num_bit_masks; $counter++ )
{
    $bitmasks[$counter] = 2**$counter;
}

################################################################################
#  Iterate through each possible combination
#  Works because each combination can be translated into a bit-string. Examples:
#
#  (combination_id = bit-string)
#      0 = 00000
#      1 = 00001
#      2 = 00010
#      3 = 00011
#      ...etc...
################################################################################
my	(
		$combination_id, $c, $value, $printbits,
		$test_expected,
		$test_flag,
		$t_flag,
		$test_returned,
		$test_text
    );

for ( $combination_id = 0; $combination_id < $num_possible_combinations; $combination_id++ )
{

	# set everything back to 0
	$test_expected = 0;
	
	$test_flag     = 0;
	$t_flag        = 0;
    
	# do the bitwise test and set each round to true or false
	my $test_one   = $combination_id & $bitmasks[0];
	my $test_two   = $combination_id & $bitmasks[1];
	
	# Set up the test based on the bitwise test.  ONLY SET FOR THAT TEST
	if ($test_one) {
		$test_flag     = 1;
		$test_expected = 1;
	}
	
	if ($test_two) {
		$t_flag        = 1;
		$test_expected = 1;
	}

	# Run the fuction with the flags set
	($test_returned) = test_check($test_flag, $t_flag);

	# Print the plan summary
	$test_text = "test_check ( $test_flag, $t_flag ) " .
	                   ":: test_flag: $test_flag :: t_flag: $t_flag :: number $combination_id";
	print "$test_text\n";
	
	# Check against results
	is ($test_returned, $test_expected);

}

####################################
####################################
GET_HOSTNAME:
{
	my ($hostname_expected, $hostname_got);
	
	if (os_type() eq 'WINDOWS') {
		
		$hostname_expected = $ENV{'COMPUTERNAME'};
		
	}
    elsif (os_type() eq 'LINUX') {
        
		$hostname_expected = $ENV{'HOSTNAME'};
		
	}
	else {
		
		$hostname_expected = $ENV{'HOSTNAME'};
		
	}
	
	chomp ($hostname_expected);

	$hostname_got = get_hostname();
	
	is ($hostname_got, $hostname_expected, 'get_hostname( ) should return the hostname: ' . $hostname_got);
  
}

####################################
####################################
FTP_FILE:
{
	#TODO: Add logic around testing ftp_file
	my $file = "test.txt";
	my $ftp_dir = "";
	
}

####################################
####################################
MAIL_ALERT:
{
	
	my $from    = "alarm.point\@barclaysglobal.com";
	my $to      = "nichj\@barclaysglobal.com";
	my $cc      = "john.nichols\@barclaysglobal.com";
	my $subject = "Testing " . time . " please ignore - subject";
	my $body    = "Testing " . time . " please ignore - body";
	
	my $status = mail_alert($from, $to, $cc, $subject, $body);
	
	is ($status, 1, 'mail_alert( $from, $to, $cc, $subject, $body ) should return 1 if successful: ' . $status);
	
}

####################################
####################################
GET_DISPLAY_DATE:
{
	
	print "\n\nget_display_date\n";
	my $date_exp = localtime;
	my $date_got = get_display_date();
	
	is ($date_got, $date_exp, 'get_display_date( ) should return a display date independant of platform: ' . $date_got);
	
}

####################################
####################################
GET_CHECK_DATE:
{
	
	print "\n\nget_check_date\n";
	my ($chk_dw, $chk_mon, $chk_day, $chk_time, $chk_year)  = split(/ /,get_display_date());
	my $date_exp = "$chk_dw $chk_mon $chk_day";
	my $date_got = get_check_date();
	
	is ($date_got, $date_exp, 'get_check_date( ) should return a check date independant of platform: ' . $date_got);
	
}

####################################
####################################
GET_COMMON_SHARED_VERSION:
{
	
	print "\n\nget_common_shared_version()\n";
	my $common_shared_version = get_common_shared_version();
	
	is ($common_shared_version, $common_shared_version,
		'get_common_shared_version( ) should return the version of BGI::ESM::Common::Shared: ' . $common_shared_version);
	
}

####################################
####################################
DIR_LISTING:
{
	
	print "\n\ndir_listing() scalar\n";
	my ($ov_agent_dir, $ov_data_dir) = get_agent_dirs();
	my @dirs = ($ov_agent_dir, $ov_data_dir);
	
	print "\nDirectories to get listings\n";
	print Dumper \@dirs;
	
	foreach my $dir (@dirs) {
		print "\nDirectory listing for $dir\n";
		my $dirlist = dir_listing($dir);
		#print Dumper $dirlist;
		is_deeply ($dirlist, dir_listing($dir), 'dir_listing( $dir ) should return a reference to an array with files as elements.');
	}
	
	print "\n\ndir_listing() array\n";
	my $dirslist = dir_listing(@dirs);
	is_deeply ($dirslist, dir_listing(@dirs), 'dir_listing( @dirs ) should return a reference to an array with files as elements.');
	
	#print "\nDirectory listing for all agent dirs\n";
	#print Dumper $dirslist;
	
}

####################################
####################################
PRINT_ARRAY:
{
	
	my @a = qw(one two three_four five_six_seven);
	print_array(@a);
	
}
####################################
####################################
PRINT_ARRAY_FILE:
{
	
	my @a = qw(one two three_four five_six_seven);
	#print_array_file(@a);
	
}

####################################
####################################
PRINT_HASH_FORMATTED:
{
	
	my @a = qw(one two three_four five_six_seven);
	#print_array(@a);
	
}

####################################
####################################
PRINT_HASH_FORMATTED_FILE:
{
	
	my @a = qw(one two three_four five_six_seven);
	#print_array(@a);
	
}

####################################
####################################
# V V V V V V V V V V V V V V V V V 

TEST_OUTPUT_HEADER_FOOTER_PROCESS_VPOSEND:
{
    print "\n\nTEST OUTPUT HEADER\n";
    
	my ($prefix, $status, $file_chk);
    
	$prefix = "testing" . time;
    
    $status = test_output_header($prefix);
    
    is ($status, 1, 'test_output_header( $prefix ) should return 1 if successful.');
	#print_array(@a);
    
######################################
######################################

    print "\n\nPROCESS VPOSEND LF\n\n";
    
    my ($app, $message, $sev, $test);
    
    my @sevs  = qw(critical major minor warning normal);
    my @tests = (1, 0);
    
    $message = "Running this test at " . time . " on " . get_hostname();
    $app     = "esm_" . get_hostname() . "_" . time;
    
    foreach $sev (@sevs) {
        
        foreach $test (@tests) {
        
            my $vposend_msg = "app=$app message=$message sev=$sev type=qa";
            
            print "vposend_msg = $vposend_msg\n";
            print "\tTest: $test\n\n";
            
            process_vposend_lf($vposend_msg, $test, $prefix);
        
        }
        
    }
    
    print "\n\nTEST OUTPUT FOOTER\n";
    $status = test_output_footer($prefix);

    is ($status, 1, 'test_output_footer( $prefix ) should return 1 if successful.');
    
    my $test_output_log = get_test_output_log($prefix);
    
    print "\nThe test log file name is $test_output_log. ";

    if (-e $test_output_log) {
        print "It exists!\n";
        $file_chk = 1;
        
    }
    else {
        print "It DOES NOT EXIST! This is a problem";
        $file_chk = 0;
    }
    
    is ($file_chk, 1, 'The test_output_footer or header ( prefix ) should create a file.');

    my @file_contents = read_file_contents($test_output_log);
    chomp(@file_contents);
    
    print "\nThe file contents of the ssm test logfile: $test_output_log\n";
    
    print Dumper (\@file_contents);
    

    unlink ($test_output_log) or carp "Unable to delete $test_output_log: $!";
    
}

# ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
####################################
####################################

####################################
####################################
MOVE_FILE:
{
    print "\nMOVE FILE - replace\n";
    
    my $from_file = "temp" . time . "_from.tmp";
    my $to_file   = "temp" . time . "_to.tmp";

    my @file_contents = qw(one two three two_one two_two two_three);
    my @to_file_contents = qw(2_one 2_two 2_three 2_two_one 2_two_two 2_two_three);
    
    print "\n\tThe contents of the from file before the move:\n";
    my @file_contents_output = read_file_contents($from_file);
    print Dumper (\@file_contents_output);

    if (not -e $from_file) {
        my $status = write_file_contents($from_file, \@file_contents, 'replace');
    }
    
    if (not -e $to_file) {
        my $status = write_file_contents($to_file, \@to_file_contents, 'replace');
    }
    
    print "\n\tThe contents of the from file before the move:\n";
    @file_contents_output = read_file_contents($from_file);
    print Dumper (\@file_contents_output);

    my $move_status = move_file($from_file, $to_file, 'replace');
    
    is ($move_status, 1, 'move_file( ) with replace option should return 1 if successful.');

    print "\n\tThe contents of the to file after the move:\n";
    @file_contents_output = read_file_contents($to_file);
    print Dumper (\@file_contents_output);

    unlink "$to_file" or croak "Unable to remove $to_file: $!";
    
    ####################################

    print "\nMOVE FILE - no replace\n";
    
    if (not -e $from_file) {
        my $status = write_file_contents($from_file, \@file_contents, 'replace');
    }
    
    $move_status = move_file($from_file, $to_file);
    
    is ($move_status, 1, 'move_file( ) should return 1 if successful.');

    ####################################

    print "\nMOVE FILE - failed replace\n";
    
    if (not -e $from_file) {
        my $status = write_file_contents($from_file, \@file_contents, 'replace');
    }

    if (not -e $to_file) {
        my $status = write_file_contents($to_file, \@to_file_contents, 'replace');
    }

    $move_status = move_file($from_file, $to_file);
    
    is ($move_status, 0, 'move_file( ) should return 0 if to_file already exists.');

    unlink $from_file;
    unlink $to_file;
}

#####################################
#####################################
NFS_ERROR:
{
	print "\n\nNFS ERROR\n\n";
	is (nfs_error(), 0, 'nfs_error( ) should return 0 if there are not nfs errors');
	
}
#####################################
#####################################
CHK_RUNNING:
{
	print "\n\nCHK_RUNNING\n\n";
	is (chk_running("fileage"), 1, 'chk_running( ) should return 1 if okay to run.');
}

#####################################
#####################################
SOURCE_HOST_CHECK:
{
	my $host_bad  = "notvalid";
	my $host_good = get_hostname();
	
	my $bad_result  = source_host_check($host_bad);
	my $good_result = source_host_check($host_good);
	
	if (os_type() ne 'WINDOWS') {
		is ($bad_result,  0, 'source_host_check( not_host ) should return 0 if not the source host.');
	}
	else {
		print "\nsource_host_check will only return 1 on Windows systems.\n";
	}
	
	is ($good_result, 1, 'source_host_check(   host   ) should return 1 if not the source host.');

}	

#####################################
#####################################
FLIP_SLASHES:
{
	
	print "\n\nFLIP SLASHES\n\n";
	my ($dir_to_check, $dir_expected_single, $dir_expected);
	if (os_type() eq 'WINDOWS') {
		$dir_to_check        = 'c:/temp/dir1';
		$dir_expected_single = 'c:\temp\dir1';
		$dir_expected        = "c:\\\\temp\\\\dir1";
	}
	else {
		$dir_to_check        = '/tmp/dir1';
		$dir_expected_single = '/tmp/dir1';
		$dir_expected        = '/tmp/dir1';
	}
		
	my $returned_dir        = flip_slashes_to_back($dir_to_check);
	my $returned_dir_single = flip_slashes_to_single_back($dir_to_check);
	is ($dir_expected_single, $returned_dir_single,
			'flip_slashes_to_single_back( ) should return a transposed value (only on Windows): ' . $returned_dir_single);
	is ($dir_expected, $returned_dir,
			'flip_slashes_to_back( )        should return a transposed value (only on Windows): ' . $returned_dir);
}

#####################################
#####################################
## post-processing clean up #########
#####################################
#####################################



#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME

Test program for BGI::ESM::Common::Diff

=head1 SYNOPSIS

This program tests the methods found in BGI::ESM::Common::Diff

=head1 REVISIONS

CVS Revision: $Revision: 1.10 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-10-11   nichj   Developing release 1
  #  
  #####################################################################

=head1 TODO

	
=cut

##############################################################################
### Module Use Section #######################################################
use warnings;
use strict;
use Data::Dumper;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(write_file_contents);

##############################################################################
my @subs = qw(
	diff_files
	diff_added
	diff_removed
	diff_files_patch
	clean_diff_records
 );

BEGIN { use_ok('BGI::ESM::Common::Diff', @subs); };

##############################################################################

can_ok( __PACKAGE__, 'diff_files');
can_ok( __PACKAGE__, 'diff_added');
can_ok( __PACKAGE__, 'diff_removed');
can_ok( __PACKAGE__, 'diff_files_patch');
can_ok( __PACKAGE__, 'clean_diff_records');

###############################################################################
##### Load common methods and variables
###############################################################################


###############################################################################
##### Testing Section
###############################################################################

#########################
#########################
DIFF_FILES:
{
	print "\n\n=== DIFF FILES ===\n\n";
	my (
		$write_status, $diff_text_got,
		$diff_text_expected, $diff_added_got, $diff_rem_got,
		$diff_added_got_clean, $diff_rem_got_clean,
		);
	
	my (@diff_text_same, @diff_text_different, @diff_blank);
	my $tmpfile_a = time . "-diff_a.tmp";
	my $tmpfile_b = time . "-diff_b.tmp";
	
	#########################
	print "\tDiff Files that are the same\n";
	
	@diff_text_same      = ("line 1", "line 2", "line 3");
	@diff_text_different = ("line 1", "line 2", "line three", "line four", "line five");
	
	$write_status = write_file_contents($tmpfile_a, \@diff_text_same, 'replace');
	print "\n\tStatus of writing $tmpfile_a: $write_status\n";
	$write_status = write_file_contents($tmpfile_b, \@diff_text_same, 'replace');
	print "\n\tStatus of writing $tmpfile_b: $write_status\n";
	
	$diff_text_got = diff_files($tmpfile_a, $tmpfile_b);
	
	print Dumper $diff_text_got;
	
	#########################
	print "\n\t--- Diff Added   - Same ---\n\n";

    $diff_added_got       = diff_added($tmpfile_a, $tmpfile_b);
    $diff_added_got_clean = diff_added($tmpfile_a, $tmpfile_b, 'clean');
	
	print Dumper $diff_added_got;
	
	is_deeply ($diff_added_got, \@diff_blank,
		'diff_added( file_a, file_b ) should return blank array on files that are the same');
	
	#########################
	print "\n\t--- Diff Removed - Same ---\n\n";

	$diff_rem_got       = diff_removed($tmpfile_a, $tmpfile_b);
    $diff_rem_got_clean = diff_removed($tmpfile_a, $tmpfile_b, 'clean');

	is_deeply ($diff_rem_got, \@diff_blank,
		'diff_removed( file_a, file_b ) should return blank array on files that are the same');

	#########################
	print "\n\t--- Diff files that are different ---\n\n";
	$write_status = write_file_contents($tmpfile_b, \@diff_text_different, 'replace');
	print "\n\tStatus of writing $tmpfile_b: $write_status\n";

	$diff_text_got = diff_files($tmpfile_a, $tmpfile_b);
	print Dumper $diff_text_got;
	
	#########################
	print "\n\t--- Diff Added   - Different ---\n\n";

	$diff_added_got       = diff_added($tmpfile_a, $tmpfile_b);
    $diff_added_got_clean = diff_added($tmpfile_a, $tmpfile_b, 'clean');

	is_deeply ($diff_added_got, diff_added($tmpfile_a, $tmpfile_b),
		'diff_added( file_a, file_b ) should return array with added differences on files that are different');

	print "\nContents of added diff\n";
	print Dumper $diff_added_got;
	print "\nContents of added diff - clean option\n";
	print Dumper $diff_added_got_clean;

	#########################
	print "\n\t--- Diff Removed - Different ---\n\n";

	$diff_rem_got = diff_removed($tmpfile_a, $tmpfile_b);
    $diff_rem_got_clean = diff_removed($tmpfile_a, $tmpfile_b, 'clean');

	is_deeply ($diff_rem_got, diff_removed($tmpfile_a, $tmpfile_b),
		'diff_removed( file_a, file_b ) should return array with removed differences on files that are different');

	#########################
	print "\nContents of removed diff\n";
	print Dumper $diff_rem_got;
	print "\nContents of removed diff - clean option\n";
	print Dumper $diff_rem_got_clean;


	#########################
	unlink $tmpfile_a;
	unlink $tmpfile_b;
	
	#########################
	print "\n\n=== Record manipulation ===\n\n";
	my $clean_records_added   = clean_diff_records($diff_added_got);
	my $clean_records_removed = clean_diff_records($diff_rem_got);
	
	is_deeply($clean_records_added, $diff_added_got_clean,
			  'clean_diff_records( $diff_record ) should return a reference to an array with clean records');
	
	is_deeply($clean_records_removed, $diff_rem_got_clean,
			  'clean_diff_records( $diff_record ) should return a reference to an array with clean records');

	#########################
	print "--- Clean added records ---\n\n";
	print Dumper $clean_records_added;
	
	print "\n\n--- Clean removed records ---\n\n";
	print Dumper $clean_records_removed;
}

DIFF_FILES_PATCH:
{
	print "\n\n=== DIFF FILES PATCH ===\n\n";
	my ($write_status, $diff_text_got, $diff_text_expected, $diff_added_got, $diff_rem_got);
	my (@diff_text_same, @diff_text_different, @diff_blank);
	my $tmpfile_a = time . "-diff_a.tmp";
	my $tmpfile_b = time . "-diff_b.tmp";
	
	print "\t--- Diff Files that are the same ---\n\n";
	
	@diff_text_same      = ("line 1", "line 2", "line 3");
	@diff_text_different = ("line 1", "line 2", "line three", "line four", "line five");
	
	$write_status = write_file_contents($tmpfile_a, \@diff_text_same, 'replace');
	print "\n\tStatus of writing $tmpfile_a: $write_status\n";
	$write_status = write_file_contents($tmpfile_b, \@diff_text_same, 'replace');
	print "\n\tStatus of writing $tmpfile_b: $write_status\n";
	
	$diff_text_got = diff_files_patch($tmpfile_a, $tmpfile_b);
	
	print Dumper $diff_text_got;
	
	print "\n\t--- Diff files that are different ---\n\n";
	$write_status = write_file_contents($tmpfile_b, \@diff_text_different, 'replace');
	print "\n\tStatus of writing $tmpfile_b: $write_status\n";

	$diff_text_got = diff_files_patch($tmpfile_a, $tmpfile_b);
	print Dumper $diff_text_got;
	
	unlink $tmpfile_a;
	unlink $tmpfile_b;

}

###############################################################################
##### post-processing clean up 
###############################################################################



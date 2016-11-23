
=head1 NAME

Test module for BGI ESM Common Debug methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::Debug methods

=head1 REVISIONS

CVS Revsion: $Revision: 1.4 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-09-15   nichj   Developing release 1
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
	opt_debug_flag
	file_debug_flag
	get_debug
    get_debug_named
 );

BEGIN { use_ok('BGI::ESM::Common::Debug', @subs); };

#########################

can_ok( __PACKAGE__, 'opt_debug_flag'           );
can_ok( __PACKAGE__, 'file_debug_flag'          );
can_ok( __PACKAGE__, 'get_debug'                );
can_ok( __PACKAGE__, 'get_debug_named'          );

####################################
##  OPT_DEBUG_FLAG #################
print "\nOPT Debug Flag\n";

my ($debug_flag, $d_flag, $debug_extensive_flag);
my ($debug_returned, $debug_returned_d, $debug_extensive_returned);

print "\n\nDebug 1, D 1, Debug Extensive 1\n";

$debug_flag           = 1;
$d_flag               = 1;
$debug_extensive_flag = 1;

($debug_returned)           = opt_debug_flag($debug_flag);
($debug_returned_d)         = opt_debug_flag($d_flag);
($debug_extensive_returned) = opt_debug_flag($debug_extensive_flag);

is ($debug_returned, $debug_flag, 'opt_debug_flag( ) $debug should return 1 if $debug_flag is set or 0 if not.');
is ($debug_returned_d, $d_flag, 'opt_debug_flag( ) $debug should return 1 if $d_flag is set or 0 if not.');
is ($debug_extensive_returned, $debug_extensive_flag, 'opt_debug_flag( ) $debug_extensive should return 1 if $debug_extensive is set or 0 if not.');

print "\n\nDebug 0, D 1, Debug Extensive 1\n";

$debug_flag           = 0;
$d_flag               = 1;
$debug_extensive_flag = 1;

($debug_returned)           = opt_debug_flag($debug_flag);
($debug_returned_d)         = opt_debug_flag($d_flag);
($debug_extensive_returned) = opt_debug_flag($debug_extensive_flag);

is ($debug_returned, $debug_flag, 'opt_debug_flag( ) $debug should return 1 if $debug_flag is set or 0 if not.');
is ($debug_returned_d, $d_flag, 'opt_debug_flag( ) $debug should return 1 if $d_flag is set or 0 if not.');
is ($debug_extensive_returned, $debug_extensive_flag, 'opt_debug_flag( ) $debug_extensive should return 1 if $debug_extensive is set or 0 if not.');

print "\n\nDebug 0, D 0, Debug Extensive 1\n";

$debug_flag           = 0;
$d_flag               = 0;
$debug_extensive_flag = 1;

($debug_returned)           = opt_debug_flag($debug_flag);
($debug_returned_d)         = opt_debug_flag($d_flag);
($debug_extensive_returned) = opt_debug_flag($debug_extensive_flag);

is ($debug_returned, $debug_flag, 'opt_debug_flag( ) $debug should return 1 if $debug_flag is set or 0 if not.');
is ($debug_returned_d, $d_flag, 'opt_debug_flag( ) $debug should return 1 if $d_flag is set or 0 if not.');
is ($debug_extensive_returned, $debug_extensive_flag, 'opt_debug_flag( ) $debug_extensive should return 1 if $debug_extensive is set or 0 if not.');

print "\n\nDebug 0, D 0, Debug Extensive 0\n";

$debug_flag           = 0;
$d_flag               = 0;
$debug_extensive_flag = 0;

($debug_returned)           = opt_debug_flag($debug_flag);
($debug_returned_d)         = opt_debug_flag($d_flag);
($debug_extensive_returned) = opt_debug_flag($debug_extensive_flag);

is ($debug_returned, $debug_flag, 'opt_debug_flag( ) $debug should return 1 if $debug_flag is set or 0 if not.');
is ($debug_returned_d, $d_flag, 'opt_debug_flag( ) $debug should return 1 if $d_flag is set or 0 if not.');
is ($debug_extensive_returned, $debug_extensive_flag, 'opt_debug_flag( ) $debug_extensive should return 1 if $debug_extensive is set or 0 if not.');

print "\n\nDebug 1, D 0, Debug Extensive 0\n";

$debug_flag           = 1;
$d_flag               = 0;
$debug_extensive_flag = 0;

($debug_returned)           = opt_debug_flag($debug_flag);
($debug_returned_d)         = opt_debug_flag($d_flag);
($debug_extensive_returned) = opt_debug_flag($debug_extensive_flag);

is ($debug_returned, $debug_flag, 'opt_debug_flag( ) $debug should return 1 if $debug_flag is set or 0 if not.');
is ($debug_returned_d, $d_flag, 'opt_debug_flag( ) $debug should return 1 if $d_flag is set or 0 if not.');
is ($debug_extensive_returned, $debug_extensive_flag, 'opt_debug_flag( ) $debug_extensive should return 1 if $debug_extensive is set or 0 if not.');

print "\n\nDebug 0, D 1, Debug Extensive 0\n";

$debug_flag           = 0;
$d_flag               = 1;
$debug_extensive_flag = 0;

($debug_returned)           = opt_debug_flag($debug_flag);
($debug_returned_d)         = opt_debug_flag($d_flag);
($debug_extensive_returned) = opt_debug_flag($debug_extensive_flag);

is ($debug_returned, $debug_flag, 'opt_debug_flag( ) $debug should return 1 if $debug_flag is set or 0 if not.');
is ($debug_returned_d, $d_flag, 'opt_debug_flag( ) $debug should return 1 if $d_flag is set or 0 if not.');
is ($debug_extensive_returned, $debug_extensive_flag, 'opt_debug_flag( ) $debug_extensive should return 1 if $debug_extensive is set or 0 if not.');

print "\n\nDebug 1, D 1, Debug Extensive 0\n";

$debug_flag           = 1;
$d_flag               = 1;
$debug_extensive_flag = 0;

($debug_returned)           = opt_debug_flag($debug_flag);
($debug_returned_d)         = opt_debug_flag($d_flag);
($debug_extensive_returned) = opt_debug_flag($debug_extensive_flag);

is ($debug_returned, $debug_flag, 'opt_debug_flag( ) $debug should return 1 if $debug_flag is set or 0 if not.');
is ($debug_returned_d, $d_flag, 'opt_debug_flag( ) $debug should return 1 if $d_flag is set or 0 if not.');
is ($debug_extensive_returned, $debug_extensive_flag, 'opt_debug_flag( ) $debug_extensive should return 1 if $debug_extensive is set or 0 if not.');

####################################
##  FILE_DEBUG_FLAG ################
print "\n\nOPT Debug Flag\n";
my ($debug_file_flag, $debug_extensive_file_flag);
my $debug_filename           = "testdebug.txt";
my $debug_extensive_filename = "testdebugextensive.txt";

print "\nFILE: Debug 1, Debug Extensive: 1\n\n";
populate_file($debug_filename);
populate_file($debug_extensive_filename);

$debug_file_flag           = 1;
$debug_extensive_file_flag = 1;

($debug_returned)           = file_debug_flag($debug_filename);
($debug_extensive_returned) = file_debug_flag($debug_extensive_filename);

is ($debug_returned, $debug_file_flag, 'file_debug_flag( ) $debug should return 1 if the file debug or debug extensive files exist or 0 if it does not.');
is ($debug_extensive_returned,$debug_extensive_file_flag, 'file_debug_flag( ) $debug_extensive should return 1 if the debugextensive file exists or 0 if it does not.');

remove_file($debug_filename);
remove_file($debug_extensive_filename);

#-------------------------------------

print "\nFILE: Debug 0, Debug Extensive: 1\n\n";
remove_file($debug_filename);
populate_file($debug_extensive_filename);

$debug_file_flag           = 0;
$debug_extensive_file_flag = 1;

($debug_returned)           = file_debug_flag($debug_filename);
($debug_extensive_returned) = file_debug_flag($debug_extensive_filename);

is ($debug_returned, $debug_file_flag, 'file_debug_flag( ) $debug should return 1 if the file debug or debug extensive files exist or 0 if it does not.');
is ($debug_extensive_returned,$debug_extensive_file_flag, 'file_debug_flag( ) $debug_extensive should return 1 if the debugextensive file exists or 0 if it does not.');

remove_file($debug_extensive_filename);

#-------------------------------------

print "\nFILE: Debug 0, Debug Extensive: 0\n\n";
remove_file($debug_filename);
remove_file($debug_extensive_filename);

$debug_file_flag           = 0;
$debug_extensive_file_flag = 0;

($debug_returned)           = file_debug_flag($debug_filename);
($debug_extensive_returned) = file_debug_flag($debug_extensive_filename);

is ($debug_returned, $debug_file_flag, 'file_debug_flag( ) $debug should return 1 if the file debug or debug extensive files exist or 0 if it does not.');
is ($debug_extensive_returned,$debug_extensive_file_flag, 'file_debug_flag( ) $debug_extensive should return 1 if the debugextensive file exists or 0 if it does not.');

remove_file($debug_filename);
remove_file($debug_extensive_filename);

#-------------------------------------

print "\nFILE: Debug 1, Debug Extensive: 0\n\n";
populate_file($debug_filename);
remove_file($debug_extensive_filename);

$debug_file_flag           = 1;
$debug_extensive_file_flag = 0;

($debug_returned)           = file_debug_flag($debug_filename);
($debug_extensive_returned) = file_debug_flag($debug_extensive_filename);

is ($debug_returned, $debug_file_flag, 'file_debug_flag( ) $debug should return 1 if the file debug or debug extensive files exist or 0 if it does not.');
is ($debug_extensive_returned,$debug_extensive_file_flag, 'file_debug_flag( ) $debug_extensive should return 1 if the debugextensive file exists or 0 if it does not.');

remove_file($debug_filename);
remove_file($debug_extensive_filename);

#####################################
## get_debug ########################
print "\n\nGet Debug\n\n";
$debug_filename           = "testdebug.txt";
$debug_extensive_filename = "testdebugextensive.txt";
my $num_bit_masks            = 5;

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
my (
    $combination_id, $c, $value, $printbits,
	$debug_expected, $debug_extensive_expected,
	$test_debug_text,
	$d_file_disp, $de_file_disp,
   );

for ( $combination_id = 0; $combination_id < $num_possible_combinations; $combination_id++ )
{

	# set everything back to 0
	$debug_expected           = 0;
	$debug_extensive_expected = 0;
	
	$d_file_disp              = 0;  # used to display if debug file used
	$de_file_disp             = 0;  # used to display if debug extensive file used

	$debug_flag               = 0;
	$d_flag                   = 0;
	$debug_extensive_flag     = 0;
	remove_file($debug_filename);
	remove_file($debug_extensive_filename);
    
	# do the bitwise test and set each round to true or false
	my $test_one   = $combination_id & $bitmasks[0];
	my $test_two   = $combination_id & $bitmasks[1];
	my $test_three = $combination_id & $bitmasks[2];
	my $test_four  = $combination_id & $bitmasks[3];
	my $test_five  = $combination_id & $bitmasks[4];
	
	# Set up the test based on the bitwise test.  ONLY SET FOR THAT TEST
	if ($test_one) {
		$debug_flag               = 1;
		$debug_expected           = 1;
	}
	
	if ($test_two) {
		$d_flag                   = 1;
		$debug_expected           = 1;
	}

	if ($test_three) {
		$debug_extensive_flag     = 1;
		$debug_expected           = 1;
		$debug_extensive_expected = 1;
	}
	
	if ($test_four) {
		populate_file($debug_filename);
		$d_file_disp              = 1;
		$debug_expected           = 1;
	}
	
	if ($test_five) {
		populate_file($debug_extensive_filename);
		$de_file_disp             = 1;
		$debug_expected           = 1;
		$debug_extensive_expected = 1;
	}		
	
	# Run the fuction with the flags set
	($debug_returned, $debug_extensive_returned) = get_debug($debug_flag, $d_flag, $debug_extensive_flag, $debug_filename, $debug_extensive_filename);
	my ($debug_named_returned, $debug_named_extensive_returned)
        = get_debug_named ({
            debug=>$debug_flag,
            d=>$d_flag,
            debugextensive=>$debug_extensive_flag,
            debug_file=>$debug_filename,
            debug_extensive_file=>$debug_extensive_filename });

	# Print the plan summary
	$test_debug_text = "get_debug ( $de_file_disp $d_file_disp $debug_extensive_flag $d_flag $debug_flag ) " .
	                   ":: de file: $de_file_disp :: debug file: $d_file_disp :: de: $debug_extensive_flag :: d: $d_flag :: debug: $debug_flag :: number $combination_id";
	print "$test_debug_text\n";
	
	# Check against results
	is ($debug_returned,                 $debug_expected);
	is ($debug_extensive_returned,       $debug_extensive_expected);
	is ($debug_named_returned,           $debug_expected);
	is ($debug_named_extensive_returned, $debug_extensive_expected);
	

}






#####################################
## post-processing clean up #########
#####################################

#####################################
## Processing Functions #############
#####################################

sub populate_file {
	my $filename = shift;
	
	open (my $POPFILE, ">", $filename) or croak "Unable to create $filename: $!\n";
	
	print $POPFILE "Populating at " . time;
	
	close $POPFILE or croak "Unable to close $filename: $!\n";
	
	return 1;
}

sub remove_file {
	my $filename = shift;
	
	if (-e $filename) {
		
		unlink "$filename" or croak "Unable to remove $filename: $!\n";
		
	}
	
	return 1;
	
}
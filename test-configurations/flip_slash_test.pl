#!/usr/bin/perl -w
use strict;
use Test::More tests => 6;

###############################################################################
##### Point the lib to the CVS source location(s)
###############################################################################
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;

###############################################################################
##### Get the additional include locations from BGI::ESM::Common::INC
###############################################################################
my $addl_inc = get_include_locations();
push @INC, @{$addl_inc};

###############################################################################
##### Load common methods and variables
###############################################################################
require "setvar.pm";
require "ssm_common.pm";

###############################################################################
##### Testing Follows
###############################################################################
my (@run_set, @run_exp_dbl, @run_exp_sgl);

if (ssm_os_type() eq 'WINDOWS') {

	@run_set = (
								 "c:\\\\usr\\\\ov\\/",
									"c:/usr/ov/bin",
										"c:\\\\usr\\/OV\\\\bin"
								);
	
	@run_exp_dbl = (
								 "c:\\\\usr\\\\ov\\\\",
									"c:\\\\usr\\\\ov\\\\bin",
										"c:\\\\usr\\\\OV\\\\bin"
								);
	
	@run_exp_sgl = (
								 "c:\\usr\\ov\\",
									"c:\\usr\\ov\\bin",
										"c:\\usr\\OV\\bin"
								);
	
} else {

	@run_set = (
								 "/var/opt/OV",
									"/opt/OV/bin",
										"/var/opt/OV/bin"
								);
	
	@run_exp_dbl = (
								 "/var/opt/OV",
									"/opt/OV/bin",
										"/var/opt/OV/bin"
								);
	
	@run_exp_sgl = (
								 "/var/opt/OV",
									"/opt/OV/bin",
										"/var/opt/OV/bin"
								);

}

my $loop    = 0;
my @test_run;

### Double
foreach my $run_set_item (@run_set) {
	
	$test_run[$loop] = flip_slashes_to_back($run_set_item);
	is ($test_run[$loop], $run_exp_dbl[$loop], "flip_slashes( ) test run $loop: " . $run_set_item . " returned " . $test_run[$loop]);
	$loop++;
	
}

### Single
my $single_loop = 0;  # because the single set run requires a reset in a counter...
foreach my $run_set_item (@run_set) {
	
	$test_run[$loop] = flip_slashes_to_single_back($run_set_item);
	is ($test_run[$loop], $run_exp_sgl[$single_loop], "flip_slashes( ) test run $loop: " . $run_set_item . " returned " . $test_run[$loop]);
	$loop++;
	$single_loop++;
	
}

print "\n\nValidating usable variables in the returned...\n\n";

foreach my $loop_item (@test_run) {
	
	if (-e "$loop_item") {
		print "GOOD! Looks like $loop_item exists!\n";
	} else {
		print "BAD!  Looks like $loop_item DOESN'T exists!\n";
	}
	
}
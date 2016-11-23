
=head1 NAME

Test module for BGI ESM Common Debug methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::SelfService::Diskspace

=head1 REVISIONS

CVS Revsion: $Revision: 1.5 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-12-09   nichj   Developing
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
	get_filesystem_list
	get_filesystem_size
	get_filesystem_type
	get_filesystem_types_list
	get_filesystem_free
	get_filesystem_free_percent
);

BEGIN { use_ok('BGI::ESM::SelfService::Diskspace', @subs); };

#########################

can_ok( __PACKAGE__, 'get_filesystem_list');
can_ok( __PACKAGE__, 'get_filesystem_types_list');
can_ok( __PACKAGE__, 'get_filesystem_size');
can_ok( __PACKAGE__, 'get_filesystem_type');
can_ok( __PACKAGE__, 'get_filesystem_free');
can_ok( __PACKAGE__, 'get_filesystem_free_percent');

#########################
#########################

print "\n\nFilesystem Type Methods\n\n";
my @filesystem_types = sort qw( local remote removable unknown ram );

my $returned_types_ref   = get_filesystem_types_list();

is_deeply($returned_types_ref, \@filesystem_types, 'get_filesystem_types_list( ) should return a list of file system types.');

foreach my $filesystem_type (@filesystem_types) {

	my $filesystems_ref = get_filesystem_list({ type=>$filesystem_type });
	
	#foreach my $filesystem (@{$filesystems_ref}) {
	#	print "Filesystem name: $filesystem\n";
	#}
	
	if ($filesystem_type eq 'local') {
		cmp_ok(@{$filesystems_ref}, "gt", 0, 'get_filesystem_list( type=>' . $filesystem_type . ') should return a list of filesystems.');
	}
	
	print "\nFilesystem List:\n";
	print Dumper $filesystems_ref;
	
}

#########################
#########################

print "\n\nFilesystem details\n\n";

foreach my $filesystem_type (@filesystem_types) {
	
	print "\n\tLooking at filesystem type $filesystem_type\n";
	
	my $filesystem_ref = get_filesystem_list({ type=>$filesystem_type });
	
	foreach my $filesystem (@{$filesystem_ref}) {
		
		print "\n\t\tLooking at filesystem $filesystem\n";

		my ($comp_check, $comp_val, $comp_text_size, $comp_text_free, $comp_text_full, $comp_text_frpercent, $comp_text_flpercent);

		my $filesystem_type         = get_filesystem_type({ filesystem=>$filesystem });
		my $filesystem_size         = get_filesystem_size({ filesystem=>$filesystem });
		my $filesystem_free         = get_filesystem_free({ filesystem=>$filesystem });
		my $filesystem_full         = get_filesystem_full({ filesystem=>$filesystem });
		my $filesystem_free_percent = get_filesystem_free_percent({ filesystem=>$filesystem });
		my $filesystem_full_percent = get_filesystem_full_percent({ filesystem=>$filesystem });
		
		
		if ($filesystem_type eq 'removable') {
			$comp_val            =  "eq";
			$comp_check          = undef;
			$comp_text_size      = "get_filesystem_size({ filesystem=>$filesystem}) should not return anything since it is removable.";
			$comp_text_free      = "get_filesystem_free({ filesystem=>$filesystem}) should not return anything since it is removable.";
			$comp_text_full      = "get_filesystem_full({ filesystem=>$filesystem}) should not return anything since it is removable.";
			$comp_text_frpercent = "get_filesystem_free_precent({ filesystem=>$filesystem}) should not return anything since it is removable.";
			$comp_text_flpercent = "get_filesystem_full_precent({ filesystem=>$filesystem}) should not return anything since it is removable.";
		}
		else {
			$comp_val            = "gt";
			$comp_check          = 0;
			$comp_text_size      = "get_filesystem_size({ filesystem=>$filesystem}) should return total MB: $filesystem_size";
			$comp_text_free      = "get_filesystem_free({ filesystem=>$filesystem}) should return free  MB: $filesystem_free";
			$comp_text_full      = "get_filesystem_full({ filesystem=>$filesystem}) should return full  MB: $filesystem_full";
			$comp_text_frpercent = "get_filesystem_free_precent({ filesystem=>$filesystem}) should return free percentage: $filesystem_free_percent.";
			$comp_text_flpercent = "get_filesystem_full_precent({ filesystem=>$filesystem}) should return full percentage: $filesystem_full_percent.";
			
			#is (($filesystem_free + $filesystem_full), $filesystem_size, 'filesystem free + filesystem full should equal filesystem size');
			
			is (($filesystem_full_percent + $filesystem_free_percent), 100, 'filesystem free percent + filesystem full percent should eq 100');
		}
		
		cmp_ok($filesystem_size, "$comp_val", $comp_check, $comp_text_size);
		
		cmp_ok($filesystem_free, "$comp_val", $comp_check, $comp_text_free);

		cmp_ok($filesystem_full, "$comp_val", $comp_check, $comp_text_full);
		
		cmp_ok($filesystem_free_percent, "$comp_val", $comp_check, $comp_text_frpercent);
		
		cmp_ok($filesystem_full_percent, "$comp_val", $comp_check, $comp_text_flpercent);
		
		
	}
	
}

print "\n\nTest for oddities\n\n";

my @fs_names;

if (os_type() eq 'WINDOWS') {
	@fs_names = ("c:\\", "d", "c", "c:\\code", "c:/code");
}
else {
	@fs_names = ("/etc/OpT/OV", "/opt/OV/bin/OpC");
}

foreach my $fs_name (@fs_names) {
	my $fs_full_per_odd = get_filesystem_full_percent({ filesystem=>$fs_name });

	print "The return from checking $fs_name is $fs_full_per_odd\n\n";
}
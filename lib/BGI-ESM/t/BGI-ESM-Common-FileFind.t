
=head1 NAME

Test module for BGI ESM Common FileFind Methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::FileFind

=head1 MAJOR REVISIONS

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-10-25   nichj   Developing release 1
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:
	: 
	
=cut

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
#use Net::Nslookup;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;
use BGI::ESM::Common::Shared qw(os_type);

my @subs = qw(
	find_files_in_sub
 );

BEGIN { use_ok('BGI::ESM::Common::FileFind', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'find_files_in_sub'     );

###############################################################################
##### Load common methods and variables
###############################################################################
my ($dir);

if (os_type() eq 'WINDOWS') {
	$dir = "c:/temp";
}
else {
	$dir = "/tmp";
	
}

#####################################
#####################################
FIND_FILES_IN_SUB:
{
	my @types = qw(all dirs files);
	
	print "\nLooking in $dir\n\n";
	
	foreach my $type (@types) {
		my $list = find_files_in_sub($dir, $type);
		print "\n\nLooking in $dir for $type\n\n";
		print Dumper ($list);
	}
	
}


#####################################
## post-processing clean up #########
#####################################



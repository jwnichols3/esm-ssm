#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME

Test module for BGI ESM Testing Shared Methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::Testing::Shared

=head1 REVISIONS

CVS Revsion: $Revision: 1.1 $
    Date:    $Date: 2005/11/01 23:02:03 $
    
    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2005-11-01   nichj   Creating
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
    get_testing_shared_version
    get_alert_config_key
);

BEGIN { use_ok('BGI::ESM::Testing::Shared', @subs); };

#########################

can_ok( __PACKAGE__, 'get_testing_shared_version');
can_ok( __PACKAGE__, 'get_alert_config_key');

####################################
####################################
GET_TESTING_SHARED_VERSION:
{
	
	print "\n\nget_testing_shared_version()\n";
	my $common_testing_version = get_testing_shared_version();
	
	is ($common_testing_version, $common_testing_version,
		'get_testing_shared_version( ) should return the version of BGI::ESM::Testing::Shared: ' . $common_testing_version);
	
}

#####################################
## post-processing clean up #########
#####################################



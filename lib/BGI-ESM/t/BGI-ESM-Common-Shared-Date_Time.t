#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME

Test module for BGI ESM Common Shared Methods specific to Date and Time

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::Shared methods specific to alerting.

=head1 REVISIONS

CVS Revsion: $Revision: 1.1 $
    Date:    $Date: 2006/03/26 23:14:13 $
    
    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2006-03-17   nichj   Created.  Added get_formatted_date_time test
    #####################################################################

=head1 TODO

    Move all alerting methods to this test library.
	
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
    get_formatted_date_time
);

BEGIN { use_ok('BGI::ESM::Common::Shared', @subs); };

#########################

can_ok( __PACKAGE__, 'get_formatted_date_time' ); # done

#####################################
#####################################
## Start-processing         #########
#####################################
#####################################

GET_FORMATTED_DATE_TIME:
{

    my $formatted_date_time = get_formatted_date_time();
    
}

#####################################
#####################################
## post-processing clean up #########
#####################################
#####################################




=head1 NAME

Test module for BGI ESM Common Stats methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::Stats methods

=head1 REVISIONS

CVS Revsion: $Revision: 1.1 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2009-03-11   nichj   Developing
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

my @subs = qw(
    yesterday
    store_statistics
    insert_stats_db
 );

BEGIN { use_ok('BGI::ESM::Common::Stats', @subs); };

#########################

can_ok( __PACKAGE__, 'yesterday');
can_ok( __PACKAGE__, 'store_statistics');
can_ok( __PACKAGE__, 'insert_stats_db');

YESTERDAY:
{
    is (1, 1, 'YESTERDAY');
}

STORE_STATISTICS:
{
    is (1, 1, 'STORE_STATISTICS');
    
}

INSERT_STATS_DB:
{
    is (1, 1, 'INSERT_STATS_DB');
    
}
###########################################################################
## Internal Routines
###########################################################################

sub _get_formatted_date {
    my ($seconds, $minute, $hour, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
    
    $month = $month + 1;
    $year  = $year  + 1900;
    
    my $retval = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $minute, $seconds);
    
    return $retval;
}
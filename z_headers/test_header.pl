#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME

Test module for 

=head1 SYNOPSIS

This is test suite for 

=head1 REVISIONS

CVS Revsion: $Revision: 1.1 $
    Date:    $Date: 2006/02/17 22:04:30 $
    
    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2005-mm-dd  userid   Developing release 1
    #####################################################################

=head1 TODO

    - Tests to write:
        . 
    - Tests to enhance:
        .
    
	
=cut

#########################
#########################
## modules to use #######
use warnings;
use strict;
use Data::Dumper;
use Carp;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
#########################
#########################

#########################
#########################
## Subs to check ########
### list each function / method in this list
my @subs = qw(
    
 );

## Check the use of the above list works
BEGIN { use_ok('BGI::ESM::Common::Shared', @subs); };

#########################
#########################
## Additional testing on the list of the 
foreach my $subname (@subs) {
  can_ok( __PACKAGE__, $subname);
}


#####################################
#####################################
## pre-processing set up ############
#####################################
#####################################


#####################################
#####################################


#####################################
#####################################
## post-processing clean up #########
#####################################
#####################################



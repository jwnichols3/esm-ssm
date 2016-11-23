#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME



=head1 SYNOPSIS



=head1 REVISIONS

CVS Revision: $Revision: 1.2 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-08-26   nichj   Developing release 1
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

##############################################################################
my @subs = qw(
    write_nodelist
    write_nodelist_archive
    write_nodelist_deltas
    nodes_from_source
	netiq_vpo_node_add
 );

BEGIN { use_ok('BGI::ESM::VpoServer::NodeSync', @subs); };

##############################################################################

can_ok( __PACKAGE__, 'write_nodelist');
can_ok( __PACKAGE__, 'write_nodelist_archive');
can_ok( __PACKAGE__, 'write_nodelist_deltas');
can_ok( __PACKAGE__, 'nodes_from_source');
can_ok( __PACKAGE__, 'netiq_vpo_node_add');

###############################################################################
##### Load common methods and variables
###############################################################################

###############################################################################
##### Testing Section
###############################################################################

#########################
#########################

#########################
#########################

#########################
#########################

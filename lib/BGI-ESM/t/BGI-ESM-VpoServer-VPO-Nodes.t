#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME

Test script for BGI::ESM::VpoServer::VPO
Nodes related methods.

=head1 SYNOPSIS



=head1 REVISIONS

CVS Revision: $Revision: 1.2 $

	#####################################################################
	#
	# Major Revision History:
	#
	#  Date       Initials  Description of Change
	#  ---------- --------  ---------------------------------------
	#  2006-03-31   nichj   Developing
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
use BGI::ESM::Common::Shared qw(os_type get_hostname say);
use BGI::ESM::Common::Variables qw(server_variables);


##############################################################################
my @subs = qw(
	get_vpo_node_list
	mv_hier
	netiq_vpo_node_add
	vpo_node_add
	vpo_node_exist
 );

BEGIN { use_ok('BGI::ESM::VpoServer::VPO', @subs); };

##############################################################################

can_ok( __PACKAGE__, 'get_vpo_node_list'); # done
can_ok( __PACKAGE__, 'mv_hier');
can_ok( __PACKAGE__, 'netiq_vpo_node_add');
can_ok( __PACKAGE__, 'vpo_node_add');
can_ok( __PACKAGE__, 'vpo_node_exist');

###############################################################################
##### Load common methods and variables
###############################################################################


###############################################################################
##### Testing Section
###############################################################################


#########################
#########################
VPO_NODE_LIST:
{
	
	print "\n\nget_vpo_node_list\n\n";
	
	my $vpo_node_list_got = get_vpo_node_list();
	
	print Dumper $vpo_node_list_got;
	
	is_deeply ($vpo_node_list_got, get_vpo_node_list(), 'get_vpo_node_list( ) should return a list of vpo nodes');
	
	print "\n\nvpo_node_exist\n\n";
	print "\tPositive\n\n";
	foreach my $node_to_check (@{$vpo_node_list_got}) {
		
		my $exist = vpo_node_exist($node_to_check);
		
		is ($exist, 1, "vpo_node_exist($node_to_check)");
		
	}
	
	print "\n\n\tNegative\n\n";
	
	my $invalid_node = time();
	
	for (1..10) {
		
		my $invalid_node = sprintf("$invalid_node-%3d", $_);
		print "Checking $invalid_node\n";
		
	}

}
###############################################################################
##### post-processing clean up 
###############################################################################



#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME



=head1 SYNOPSIS



=head1 REVISIONS

CVS Revision: $Revision: 1.4 $

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
	vpo_server_type
 );

BEGIN { use_ok('BGI::ESM::VpoServer::ServerCommon', @subs); };

#########################

can_ok( __PACKAGE__, 'vpo_server_type'  );

##########################

###############################################################################
##### Load common methods and variables
###############################################################################


###############################################################################
##### Testing Section
###############################################################################


##########################
##########################
VPO_SERVER_TYPE:
{
    my $vpo_server = "rdcuxsrv054";
    my $type_hash = {
                     'type' => "prod",
                     'role' => "primary"
                    };
    
    my $vpo_type_hash = vpo_server_type($vpo_server);
    
    is_deeply($vpo_type_hash, $type_hash, 'vpo_server_type( ) should return the role of the specified server');
    
    print "\nAnalysis of the variables\n";
    print "\nManually set hash:\n";
    print Dumper ($type_hash);
    print "\nFunction called hash:\n";
    print Dumper ($vpo_type_hash);
}
##########################


###############################################################################
##### post-processing clean up 
###############################################################################



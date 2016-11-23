=head1 TITLE

VPO Server Peregrine methods

=head1 DESCRIPTION

This holds methods that relate to the VPO->Peregrine interface

=head1 USAGE

use BGI::ESM::VpoServer::Peregrine

=head1 TODO




=head1 REVISIONS

CVS Revision: $Revision: 1.3 $

  #####################################################################
  #  2005-10-05 - nichj - Migrated to Perl Module
  #####################################################################
 
=cut

##############################################################################
### Package Name #############################################################
package BGI::ESM::VpoServer::Peregrine;
##############################################################################

##############################################################################
### Module Use Section #######################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os);
##############################################################################

##############################################################################
### Require Section ##########################################################
require Exporter;
##############################################################################

##############################################################################
### Who is this ##############################################################
our @ISA = qw(Exporter BGI::ESM::VpoServer);
##############################################################################

##############################################################################
### Public Exports ###########################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	peregrine_working
	create_ticket
	get_scauto_program_cmd
	get_peregrine_working_flag
);
##############################################################################

##############################################################################
### VERSION ##################################################################
our $VERSION = (qw$Revision: 1.3 $)[-1];
##############################################################################

##############################################################################
# Public Variables
##############################################################################

##############################################################################
# Public Methods / Functions
##############################################################################


=head2 peregrine_working()
	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#  does a check for $scauto_not_working and returns TRUE (1) if working
	#  FALSE (0) if not
	#
	#  notes: $peregrine_not_working will have a size > 0 bytes if not working.
	# -------------------------------------------------------------------
=cut

sub peregrine_working {
	my $peregrine_not_working = get_peregrine_working_flag();
	my $retval                = 1;

	if (-e $peregrine_not_working) {
		if (not -z $peregrine_not_working) {
			$retval = 0;
		}
	}
	
	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 create_ticket(\%vpo_data)
	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#  sends the event to SCAuto
	# -------------------------------------------------------------------
=cut

sub create_ticket ($) {
	my $vpo_data = shift;
	
	my $scauto_program = get_scauto_program_cmd();
	
	my $vpo_msgid = $vpo_data->{'msgid'};

	system("$scauto_program", "$vpo_msgid");
	
	return 1;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_scauto_program_cmd()
	returns the command for SCAUTO
=cut

sub get_scauto_program_cmd {
	
	return "/opt/OV/scauto/scfromitoTTI";
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_peregrine_working_flag()
	returns scalar with file name of the peregrine working flag
=cut

sub get_peregrine_working_flag {
	
	return "/opt/check-scauto/itsworking";
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

##############################################################################
### End of Public Methods / Functions ########################################
##############################################################################

##############################################################################
### Private Methods / Functions ##############################################
##############################################################################






##############################################################################
### End of Private Methods / Functions #######################################
##############################################################################

##############################################################################
# Do not change this.  Required for successful require load
1;
##############################################################################

__END__

=head2 DEVELOPER'S NOTES
 

=cut


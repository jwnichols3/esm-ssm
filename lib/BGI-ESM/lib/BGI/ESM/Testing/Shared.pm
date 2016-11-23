=head1 NAME

BGI ESM Testing Shared Methods

=head1 SYNOPSIS



=head1 REVISIONS

CVS Revision: $Revision: 1.1 $
    Date:     $Date: 2005/11/01 23:02:54 $

	#####################################################################
	#
	# Major Revision History:
	#
	#  Date       Initials  Description of Change
	#  ---------- --------  ---------------------------------------
	#  2005-11-01   nichj   Creating
	#  
	#####################################################################

=head1 TODO

- Add method for checking validate date and time (start=, stop=, dayofweek=)
...

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::Testing::Shared;
###############################################################################

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use File::stat;
use File::Copy;
use Net::FTP;
use Mail::Sendmail;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
###############################################################################

###############################################################################
### Require Section ###########################################################
require Exporter;
###############################################################################

###############################################################################
### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::Testing);
###############################################################################

###############################################################################
### Public Exports ############################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    get_testing_shared_version
    get_alert_config_key
);
###############################################################################

###############################################################################
### VERSION ###################################################################
our $VERSION = (qw$Revision: 1.1 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################

###############################################################################
# Public Methods / Functions
###############################################################################


=head2 get_testing_shared_version
	returns a scalar with the version of this module
=cut

sub get_testing_shared_version {
	return $VERSION;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_alert_config_key($alert_config_entry)
    Evaluates the alert config entry for app=
    Returns 0 if not found, the value of app=
    
    Example ---
    my $a_config_ent = "app=esm0001 sev=major   filesys=c:"
    my $config_key = get_alert_config_key($a_config_ent);
    
    TODO
    - Write
    
=cut
sub get_alert_config_key {
    
    
}

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################


#################################################################################
### End of Private Methods / Functions ##########################################
#################################################################################

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES

=cut

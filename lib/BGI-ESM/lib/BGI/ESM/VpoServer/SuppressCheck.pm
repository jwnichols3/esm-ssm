=head1 TITLE

VPOServer Suppress Check module

=head1 DESCRIPTION

This holds methods in relation to notification suppression

=head1 USAGE

use BGI::ESM::VpoServer::SuppressCheck

=head1 TODO

    - more logic around getting the suppress command
    

=head1 REVISIONS

CVS Revision: $Revision: 1.5 $

  #####################################################################
  #  2005-10-05 - nichj - Migrated to Perl Module
  #####################################################################
 
=cut

##############################################################################
### Package Name #############################################################
package BGI::ESM::VpoServer::SuppressCheck;
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
    suppress_check
    get_suppress_command
);
##############################################################################

##############################################################################
### VERSION ##################################################################
our $VERSION = (qw$Revision: 1.5 $)[-1];
##############################################################################

##############################################################################
# Public Variables
##############################################################################

##############################################################################
# Public Methods / Functions
##############################################################################


=head2 suppress_check($message_group, $node, $cma, $message_text, $msgid)
    This function is called when the usage output is required
=cut

sub suppress_check {
  my $suppress_data = shift;
  my %suppress_data = %$suppress_data;
     
  my ($vpo_message_group, $vpo_node, $vpo_cma, $vpo_msgtext, $vpo_msgid);
  
  $vpo_message_group = $suppress_data{'message_group'};
  $vpo_node          = $suppress_data{'node'};
  $vpo_cma           = $suppress_data{'cma'};
  $vpo_msgtext       = $suppress_data{'message_text'};
  $vpo_msgid         = $suppress_data{'msgid'};
  
  
  my $retval;
  my $suppress_command = get_suppress_command();
  
    if (-e "$suppress_command") { 
        $retval = system("$suppress_command", "$vpo_message_group", "$vpo_node", "$vpo_msgtext", "$vpo_cma");
        print "Debug: suppress_check retval is $retval\n";
        print "Debug: suppress_check command is $suppress_command $vpo_message_group $vpo_node $vpo_msgtext $vpo_cma\n";
    }
    else {
        $retval = 0;
    }

  return $retval;  
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_suppress_command()
    returns a scalar with the suppress command
=cut

sub get_suppress_command {
    
    return "/opt/OV/suppress/suppress_check";
    
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


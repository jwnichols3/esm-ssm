=head1 NAME

Library Name

=head1 SYNOPSIS

Library Synopsis

=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.4 $
    
    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2005-mm-dd   userid  Original
    #  
    #####################################################################

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::;

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
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
our @ISA = qw(Exporter BGI::ESM::);
###############################################################################

###############################################################################
### Public Exports ############################################################
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
###############################################################################

###############################################################################
### VERSION ###################################################################
my $VERSION = (qw$Revision: 1.4 $)[-1];
###############################################################################

###############################################################################
# Public Methods / Functions
###############################################################################

=head2 function_name(function_options)
    
    
=head3 Purpose  
    
    
=head3 Returns
    
    
=head3 Requires
    
    
=head3 Example
    
    
=head3 Issues/Enhancements
    
    
=head3 Revisions
    
    Date       Initials  Description of Change
    ---------- --------  ---------------------------------------
    2005-mm-dd   userid  Original
    -------------------------------------------------------------------

=cut

sub function_name {


}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

###############################################################################
### End of Public Methods / Functions #########################################
###############################################################################


###############################################################################
### Private Methods / Functions ###############################################
###############################################################################



###############################################################################
### End of Private Methods / Functions ########################################
###############################################################################

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES

=cut
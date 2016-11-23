
=head1 NAME

Library Name

=head1 SYNOPSIS

Library Synopsis

=head1 MAJOR REVISIONS

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

#################################################################################
### Package Name ################################################################
package BGI::ESM::;

#################################################################################
### Module Use Section ##########################################################
use 5.008000;
use strict;
use warnings;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::);
#################################################################################

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.5 $)[-1];
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

=head2 function_name(function_options)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  
  #  Purpose:  
  #  Returns:  
  #  Requires: 
  #  Issues/Enhancements:
  #            
  #  Revisions:
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-mm-dd   userid  Original
  # -------------------------------------------------------------------

=cut

sub function_name {


}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################

## Uncomment when needed ###
#=head2 _function_name(function_options)
#
#  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#  # Function:  
#  #  Purpose:  
#  #  Returns:  
#  #  Requires: 
#  #  Issues/Enhancements:
#  #            
#  #  Revisions:
#  #  Date       Initials  Description of Change
#  #  ---------- --------  ---------------------------------------
#  #  2005-mm-dd   userid  Original
#  # -------------------------------------------------------------------
#
#=cut
#
#sub _function_name {
#
#
#}
## ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


#################################################################################
### End of Private Methods / Functions ##########################################
#################################################################################

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

## Function Template
##
## ---copy and uncomment starting here ---
#
#=head2 function_name(function_options)
#
#  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#  # Function: function_name(function_options)
#  #  Purpose:  Purpose of the function
#  #  Returns:  What kind of data does it return
#  #  Requires: Does it require any special modules to be loaded
#  #  Issues/Enhancements:
#  #            Any possible enhancements that might make this function better
#  #  Revisions:
#  #  Date       Initials  Ver  Description of Change
#  #  ---------- -------- ----- ---------------------------------------
#  #  2005-mm-dd   userid  1.00 Original
#  # -------------------------------------------------------------------
#
#=cut
#
#sub function_name {
#
#
#}
## ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
## ---copy and uncomment  ending  here ---


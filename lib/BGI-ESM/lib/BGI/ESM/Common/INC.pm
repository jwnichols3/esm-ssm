
=head1 NAME

BGI::ESM::Common::INC

=head1 SYNOPSIS

This package deals with setting the @INC variable for all monitoring programs.

=head1 MAJOR REVISIONS

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-08-26   nichj   Original
  #  2005-08-26   nichj   Added server_library to CVS locations
  #  2005-10-17   nichj   Changed the required Perl version to v5.004
  #####################################################################

=cut

#################################################################################
### Package Name ################################################################
package BGI::ESM::Common::INC;

#################################################################################
### Module Use Section ##########################################################
use 5.004000;
use strict;
use warnings;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
#use BGI::ESM::Common::Variables;
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::Common);
#################################################################################

#################################################################################
### Public Exports ##############################################################
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  get_include_locations
);
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.5 $)[-1];
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

=head2 get_inc_locations()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  get_inc_locations()
  #  Purpose:  gets a list of locations to add to @INC
  #  Returns:  a reference to an array with additional @INC values
  #  Requires:
  #  Issues/Enhancements:
  #
  #  Revisions:
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-08-26   nichj   Original
  # -------------------------------------------------------------------

=cut

sub get_include_locations {
  return _include_environment();

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################

=head2 _include_environment()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function:  the private version of the include environment
  #  Purpose:  sets the array for adding to the @INC
  #  Returns:  a reference to an array
  #  Requires:
  #  Issues/Enhancements:
  #
  #  Revisions:
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-08-26    nichj  Original
  # -------------------------------------------------------------------

=cut

sub _include_environment {
	my @inc_cvs_windows  = (
			"c:/code/vpo/SSM/src", "c:/code/vpo/SSM/src",
			"c:/code/vpo/server_library", "/apps/esm/vpo/server_library",
			"c:/code/vpo/global library", "/apps/esm/vpo/global library"
			);

	my @inc_cvs_unix     = (
			"/apps/esm/vpo/SSM/src", "/apps/esm/vpo/SSM/src"
			);

	my @inc_server_lib   = ("/apps/esm/lib");

	my @inc_vpo_agt_unix = ("/var/opt/OV/bin/instrumentation", "/var/opt/OV/bin/OpC/cmds");

	### To prevent uninitialized vairables from being used...
		my @inc_env_ov_dir = ();
		if ($ENV{'OvAgentDir'}) {
			@inc_env_ov_dir = (
					$ENV{'OvAgentDir'} . "/bin/OpC/cmds",
					$ENV{'OvAgentDir'} . "/bin/HP OpenView/data/bin/instrumentation",
				);
		}

	my @inc_vpo_agt_win  = (
			@inc_env_ov_dir,
			"c:/usr/OV/bin/OpC/cmds", "c:/usr/OV/bin/HP OpenView/data/bin/instrumentation",
			"e:/usr/OV/bin/OpC/cmds", "e:/usr/OV/bin/HP OpenView/data/bin/instrumentation"
			);


	my @add_inc = (
		@inc_cvs_windows, @inc_cvs_unix, @inc_server_lib, @inc_vpo_agt_unix, @inc_vpo_agt_win
		);

	return \@add_inc;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

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
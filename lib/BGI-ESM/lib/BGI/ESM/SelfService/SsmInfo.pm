=head1 NAME

BGI ESM SelfService Information Methods

=head1 SYNOPSIS

This module will be used for gathering and reporting information about self
service programs, etc.


=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.2 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-09-23   nichj   Starting
  #  
  #####################################################################

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::SelfService::SsmInfo;

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use Carp;
#use MLDBM qw(DB_File Storable);
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared qw(os_type check_os trim);
use BGI::ESM::Compile::Ssm qw(get_program_exe_list_os);
###############################################################################

###############################################################################
### Require Section ###########################################################
require Exporter;
###############################################################################

###############################################################################
### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::SelfService);
###############################################################################

###############################################################################
### Public Exports ############################################################
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    get_exe_list
    ssm_program_versions
);
###############################################################################

###############################################################################
### VERSION ###################################################################
my $VERSION = (qw$Revision: 1.2 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################

###############################################################################
# Public Methods / Functions
###############################################################################

=head2 get_exe_list($os, $agent_type)
    returns a reference to an array with a list of executables based on the
     running OS and agent type
=cut

sub get_exe_list {
    my ($os, $agent_type) = @_;
    $os                   = check_os($os);
    my (@return_list);

    my $ssm_vars          = ssm_variables();
    my $ssm_bin           = $ssm_vars->{'SSM_BIN'};
    
    my $program_list      = get_program_exe_list_os($os);
    
    foreach my $program (@{$program_list}) {
        push @return_list, $ssm_bin . "/$program";
    }

    return \@return_list;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

sub ssm_program_versions {
    my @return_array;
    
    my $monitor_programs = get_exe_list(os_type());

    foreach my $monitor_command (@{$monitor_programs}) {
        my $version = `$monitor_command -v`;
        push @return_array, $version;
    }
    chomp(@return_array);
    @return_array = trim(@return_array);
    
    return \@return_array;
    
}

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
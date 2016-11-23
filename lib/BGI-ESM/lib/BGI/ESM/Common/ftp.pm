
=head1 NAME

BGI ESM Common Shared Methods: ftp functions

=head1 SYNOPSIS

This library is used for ftp functions.

=head1 REVISIONS

CVS Revision: $Revision: 1.1 $
    Date:     $Date: 2009/03/06 22:43:40 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2009-03-06   nichj   Create
  #
  #####################################################################

=head1 TODO

##
##

=cut


###############################################################################
### Package Name ##############################################################
package BGI::ESM::Common::ftp;
###############################################################################

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Net::FTP;
use Carp;
#use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
#use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
#no strict "subs";
#no strict "vars";

###############################################################################

###############################################################################
### Require Section ###########################################################
require Exporter;
###############################################################################

###############################################################################
### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::Common);
###############################################################################

###############################################################################
### Public Exports ############################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    ftp_file
);
###############################################################################

###############################################################################
### VERSION ###################################################################
our $VERSION = (qw$Revision: 1.1 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################
#our $ssm_vars                     = ssm_variables();
#our $agent_vars                   = agent_variables();
#our $agent_version                = get_agent_version();
#our $agent_comm_type              = get_agent_comm_type();


###############################################################################
# Public Methods / Functions
###############################################################################

=head2  ftp_file($from_file, $to_server, $to_dir, $to_file, $ftp_user, $ftp_pass)

This will return FALSE if there is a problem, TRUE if successful.

Options Hash (note: all options are required)
%ftp_hash = (
    from_file       => local file to ftp
    to_server       => server to ftp to
    to_dir          => remote directory
    to_file         => remote filename
    user            => user name
    password        => password of user
    );

=cut

sub ftp_file ($) {
    my ($arg_ref) = @_;
    
    my $from_file           = _not_blank($arg_ref->{from_file});
    my $to_server           = _not_blank($arg_ref->{to_server});
    my $to_dir              = _not_blank($arg_ref->{to_dir});
    my $to_file             = $arg_ref->{to_file};
    my $user                = _not_blank($arg_ref->{user});
    my $pw                  = _not_blank($arg_ref->{password});

    my $retval              = 1;
    my ($ftp);
    
    if (not $to_file) {
        $to_file = $from_file;
    }
    
    if (not $ftp=Net::FTP->new($to_server,Timeout=>240)) {
      
      warn "Can't connect to $to_server: $!\n";
      $retval = 0;
    
    }
    else {
      
        if (not $ftp->login($user, $pw)) {
          
            warn "Can't login to $to_server: $!\n";
            $retval = 0;
          
        }
        else {
          
            if (not $ftp->cwd("$to_dir")) {
        
                warn "Unable to change directories to $to_dir: $!\n";
                $retval = 0;
              
            }
            else {
              
                if (not $ftp->put("$from_file","$to_file")) {
          
                warn "Unable to send file $to_file: $!\n";
                $retval = 0;
                
                }
                else {
                  
                  $ftp->quit();
                  
                }
              }
        }
    }
    
    return $retval;
  
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################

=head2  _function_name

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:    _function_name
	# Description:  
	# Returns:      
	# Requires:     
  # -------------------------------------------------------------------

=cut


# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _not_blank
    Description: ensures that a passed parameter is not blank
    Croaks if it is.
=cut
sub _not_blank{
    my ($var_to_check) = @_;
    
    if (not $var_to_check) {
        croak "Error: Variable must be set.";
    }
    
    return $var_to_check;
    
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

=head1 DEVELOPER'S NOTES


=cut




=head1 NAME

BGI::ESM::SelfService::SsmTesting

=head1 SYNOPSIS

Package is used by the Self Service Test modules to establish, verify, and breakdown the test environment

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.8 $
    Date:     $Date: 2005/11/02 17:38:56 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-08-29   nichj   Original release in process
  #  2005-11-02   nichj   Minor update
  #####################################################################

=cut


#################################################################################
### Package Name ################################################################
package BGI::ESM::SelfService::SsmTesting;

#################################################################################
### Module Use Section ##########################################################
use 5.008;
use strict;
use warnings;
use Data::Dumper;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared;
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::SelfService);
#################################################################################

#################################################################################
### Public Exports ##############################################################
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    get_ssm_config_list
    create_config_file
    get_config_file_location
    get_default_config_hash
    get_blank_config_hash
    get_run_number
);
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.8 $)[-1];
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

=head2 get_ssm_config_list()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub get_ssm_config_list {
    return _set_ssm_config_list();
}


=head2 create_config_file($config_prefix, $run_number)
  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  the name of the config file
  #  Requires: must have the run number established already
  #  Issues/Enhancements:
  # -------------------------------------------------------------------
=cut

sub create_config_file ($$) {
    my $config_prefix   = shift;
    my $run_number      = shift;
    my $config_file_location = _config_file_location();
    
    if (not $run_number) {
      die "Unable to continue as run_number is not set!\n";
    }
    
    my $config_file_name = $config_file_location . "/" . $config_prefix . ".dat." . $run_number;
    
    if (not -e $config_file_name) {
      open (CONFIGFILE, ">", $config_file_name) or die "Unable to create $config_file_name: $!\n";
      close CONFIGFILE;
    }
    
    return $config_file_name;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 populate_config_file($config_file, \%hash_to_populate_file)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  populates the $config_file with entries corresponding to \%hash_to_populate_file
  #  Returns:  0 if problem, 1 if successful
  #  Requires: must have a filename.
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub populate_config_file ($$) {
    my $config_file_name = shift;
    my $hash_to_populate = shift;
    
    if (not -e $config_file_name) {
        return 0;
    }
  
}

=head2 get_config_file_location()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  the location of the SSM config files to use for testing
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub get_config_file_location {
  
    return _config_file_location();
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_blank_config_hash($config_prefix)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub get_blank_config_hash ($) {
    my $config_prefix = shift;
    
    return _blank_config_hash($config_prefix);
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_default_config_hash()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  the location of the SSM config files to use for testing
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub get_default_config_hash {
    return _set_default_hash();
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_run_number()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  the location of the SSM config files to use for testing
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub get_run_number {
    return _set_run_number();
  
}


#################################################################################
### Private Methods / Functions #################################################
#################################################################################

=head2 _config_file_location()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  the location of the SSM config files to use for testing
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub _config_file_location {
    my $os = os_type();
    my ($config_file_location);
    
    if ($os eq 'WINDOWS') {
      $config_file_location = "c:/ssm";
    } else {
      $config_file_location = "/tmp/.ssm";
    }
    
    if (not -e $config_file_location) { mkdir "$config_file_location", 0777 or die "Unable to create directory $config_file_location: $!\n"; }
    
    return $config_file_location;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _blank_config_hash(<config prefix>)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub _blank_config_hash ($) {
    my $config_prefix = shift;
    #my $default_hash  = _set_default_hash();
    
    
    if (lc $config_prefix eq "fileage")   { return _default_hash_fileage();   }
    if (lc $config_prefix eq "filesys")   { return _default_hash_filesys();   }
    if (lc $config_prefix eq "process")   { return _default_hash_process();   }
    if (lc $config_prefix eq "rotate")    { return _default_hash_rotate();    }
    if (lc $config_prefix eq "powerpath") { return _default_hash_powerpath(); }
    
    # If it makes it here then there wasn't a match on the config prefix
    return 0;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _default_hash_<config prefix>()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  returns a blank hash with the required keys for the <config_prefix>
  #  Returns:  
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

########### Default FILEAGE
sub _default_hash_fileage () {
    my $default_hash = _set_default_hash();
    my %default_hash = %{$default_hash};
    my (%return_hash, $return_hash);
    
    #print "_default_hash_fileage - incoming default hash\n";
    #print Dumper (\%default_hash);
  
    $return_hash = {
                    'file'    => "",
                    'dir'     => "",
                    'age_threshold' => ""
                   };
    
    %return_hash = %{$return_hash};
    
    %return_hash = (%return_hash,  %default_hash);
    
    return \%return_hash;
  
}

########### Default FILESYS
sub _default_hash_filesys () {
    my $default_hash = _set_default_hash();
    my %default_hash = %{$default_hash};
    my (%return_hash, $return_hash);
    
    #print "_default_hash_fileage - incoming default hash\n";
    #print Dumper (\%default_hash);
  
    $return_hash = {
                    'filesys'    => "",
                    'size'       => "",
                   };
    
    %return_hash = %{$return_hash};
    
    %return_hash = (%return_hash,  %default_hash);
    
    return \%return_hash;
  
}

########### Default PROCESS
sub _default_hash_process () {
    my $default_hash = _set_default_hash();
    my %default_hash = %{$default_hash};
    my (%return_hash, $return_hash);
    
    #print "_default_hash_fileage - incoming default hash\n";
    #print Dumper (\%default_hash);
  
    $return_hash = {
                    'process' => "",
                   };
    
    %return_hash = %{$return_hash};
    
    %return_hash = (%return_hash,  %default_hash);
    
    return \%return_hash;
  
}

########### Default ROTATE
sub _default_hash_rotate () {
    my $default_hash = _set_default_hash();
    my %default_hash = %{$default_hash};
    my (%return_hash, $return_hash);
    
    #print "_default_hash_fileage - incoming default hash\n";
    #print Dumper (\%default_hash);
  
    $return_hash = {
                    'file'    => "",
                    'dir'     => "",
                    'age_threshold' => ""
                   };
    
    %return_hash = %{$return_hash};
    
    %return_hash = (%return_hash,  %default_hash);
    
    return \%return_hash;
  
}

########### Default POWERPATH
sub _default_hash_powerpath () {
    my $default_hash = _set_default_hash();
    my %default_hash = %{$default_hash};
    my (%return_hash, $return_hash);
    
    #print "_default_hash_fileage - incoming default hash\n";
    #print Dumper (\%default_hash);
  
    $return_hash = {
                    'issue'   => ""
                   };
    
    %return_hash = %{$return_hash};
    
    %return_hash = (%return_hash,  %default_hash);
    
    return \%return_hash;
  
}

=head2 _set_run_number()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub _set_run_number {
    return time;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _set_default_hash()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  
  #  Returns:  
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub _set_default_hash {
    my $hash;
    
    $hash = {
             'app'     => "",
             'sev'     => "",
            };
    
    return $hash;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _set_ssm_config_list()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  returns a reference to an array with the list of ssm config prefixes
  #  Returns:  reference to array
  #  Requires: 
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub _set_ssm_config_list {
    my @retval = qw(
      filesys
      fileage
      process
      powerpath
      rotate
    );
    
    return \@retval;
}

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES


probable methods:
: create_config_file(<config prefix>, \%config_entries, $run_number) - return the config file name
: remove_config_file(<config file name>)
: agent_shut_down - return 1 if good
: agent_start_up - return 1 if good
: set_run_number - returns a run number based on epoch time to be used throughout the test to validate information
: get_blank_config_hash(<config prefix>) - returns a blank hash with relative config entries
: _get_common_config_hash - return the default config entries for all configs
: _get_blank_config_<monitor_name> - specific config hash settings - will call _get_common_config_hash
:
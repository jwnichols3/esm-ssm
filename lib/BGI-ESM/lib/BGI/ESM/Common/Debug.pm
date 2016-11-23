
=head1 NAME

BGI ESM Common Shared Debug Methods

=head1 SYNOPSIS

This library is used in most BGI ESM programs to load a common set of debug methods.

=head1 REVISIONS

CVS Revision: $Revision: 1.4 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-09-15   nichj   Getting initial release done
  #  2005-12-07   nichj   Added get_debug_named
  #                        Simplified checking of debug flags
  #####################################################################

=head1 TODO


=cut


#################################################################################
### Package Name ################################################################
package BGI::ESM::Common::Debug;
#################################################################################

#################################################################################
### Module Use Section ##########################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
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
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    opt_debug_flag
    file_debug_flag
    get_debug
    get_debug_named
);
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.4 $)[-1];
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

=head2 opt_debug_flag($opt_debug, $opt_d, $opt_debugextensive)
    Returns ($debug, $debug_extensive) based on the incoming fields
=cut

sub opt_debug_flag {
    my $debug_flag             = shift;
    my $debug_return           = 0;

    if ( $debug_flag ) {
        return 1;
    }
    else {
        return 0;
    }
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 file_debug_flag($debug_file_name, $debugextensive_file_name)
    Returns ($debug, $debug_extensive) based on the presence of the incoming files
=cut

sub file_debug_flag {
    my $DEBUG_FILE             = shift;
    my $debug_return           = 0;
  
    if ( -e $DEBUG_FILE )  {
      
        $debug_return           = 1;
    
    }
  
    return $debug_return;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_debug($opt_debug, $opt_d, $opt_debugextensive, $debug_file_name, $debugextensive_file_name)

    Returns ($debug, $debug_extensive) based on the presence of the incoming files
     or based on the incoming fields
     
=cut

sub get_debug {
    my $debug_flag             = shift;
    my $d_flag                 = shift;
    my $debug_extensive_flag   = shift;
    my $DEBUG_FILE             = shift;
    my $DEBUG_EXTENSIVE_FILE   = shift;
    my $debug_return           = 0;
    my $debug_extensive_return = 0;
    my (
        $debug_flag_set, $debug_extensive_flag_set,
        $debug_file_set, $debug_extensive_file_set,
       );
    
    if ($debug_flag) {
        $debug_flag_set = opt_debug_flag($debug_flag);
    }
    
    if ($d_flag) {
        $debug_flag_set = opt_debug_flag($d_flag);
    }
    
    if ($debug_extensive_flag) {
        $debug_extensive_flag_set = opt_debug_flag($debug_extensive_flag);
    }
    
    if ($DEBUG_FILE) {
        ($debug_file_set) = file_debug_flag($DEBUG_FILE);
    }
    
    if ($DEBUG_EXTENSIVE_FILE) {
        ($debug_extensive_file_set) = file_debug_flag($DEBUG_EXTENSIVE_FILE);
    }
    
    if ( ($debug_flag_set) or ($debug_file_set) ) {
        $debug_return           = 1;
    }
    
    if ( ($debug_extensive_flag_set) or ($debug_extensive_file_set) ) {
        $debug_return           = 1;
        $debug_extensive_return = 1;
    }
    
    return ($debug_return, $debug_extensive_return);
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_debug_named ({ debug=>$debug, d=>$d, debugextensive=$debug_extensive, debug_file=>$debug_file, debug_extensive_file=>$debug_extensive_file })

    use this for a named version of get_debug.  The settings are:
    - debug=>$opt_debug
    - d=>$opt_d
    - debugextensive=$opt_debug_extensive
    - debug_file=>$debug_file_name
    - debug_extensive_file=>$debug_extensive_file_name
    
    returns two flag values: $debug and $debug_extensive
    
=cut

sub get_debug_named {
    my ($arg_ref) = @_;
    
    my $debug_flag                = _set_flag_default($arg_ref->{debug});
    my $d_flag                    = _set_flag_default($arg_ref->{d});
    my $debug_extensive_flag      = _set_flag_default($arg_ref->{debugextensive});
    my $debug_file_flag           = _set_flag_default($arg_ref->{debug_file});
    my $debug_extensive_file_flag = _set_flag_default($arg_ref->{debug_extensive_file});
    
    my ($debug_ret, $debug_extensive_ret)
        = get_debug($debug_flag, $d_flag, $debug_extensive_flag, $debug_file_flag, $debug_extensive_file_flag);

    return ($debug_ret, $debug_extensive_ret);
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 debug_output - under construction

=cut

sub debug_output {
    my ($incoming_variable, $debug_flag, $debug_extensive_flag) = @_;
    
    
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################

sub _set_flag_default {
    my ($incoming_flag) = @_;
    my $BLANK = ''; # single quotes;
    
    if (not $incoming_flag) {
        return $BLANK;
    }
    else {
        return ($incoming_flag);
    }
}


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



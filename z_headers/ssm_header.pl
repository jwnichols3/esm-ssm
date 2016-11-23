=head1 TITLE

Title of program

=head1 DESCRIPTION

Description of program with optins, etc.

=head1 USAGE
  
    filename.pl [ --d[ebug] | --debugextensive | --h[elp] | --v[ersion] | -t[est] ]

    brief description of the program
    
    --d[ebug]        - turn on debug output
    --debugextensive - turn on debug extensive output
    --h[elp]         - display this screen
    --v[ersion]      - display the program version number

=head1 TODO

    Any refactoring work that should happen.

=head1 REVISIONS

CVS Revision: $Revision: 2.512 $

    #####################################################################
    # Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ----------------------------------------
    #  2007-06-13 nichj     Description
    #  2007-07-18 nichj     Added debug to common module list
    #  
    #####################################################################
 
=cut

our $VERSION             = (qw$Revision: 2.512 $)[-1];
my  $version             = "$0 version $VERSION\n";
our $prefix              = "program prefix";
my  $program_description = ""; ## enter a short description of this program

our (
        $opt_v, $opt_version, $opt_h, $opt_help,
        $opt_d, $opt_debug, $opt_debugextensive,
        $opt_t, $opt_test,
    );

# ===========================================================================
# Use Modules
# ===========================================================================
use Getopt::Long;
use strict;
use warnings;
use Carp;
# ---------------------------------------------------------------------------
##### Point the lib to the CVS source location(s)
# ---------------------------------------------------------------------------
use lib "/code/vpo/BGI-ESM/lib";     # Windows: assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX:    assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Debug;

# ===========================================================================
##### Get the additional include locations from BGI::ESM::Common::INC
# ===========================================================================
my $addl_inc = get_include_locations();
push @INC, @{$addl_inc};

# ===========================================================================
# Get Command Line Options
# ===========================================================================
GetOptions(
            "v", "version",
            "h", "help",
            "d", "debug", "debugextensive",
            "t", "test",
          );

# ===========================================================================
# Version Check
# ===========================================================================
if ( $opt_v or $opt_version ) { print "$version";
                                exit 0;           }

# ===========================================================================
# Help Check
# ===========================================================================
if ( $opt_h or $opt_help )    {  usage();
                                 exit 0;          }

# ===========================================================================
# Test check
# ===========================================================================
our $test = test_check($opt_t, $opt_test);

# ===================================================================
# Setup variables
# ===================================================================
our $agt_vars    = agent_variables();
our $ssm_vars    = ssm_variables();
our $server_vars = server_variables();
our $commands    = get_command_hash();

# ===================================================================
# Check debug configuration
# ===================================================================

our $DEBUG_EXTENSIVE_ON = $ssm_vars->{'SSM_CONF'} . "/filename.debugexensive";
our $DEBUG_ON           = $ssm_vars->{'SSM_CONF'} . "/filename.debug";

our ( $debug, $debug_extensive ) = get_debug( $opt_debug, $opt_d, $opt_debugextensive,
                                              $DEBUG_ON, $DEBUG_EXTENSIVE_ON );

# ===========================================================================
# ===========================================================================
# Begining of Main
# ===========================================================================
# ===========================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

#################################################################
## MAIN CODE GOES HERE
#################################################################



exit 0;


# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# ===========================================================================
# ===========================================================================
# End of Main
# ===========================================================================
# ===========================================================================


# ===========================================================================
# Beginning of Functions
# ===========================================================================
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Functions Specific to this program
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# ---------------------------------------------------------------------------
sub usage {
  print '
USAGE:

program.name [ --d[ebug] | --debugextensive | --h[elp] | --v[ersion] | -t[est] ]

brief description of the program

See http://esm/ssm for more information.

--d[ebug]        - turn on debug output
--debugextensive - turn on debug extensive output
--h[elp]         - display this screen
--v[ersion]      - display the program version number
--t[est]         - run the alert checks, but do not send in an alert.
                   log results to $SSM_LOG/ssm-test-fileage.log

Examples:


Notes:

';

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ===========================================================================
# End of Functions
# ===========================================================================

__END__


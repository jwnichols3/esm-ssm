=head1 TITLE

Enter program title here

=head1 DESCRIPTION

Enter description here

=head1 USAGE
  
  Enter usage notes here

=head1 TODO

=head1 REVISIONS

CVS Revision: $Revision: 1.12 $

  #####################################################################
  # Revision History:
  #
  #  Date       Initials Description of Change
  #  ---------- -------- ----------------------------------------
  #  2005-mm-dd userid    
  #  
  #####################################################################
 
=cut

our $VERSION             = (qw$Revision: 1.12 $)[-1];
my  $version             = "$0 version $VERSION\n";

my $program_description = "";

our (
        $opt_v, $opt_version, $opt_h, $opt_help,
        $opt_d, $opt_debug, $opt_debugextensive,
        $opt_t, $opt_test
    );

# ===========================================================================
# Use Modules
# ===========================================================================
use Getopt::Long;
use strict;
use warnings;
use diagnostics;
use Carp;
# ---------------------------------------------------------------------------
##### Point the lib to the CVS source location(s)
# ---------------------------------------------------------------------------
use lib "/code/vpo/BGI-ESM/lib";     # Windows: assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX:    assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;

# ===========================================================================
##### Get the additional include locations from BGI::ESM::Common::INC
# ===========================================================================
my $addl_inc = get_include_locations();
push @INC, @{$addl_inc};

# ===========================================================================
##### Load common methods and variables
# ===========================================================================
require "setvar.pm";
require "ssm_common.pm";
require "all_server_common.pl";

# ===========================================================================
# Get Command Line Options
# ===========================================================================
GetOptions(
            "v", "version",
            "h", "help",
            "d", "debug", "debugextensive",
            "t", "test"
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

# ===========================================================================
# Program Location Variables
# ===========================================================================
our $PGM_ROOT      = "/apps/esm";
our $PGM_CONF      = "$PGM_ROOT/conf";
our $PGM_LOGS      = "$PGM_ROOT/logs";
our $PGM_BIN       = "$PGM_ROOT/bin";
our $PGM_LIB       = "$PGM_ROOT/lib";
our $PGM_DATA_ROOT = "/data/esm";

# ===========================================================================
# Determine Debug settings
# ===========================================================================
## Calling the check_debug_settings will evaluate the command line options and
## the debug files.
## $debug and/or $debug_extensive are set to true if the setting are true

my $DEBUG_FILENAME           = "";  ## Change this to reflect the proper file
my $DEBUG_EXTENSIVE_FILENAME = "";  ## Change this to reflect the proper file
check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");


# ===========================================================================
# ===========================================================================
# Begining of Main
# ===========================================================================
# ===========================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v


###########################################################
###########################################################
##########        Enter Main Code Here        #############
###########################################################
###########################################################


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
# Functions specific to this program (that aren't defined in any library
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
  
Program USAGE:

<program name>
               [ --d[ebug] | --debugextensive |
                 --h[elp]  | --v[ersion]      |
                 --t[est] ]

";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ===========================================================================
# End of Functions
# ===========================================================================


__END__

=head2 DEVELOPER'S NOTES

  
  
=cut

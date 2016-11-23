=head1 TITLE

Enter program title here

=head1 DESCRIPTION

Enter description here

=head1 USAGE
  
    performance.monitor
    
                   [ --d[ebug] | --debugextensive |
                     --h[elp] | --v[ersion] |
                     --t[est] ]

=head1 TODO

=head1 REVISIONS

CVS Revision: $Revision: 1.5 $

  #####################################################################
  # Revision History:
  #
  #  Date       Initials Description of Change
  #  ---------- -------- ----------------------------------------
  #  2005-09-20   nichj  Initial development
  #  
  #  
  #####################################################################
 
=cut

our $VERSION             = (qw$Revision: 1.5 $)[-1];
my  $version             = "$0 version $VERSION\n";

my  $program_description = ""; ## enter a short description of this program
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
use Carp;
use Data::Dumper;
# ---------------------------------------------------------------------------
##### Point the lib to the CVS source location(s)
# ---------------------------------------------------------------------------
use lib "/code/vpo/BGI-ESM/lib";     # Windows: assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX:    assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared;
use BGI::ESM::Common::Network;
use BGI::ESM::SelfService::Performance;

# ===========================================================================
##### Get the additional include locations from BGI::ESM::Common::INC
# ===========================================================================
my $addl_inc = get_include_locations();
push @INC, @{$addl_inc};

# ===================================================================
# Get common variables
# ===================================================================
my $ssm_vars   = ssm_variables();
my $agent_vars = agent_variables();

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
# Determine Debug settings
# ===========================================================================
## Calling the check_debug_settings will evaluate the command line options and
## the debug files.
## $debug and/or $debug_extensive are set to true if the setting are true

our $DEBUG_FILENAME           = $ssm_vars->{'SSM_CONF'} . "/performance.monitor.debug";
our $DEBUG_EXTENSIVE_FILENAME = $ssm_vars->{'SSM_CONF'} . "/performance.monitor.debugextensive";
#check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");


# ===========================================================================
# ===========================================================================
# Begining of Main
# ===========================================================================
# ===========================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

my (
        $stat_time, $last_stat_time, $counter
    );

my $loops        = 1440;
my $sleeptime    = 60;

print "\n=== Capturing Performance Data ===\n";
print "    Sleep time between captures: $sleeptime\n";

for ( $counter = 0; $counter < $loops; $counter++ ) {
    
    if (not $last_stat_time) { $last_stat_time = "starting"; }
    
    print "\n\n==================================\n\n";
    print "Performance Capture via Coda: Loop $counter\n";

    my $perf_record = get_performance_record();
    
    $stat_time = get_record_key($perf_record);
    
    if ($last_stat_time eq $stat_time) {
        
        print "\n\nPerf stat hasn't changed.\n";
        
    }
    else {
    
        my $status = add_record($perf_record);

        if ($status) {

            print "\tLast stat time: $last_stat_time has changed to: $stat_time\n";
            
            $last_stat_time = $stat_time;
        
            print "\nPerformance Metrics for $stat_time\n\n";
            print Dumper ($perf_record);
        }
        else {
            
            print "Unable to add record!\n";

        }
    
    }
    
    print "\nSleeping...\n";
    sleep $sleeptime;
    
}


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

=head2 open_perf_db_file()

=cut



# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# ---------------------------------------------------------------------------
sub usage {
  print "
  
Program USAGE:

performance.monitor

               [ --d[ebug] | --debugextensive |
                 --h[elp] | --v[ersion] |
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

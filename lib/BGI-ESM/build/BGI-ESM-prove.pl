#!/opt/OV/activeperl-5.8/bin/perl

=head1 TITLE

BGI-ESM Module prove script

=head1 DESCRIPTION

This will run prove on all test programs for the BGI::ESM modules

=head1 USAGE
  
    BGI-ESM-prove.pl
    
                   [ --d[ebug] | --debugextensive |
                     --h[elp] | --v[ersion] |
                     --t[est] ]

=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.4 $

  #####################################################################
  # Revision History:
  #
  #  Date       Initials Description of Change
  #  ---------- -------- ----------------------------------------
  #  2005-09-30   nichj  Initial development
  #  
  #  
  #####################################################################
 
=cut

our $VERSION             = (qw$Revision: 1.4 $)[-1];
my  $version             = "$0 version $VERSION\n";

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
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared qw(os_type test_check);

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
# ===========================================================================
# Begining of Main
# ===========================================================================
# ===========================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

my $cmd = "prove";
my ($dir);

if (os_type() eq 'WINDOWS') {
    $dir = "/code/vpo/BGI-ESM/t";
}
else {
    $dir = "/apps/esm/vpo/BGI-ESM/t";
}

my @files = glob "$dir/*.t";

print "\n\nList of files to build:\n";

print Dumper \@files;

foreach my $file (@files) {
    
    my $start_time = time;
    print "\nBuilding $file\n";
    my $status     = `$cmd $file`;
    print "\n\n== Status of the prove: $status\n";
    my $end_time   = time;
    my $spent_time = $end_time - $start_time;
    print "\tIt took " . $spent_time . " to run\n\n";
    
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

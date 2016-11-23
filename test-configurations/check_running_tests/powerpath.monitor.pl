###################################################################
#
#             File: powerpath.monitor.pl
#             NOTE: this is used for looping.  Do not distribute
#         Revision: 1.00
#
#           Author: John Nichols
#
#    Original Date: 2004 Mar 22
#
#      Description: This program is used to test check_running loops
#                   
#           Usage:  powerpath.monitor --repeat_minutes=n --debug
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  2004-09   nichj         <Initial Version>
#
#
#####################################################################

$version = "$0 version 1.00\n";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;
use File::Basename;

# ===================================================================
# Get Command Line Options
# ===================================================================

GetOptions(
            "repeat_minutes:n"   => \$repeat_minutes,
            "t", "test",
            "v", "version",
            "h", "help",
            "d", "debug", "debugextensive"
          );

# ===================================================================
# Version check
# ===================================================================
if ( $opt_v or $opt_version ) { die $version }

if ( $opt_h or $opt_help ) {
  usage();
  die $version;
}

# ===================================================================
# Begining of Main
# ===================================================================

if ( $opt_t or $opt_test ) {
  $debug = 1;
  $test  = 1;
  print "Running in Test Mode\n";
}

print " The current pid is $$\n";

create_loop_process($repeat_minutes);


print "Thank you for using the loop test system.\n\n";

return 1;                                                            # set this up in case this gets distributed.

# ===================================================================
# End of Main
# ===================================================================


# ===================================================================
# Start of FUNCTIONS
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: create_loop_process($repeat_minutes)
#  Creates a loop that lasts for $repeat_minutes
# -------------------------------------------------------------------

sub create_loop_process {
  
  my $sleep_time          = 60;                                      # number of seconds to sleep
  my $sleep_min_default   = 10;                                      # number of minutes to default
  my $i                   = 1;                                       # loop counter
  
  if ( $repeat_minutes eq "" ) { $repeat_minutes = $sleep_min_default; } # set the default sleep if not specified on command line
  
  print "Looping for $repeat_minutes minutes...\n\n";
  
  for ($i = 1; $i <= $repeat_minutes; $i++) {
    
    print " Loop $i\n\n";
    
    sleep $sleep_time;
    
  }

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  The usage information
# -------------------------------------------------------------------
print "

powerpath.monitor --repeat_minutes=n --debug

--repeat_minutes - n is the number of minutes you want this program to loop.

";
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# ===================================================================
# End of FUNCTIONS
# ===================================================================

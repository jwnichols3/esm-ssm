=head1 TITLE

SSM v2 ESM version output

=head1 DESCRIPTION

Use this program to output the version of all SSM2 programs located in the repository

=head1 USAGE

perl ssm2_ver_all.pl [--bin] [--list] [-diff] [--help | --version | --debug | --debugextensive]

  --bin option runs the version output from the compiled versions of the code.
  --list lists all programs
  --diff prints a diff of the source and compiled versions

=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.1 $

  #####################################################################
  #
  #           Author: Nichols, John
  #
  #    Original Date: 2005-08-30
  #
  # Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ----------------------------------------
  #  2005-08-30    nichj  original
  #  2005-08-31    nichj  refactoring to use ssm2_compile.pm
  #  2005-09-01    nichj  getting diff option to work
  #  2005-09-01    nichj  Updated to use BGI::ESM::Compile::Ssm
  #  2005-10-12    nichj  Refactored to leverage new hash
  #####################################################################
 
=cut

our $VERSION             = (qw$Revision: 1.1 $)[-1];
my  $version             = "$0 version $VERSION\n";

our (
     $opt_v, $opt_version, $opt_h, $opt_help, $opt_d, $opt_debug, $opt_debugextensive,
     $opt_dry, $opt_bin, $opt_list, $opt_diff
     );

# =================================================================================
# Use Modules
# =================================================================================
use Getopt::Long;
use strict;
use File::Find;
use Data::Dumper;
# =================================================================================
##### Point the lib to the CVS source location(s)
# =================================================================================
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;
use BGI::ESM::Common::Shared qw(os_type);
use BGI::ESM::Compile::Common;
use BGI::ESM::Compile::Ssm;

# =================================================================================
##### Get the additional include locations from BGI::ESM::Common::INC
# =================================================================================
my $addl_inc = get_include_locations();
push @INC, @{$addl_inc};

# =================================================================================
##### Load common methods and variables
# =================================================================================
require "setvar.pm";
require "ssm_common.pm";

# =================================================================================
# Get Command Line Options
# =================================================================================
GetOptions( "v", "version",
            "h", "help",
            "d", "debug", "debugextensive",
            "bin",
            "list",
            "dry",
            "diff"
          );

# =================================================================================
# Version Check
# =================================================================================
if ( $opt_v or $opt_version ) { print "$version";
                                exit 0;           }

# =================================================================================
# Help Check
# =================================================================================
if ( $opt_h or $opt_help )    {  usage();
                                 exit 0;          }

# =================================================================================
# =================================================================================
# Begining of Main
# =================================================================================
# =================================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

my ($source_dir, $bin_dir, $lib_dir, $doc_dir, $doc_logfile,
    $program_list, $ver_logfile,
    $dry);

#################################
## Dry Run settings #############
$dry = dry_run_settings($opt_dry);

($source_dir, $bin_dir, $lib_dir, $doc_dir) = get_compile_locations();

if (not compile_continue()) {
  die "ERROR!\n";
}

compile_location_summary();

$program_list = get_program_hash();

if ($opt_list) {
  print_program_list();
  print "\nExiting\n";
  exit 0;
}

if ($opt_diff) {
  
  version_compare_all();
  
} else {
  
  foreach my $key (keys %{$program_list}) {
    
    if (compile_check($key)) {
    
      print get_version($key, $opt_bin) . "\n";
      
    }
  }
  
}

print "\nCompleted\n";
exit 0;

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# =================================================================================
# =================================================================================
# End of Main
# =================================================================================
# =================================================================================


# =================================================================================
# Beginning of Functions
# =================================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
=head2 Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
=cut
sub usage {
  print "
  
Program USAGE:

perl ssm2_ver_all.pl [--bin] [--list] [-diff] [--help | --version | --debug | --debugextensive]

  --bin option runs the version output from the compiled versions of the code.
  --list lists all programs
  --diff prints a diff of the source and compiled versions

";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


# =================================================================================
# End of Functions
# =================================================================================
__END__

=head2 DEVELOPER'S NOTES
 

=cut


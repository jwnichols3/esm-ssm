=head1 TITLE

SSM v2 ESM pod2text wrapper for individual programs

=head1 DESCRIPTION

Use this program to produce pod documentation for specific SSM programs.

=head1 USAGE

perl ssm2_doc_indv.pl --p[rogram]=<program name> | --list
                      [--dry] [--debug | --debug_extensive | --help | --version]

  --dry will run this without producing documentation.
  --list will list the programs you can produce documentation for
  --p[rogram]=<program name> is the program you want to produce documentation for

=head1 TODO

Refactor to have source_dir, log_dir, bin_dir, doc_dir set as part of the module.

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
  #  2005-08-31    nichj  Updated to include compile directories in @INC
  #  2005-09-01    nichj  Updated to use BGI::ESM::Compile::Ssm
  #  
  #####################################################################
 
=cut

our $VERSION             = (qw$Revision: 1.1 $)[-1];
my  $version             = "$0 version $VERSION\n";

our ($opt_v, $opt_version, $opt_h, $opt_help, $opt_d, $opt_debug, $opt_debugextensive, $opt_dry, $opt_list, $program);

# =================================================================================
# Use Modules
# =================================================================================
use Getopt::Long;
use strict;
use warnings;
use Carp;
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
#push @INC, ("/apps/esm/vpo/SSM/compile", "c:/code/vpo/SSM/compile");

# =================================================================================
##### Load common methods and variables
# =================================================================================
require "setvar.pm";
require "ssm_common.pm";
#require "ssm2_compile.pm";

# =================================================================================
# Get Command Line Options
# =================================================================================
GetOptions( "v", "version",
            "h", "help",
            "d", "debug", "debugextensive",
            "dry",
            "program:s" => \$program,
            "p:s"       => \$program,
            "list"
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

my (
    $dry, $doc_logfile
    );

#################################
## Dry Run settings #############
$dry = dry_run_settings($opt_dry);

#################################
## List option ##################
if ($opt_list) {
  print_program_list();
  print "\nExiting\n";
  exit 0;
}

#################################
## Can it run ###################
if (not compile_continue()) {
  croak "ERROR!\n";
}

#################################
## Running ######################

compile_location_summary();

$doc_logfile = "ssm2_" . $program . "_doc_indv.log";
open (DOC_LOGFILE, "> $doc_logfile") or warn "Unable to open $doc_logfile: $!\n";
print DOC_LOGFILE "$version\n";
if ($dry) { print DOC_LOGFILE "Dry run!\n"; }
print DOC_LOGFILE "$version";
print DOC_LOGFILE "Starting documentation process for the following:\n";
close DOC_LOGFILE;


doc_pgm($program, $dry, $doc_logfile);


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
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Functions Specific to this program
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
=head2 Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
=cut
sub usage {
  print "
  
Program USAGE:

perl ssm2_doc_all.pl --dry [--debug | --debug_extensive | --help | --version]

  --dry will run this without producing documentation.

";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


# =================================================================================
# End of Functions
# =================================================================================
__END__

=head2 DEVELOPER'S NOTES
 

=cut


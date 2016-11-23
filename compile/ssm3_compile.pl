#!/opt/OV/activeperl-5.8/bin/perl
=head1 TITLE

SSM v2 ESM Compile program - individual components

=head1 DESCRIPTION

Use this program to run SSM compiles on specific SSM v2 modules

=head2 USAGE

    ssm2_compile_indv --p[rogram]=<program exe name> | -list
                  [--dry] [--debug | --debug_extensive | --help | --version]

    --list will list the program that can be compiled
    --p[rogram] will compile the indicated program
    --dry will run it dry with output
    --list will list the program that can be compiled
    --p[rogram] will compile the indicated program

=head1 TODO



=head2 REVISIONS

CVS Revision: $Revision: 1.1 $

  #####################################################################
  #           Author: Nichols, John
  #
  #    Original Date: 2005-08-26
  #
  # Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ----------------------------------------
  #  2005-08-31    nichj  original
  #  2005-08-31    nichj  Updated to include compile directories in @INC
  #  2005-09-01    nichj  Updated to use BGI::ESM::Compile::Ssm
  #
  #####################################################################


=cut

our $VERSION             = (qw$Revision: 1.1 $)[-1];
my  $version             = "$0 version $VERSION\n";

our (
     $opt_v, $opt_version,
     $opt_h, $opt_help,
     $opt_d, $opt_debug, $opt_debugextensive,
     $opt_dry,
     $program,
     $opt_list,
     $opt_checkin
     );

# =================================================================================
# Use Modules
# =================================================================================
use Getopt::Long;
use strict;
use warnings;
use Carp;
#use diagnostics;
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
            "dry",
            "program:s" => \$program,
            "p:s"       => \$program,
            "list",
            "checkin"
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
    $program_list, $compile_logfile, $ver_logfile
    );

#################################
## Dry Run settings #############
my $dry = dry_run_settings($opt_dry);

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

$program_list = get_program_hash();

if (compile_check($program)) {

  $compile_logfile = "ssm2_" . $program . "_compile_indv.log";
  open (COMP_LOGFILE, "> $compile_logfile") or warn "Unable to open $compile_logfile: $!\n";
  print COMP_LOGFILE "$version\n";
  if ($dry) { print COMP_LOGFILE "Dry run!\n"; }
  close COMP_LOGFILE;

  $ver_logfile = "ssm2_" . $program . "_version_indv.log";
  open (VER_LOGFILE, "> $ver_logfile") or warn "Unable to open $ver_logfile: $!\n";
  print VER_LOGFILE "Version listing:\n";
  close VER_LOGFILE;

  my $program_source_file = get_program_source_file($program);

  print "$program compile file is " . $program_source_file;

  if (-e $program_source_file) {
    print " Exists!\n";
    my $compile_status = compile_pgm($program, $dry, $compile_logfile, $opt_checkin);
    write_log($compile_logfile, $compile_status);
    version_print($program) if ($compile_status);

  }
  else {

    print " *Not* able to find $program.\n";

  }

}
else {

  print "It appears this program should *not* be compiled\n";

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
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Functions Specific to this program
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
=head2 compile_pgm($exe_file, $file_to_compile, $dry)

=cut

=head2 Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------

=cut
sub usage {
  print "

Program USAGE:

ssm3_compile --p[rogram]=<program exe name> | -list
                  [--dry] [--debug | --debug_extensive | --help | --version]

";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


# =================================================================================
# End of Functions
# =================================================================================
__END__

=head2 DEVELOPER'S NOTES



=cut


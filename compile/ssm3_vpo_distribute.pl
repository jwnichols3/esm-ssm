=head1 TITLE

SSM v2 VPO Distribution Program (run on VPO server(s))

=head1 DESCRIPTION

Use this program to copy programs to respective distribution directories.

=head1 USAGE

 perl ssm2_vpo_distribute.pl --p[rogram]=<program_name | all> --os=<unix | windows | all>
                             --type=<agent_type | all>
                             --list
                             [--dry]
                             [ --d[ebug] | --debugextensive |
                               --h[elp]  | --v[ersion]
                               --t[est] ]

  --list will list the programs you can copy to distribution directories
  --p[rogram]=<program name | all> is the program you want to copy to the respective
     distribution directories (defaults to all)
  --os=<solaris | windows | all> - which OS to copy files to distribution dir
     (defaults to all)
  --type=<dce | https | all> - which agent type to copy files to the respective
     distribution direcotyr (defaults to all) - NOTE: HTTPS only works on VPO8
  --dry will run this without copying files.

=head1 TODO



=head1 REVISIONS

CVS Revision: $Revision: 1.1 $

  #####################################################################
  # Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ----------------------------------------
  #  2005-09-06    nichj  original
  #  2005-09-07    nichj  Refactoring and getting ready.
  #####################################################################
 
=cut

our $VERSION             = (qw$Revision: 1.1 $)[-1];
my  $version             = "$0 version $VERSION\n";

our (
        $opt_v, $opt_version, $opt_h, $opt_help,
        $opt_d, $opt_debug, $opt_debugextensive,
        $opt_t, $opt_test,
        $opt_dry,
        $opt_list,
        @os, @type, @program,
        $os, $type, $program
    );

# =================================================================================
# Use Modules
# =================================================================================
use Getopt::Long;
use strict;
use warnings;
use File::Find;
use Data::Dumper;
use Carp;
# =================================================================================
##### Point the lib to the CVS source location(s)
# =================================================================================
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;
use BGI::ESM::Common::Shared qw(os_type);
use BGI::ESM::Compile::Common;
use BGI::ESM::Compile::Ssm;
use BGI::ESM::Compile::VpoDistribute;

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
GetOptions(
            "v", "version",
            "h", "help",
            "d", "debug", "debugextensive",
            "t", "test",
            "dry",
            "list",
            "os:s"      => \@os,
            "program:s" => \@program,
            "p:s"       => \@program,
            "type:s"    => \@type
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

my  (
        $logfile, $LOGFILE
    );

#################################
## Dry Run settings #############
my $dry = dry_run_settings($opt_dry);

#################################
## Validate the Environment #####
##  skip if dry run #############
if (not $dry) {
    if (not distribute_continue()) {
      croak "ERROR! Unable to continue.";
    }
}
#################################
## Print Dist Summary ###########
distribute_location_summary();

#################################
## List programs ################
if ($opt_list) {
  print_program_list();
  print "\nExiting\n";
  exit 0;
}

#################################
## Set Defaults #################
if ( (not @os)      or ($os[0] eq "")      or (lc $os[0] eq "all") )      {
    $os      = get_all_os_distrib();
    @os      = @{$os};
}
if ( (not @program) or ($program[0] eq "") or (lc $program[0] eq "all") ) {
    $program = get_all_distrib();
    @program = @{$program};
}
if ( (not @type)    or ($type[0] eq "")    or (lc $type[0] eq "all") )  {
    $type    = get_all_type_distrib();
    @type    = @{$type};
}



### Pseudo:
#    For each OS, each TYPE, and each Program
#    Remove the associated distribution program
#    if not dry, 
#     Copy source -> distribution
#

if ($dry) {
    print "\nDry Run!!!\n";
    print "\nOS list:\n";
    print "@os";
    
    print "\nProgram list:\n";
    print "@program";
    
    print "\nType list:\n";
    print "@type";
    
}

#################################
## Logfile initialzation ########
$logfile = "ssm2_vpo_distribute.log";
open ($LOGFILE, "> $logfile") or carp("Unable to open $logfile: $!\n");
print $LOGFILE "$version\n";
if ($dry) { print $LOGFILE "Dry run!\n"; }
print $LOGFILE "Starting distribute process.\n";
close $LOGFILE;

my ($fail_hash);

foreach my $os_item (@os) {
    
    foreach my $type_item (@type) {
        
        foreach my $program_item (@program) {
            
			my $status = copy_distrib($program_item, $os_item, $type_item, $logfile, $dry);
		
			if (not $status) {
				$fail_hash->{$program_item}->{$type_item}->{$os_item} = $program_item;
			}
            
        }
        
    }
    
}

if ($fail_hash) {
    print "\n\nThe following items were not successful:\n\n";
    print Dumper ($fail_hash);
}
else {
    print "\n\nAll programs processed!\n\n";
    
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

sub usage {
  print '
  
Program USAGE:

 perl ssm2_vpo_distribute.pl --p[rogram]=<program_name | all> --os=<os | all>
                             --type=<agent_type | all>
                             --list
                             [--dry]
                             [ --d[ebug] | --debugextensive |
                               --h[elp]  | --v[ersion]
                               --t[est] ]

  --list will list the programs you can copy to distribution directories
  --p[rogram]=<program name | all> is the program you want to copy to the respective
     distribution directories (defaults to all)
  --os=<solaris | windows | all> - which OS to copy files to distribution dir
     (defaults to all)
  --type=<dce | https | all> - which agent type to copy files to the respective
     distribution directory (defaults to all) - NOTE: HTTPS only works on VPO8
  --dry will run this without copying files.

';

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


# =================================================================================
# End of Functions
# =================================================================================
__END__

=head2 DEVELOPER'S NOTES
 

=cut


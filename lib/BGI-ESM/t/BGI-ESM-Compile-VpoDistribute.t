=head1 NAME

Test module for BGI ESM Compile SSM modules

=head1 SYNOPSIS

This is test suite for BGI::ESM::Compile::VpoDistribute

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.25 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-09-06   nichj   Developing release 1
  #  2005-11-22   nichj   Added get_agent_types method
  #####################################################################

=head1 TODO

- Write tests for the following:
  : cvs_commit
	
=cut

#########################

use warnings;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Getopt::Long;

use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Compile::Ssm;
use BGI::ESM::Compile::Common;
use BGI::ESM::Common::Shared qw(os_type);

# =============================================================================
# Get Command Line Options
# =============================================================================
our ($opt_notdry);
GetOptions(
            "notdry"
          );


my @subs = qw(

    distribute_continue
    get_agent_types
    get_distribute_dirs
    distribute_location_summary
    print_distribute_dirs
    print_distribute_file_list
    get_all_distrib
    get_all_os_distrib
    get_all_type_distrib
    get_destination_file_name
    get_from_file_name
    get_distrib_dest_file_name
    copy_distrib
);

BEGIN { use_ok('BGI::ESM::Compile::VpoDistribute', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'distribute_continue');
can_ok( __PACKAGE__, 'get_agent_types');
can_ok( __PACKAGE__, 'get_distribute_dirs');
can_ok( __PACKAGE__, 'distribute_location_summary');
can_ok( __PACKAGE__, 'print_distribute_dirs');
can_ok( __PACKAGE__, 'print_distribute_file_list');
can_ok( __PACKAGE__, 'get_all_distrib');
can_ok( __PACKAGE__, 'get_all_os_distrib');
can_ok( __PACKAGE__, 'get_all_type_distrib');
can_ok( __PACKAGE__, 'get_destination_file_name');
can_ok( __PACKAGE__, 'get_from_file_name');
can_ok( __PACKAGE__, 'get_distrib_dest_file_name');
can_ok( __PACKAGE__, 'copy_distrib');


##############################################
## get_distribute_dirs #######################

my $distrib_dirs_expected = {
    'UNIX'    => {
                  'DCE'   => "/var/opt/OV/share/databases/OpC/mgd_node/customer/sun/sparc/solaris/cmds",
                  'HTTPS' => "/var/opt/OV/share/databases/OpC/mgd_node/customer/sun/sparc/solaris7/cmds",
                  'BIN'   => "/apps/esm/vpo/SSM/bin/solaris"
                 },

    'LINUX'   => {
                  'DCE'   => "/var/opt/OV/share/databases/OpC/mgd_node/customer/linux/intel/linux24/cmds",
                  'HTTPS' => "/var/opt/OV/share/databases/OpC/mgd_node/customer/linux/x86/linux24/cmds",
                  'BIN'   => "/apps/esm/vpo/SSM/bin/linux"
                 },

    'WINDOWS' => {
                  'DCE'   => "/var/opt/OV/share/databases/OpC/mgd_node/customer/ms/intel/nt/cmds",
                  'HTTPS' => "/var/opt/OV/share/databases/OpC/mgd_node/customer/ms/x86/winnt/cmds",
                  'BIN'   => "/apps/esm/vpo/SSM/bin/windows"
                 }
};

my $distrib_dirs_got = get_distribute_dirs();

is_deeply ($distrib_dirs_expected, $distrib_dirs_got, 'get_distribute_dirs( ) should return location of distribution directories');

##############################################
## distribute_continue() #######################

if (not distribute_continue()) {
    carp("This doesn't look like a VPO server or some other issue exists.");
}
else {
    print "This systems is okay to distribute.\n";
}

##############################################
## distribute_location_summary ###############
print "\n\ndistribute location summary\n\n";
distribute_location_summary();

##############################################
## print_distribute_dirs #####################
print "\n\nprint distribute dirs\n\n";
print_distribute_dirs();

##############################################
## print_distribute_file_list #####################
print "\n\ndistribute file list\n\n";
print_distribute_file_list();

##############################################
## get all defaults ##########################
print "\n\nGetting all defaults\n\n";
my $all_os      = get_all_os_distrib();      
my $all_program = get_all_distrib(); 
my $all_type    = get_all_type_distrib();

print "\n== All OS\n";
print Dumper ($all_os);

print "\n== All Programs\n";
print Dumper ($all_program);

print "\n== All Type\n";
print Dumper ($all_type);


##############################################
## get_from_file_name ########################

my $from_fn = get_from_file_name('fileage.monitor', 'WINDOWS', 'HTTPS');

print "From file name: $from_fn\n";

##############################################
## get_destination_file_name #################

my $dest_fn = get_destination_file_name('fileage.monitor', 'WINDOWS', 'HTTPS');

print "Destination file name: $dest_fn\n";

###############################################
### get_all_programs_hash #####################
#my $all_programs_win_got = get_all_programs_hash('WINDOWS');
#my $all_programs_sol_got = get_all_programs_hash('UNIX');
#
#print "\nGet All Programs Hash\n";
#
#print "\nAll programs hash: WINDOWS:\n";
#print Dumper ($all_programs_win_got);
#
#print "\nAll programs hash: UNIX:\n";
#print Dumper ($all_programs_sol_got);

###############################################
### get_bin_file_name #########################
#my $bin_file_name_got = get_bin_file_name('fileage.monitor', 'WINDOWS');
#print "bin file name: $bin_file_name_got\n";

##############################################
## copy_distrib ##############################
print "\n\nChecking copy_distrib\n";
print "Running in dry mode\n";
my $dry_copy_distrib     = "true";
my $copy_distrib_logfile = "copy_distrib_temp.txt";
my $copy_distrib_logfile_real = "copy_distrib_real.txt";
my ($fail_hash, $fail_hash_real);

open (my $REAL, ">", $copy_distrib_logfile_real) or carp "Problem opening $copy_distrib_logfile_real: $!\n";

my @types    = qw(DCE HTTPS);
my @oses     = qw(WINDOWS UNIX);

my $program_list = get_program_hash();

foreach my $os_item (@oses) {
		
	foreach my $type_item (@types) {
			
		foreach my $program_item (keys %{$program_list}) {

			print "Running for os: $os_item, type: $type_item, program: $program_item\n";

			my $status = copy_distrib($program_item, $os_item, $type_item, $copy_distrib_logfile, $dry_copy_distrib);
		
			is ($status, 1, 'copy_distrib( ) should return 1 if successful: ' . $program_item);
			
			if (not $status) {
				$fail_hash->{$program_item}->{$type_item}->{$os_item} = $program_item;
			}
		
			if ( (os_type() eq 'UNIX') and ($opt_notdry) ) {
				print "Running Copy Distrib for real!\n";
				my $status = copy_distrib($program_item, $os_item, $type_item, $copy_distrib_logfile_real);
				is ($status, 1, 'copy_distrib( ) should return 1 if successful: ' . $program_item);
				
				if (not $status) {
					$fail_hash_real->{$program_item}->{$type_item}->{$os_item} = $program_item;
				}
				
			}

			
		}
		
	}
}

print "\n\nThe following failed the copy_distrib DRY RUN:\n\n";

print Dumper ($fail_hash);

if ($fail_hash_real) {
	print "\n\nThe following failed the copy_distrib REAL RUN:\n\n";

	print Dumper ($fail_hash_real);
}

#############################################
#############################################
print "\nGET AGENT TYPES\n";
my $agent_types = get_agent_types();
print Dumper $agent_types;

#############################################
## get_type_available #######################

#my $type_available_got = get_type_available();
#
#print "\n @{$type_available_got} \n";

#####################################
## post-processing clean up #########
#####################################



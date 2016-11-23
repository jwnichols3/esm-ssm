
=head1 NAME

Test module for BGI ESM Compile VpoServer modules

=head1 SYNOPSIS

This is test suite for BGI::ESM::Compile::VpoServer

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.8 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-08-26   nichj   Developing release 1
  #  2005-10-27   nichj   Adding Linux checks
  #####################################################################

=head1 TODO

- Write tests for the following:
    : cvs_commit
	
=cut


use warnings;
use strict;
use Data::Dumper;
#use Net::Nslookup;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type);
use BGI::ESM::Compile::Common;

$Data::Dumper::Sortkeys = 1;

my @subs = qw(
    compile_check
    compile_continue
    compile_location_summary
    compile_pgm
    copy_program
    doc_check
    doc_pgm
    get_all_programs
    get_bin_base_file_name
    get_bin_name_with_compile_path
    get_bin_name_with_cvs_path
    get_bin_version
    get_compile_locations
    get_cvs_locations
    get_doc_file_name
    get_etc_locations
    get_exe_extension
    get_program_exe_list_os
    get_program_hash
    get_program_list
    get_program_source_file
    get_source_version
    get_version
	is_executable
    print_program_list
    version_compare
    version_compare_all
    version_print
);

BEGIN { use_ok('BGI::ESM::Compile::VpoServer', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'compile_check');
can_ok( __PACKAGE__, 'compile_continue');
can_ok( __PACKAGE__, 'compile_location_summary');
can_ok( __PACKAGE__, 'compile_pgm');
can_ok( __PACKAGE__, 'copy_program');
can_ok( __PACKAGE__, 'doc_check');
can_ok( __PACKAGE__, 'doc_pgm');
can_ok( __PACKAGE__, 'get_all_programs');
can_ok( __PACKAGE__, 'get_bin_base_file_name');
can_ok( __PACKAGE__, 'get_bin_name_with_compile_path');
can_ok( __PACKAGE__, 'get_bin_name_with_cvs_path');
can_ok( __PACKAGE__, 'get_bin_version');
can_ok( __PACKAGE__, 'get_compile_locations');
can_ok( __PACKAGE__, 'get_cvs_locations');
can_ok( __PACKAGE__, 'get_exe_extension');
can_ok( __PACKAGE__, 'get_program_exe_list_os');
can_ok( __PACKAGE__, 'get_program_hash');
can_ok( __PACKAGE__, 'get_program_list');
can_ok( __PACKAGE__, 'get_program_source_file');
can_ok( __PACKAGE__, 'get_source_version');
can_ok( __PACKAGE__, 'get_version');
can_ok( __PACKAGE__, 'is_executable');
can_ok( __PACKAGE__, 'print_program_list');
can_ok( __PACKAGE__, 'version_compare');
can_ok( __PACKAGE__, 'version_compare_all');
can_ok( __PACKAGE__, 'version_print');

###############################################################################
## main tests #################################################################
###############################################################################


#####################################
## establish test vars ##############
my @oses         = qw(WINDOWS UNIX);
my $program_hash = get_program_hash();
my @types        = qw(DCE HTTPS);

#####################################
## dry_run_settings #################
print "\nDry run settings\n";
my $opt_dry_on  = 1;
my $dry_get_on  = dry_run_settings($opt_dry_on);
is ($dry_get_on, 1, 'dry_run_settings($opt_dry) should return 1 if $opt_dry is true.');

my $opt_dry_off = 0;
my $dry_get_off = dry_run_settings($opt_dry_off);
is ($dry_get_off, 0, 'dry_run_settings($opt_dry) should return 0 if $opt_dry is false.');

#####################################
## get_cvs_locations ################
print "\nGet CVS locations\n";
my $cvsroot_windows = "c:/code/vpo";
my $cvsroot_unix    = "/apps/esm/vpo";
my $cvsroot_linux   = "/apps/esm/vpo";
my $cvsroot_expected_win = {
                   'CVSROOT'     => "$cvsroot_windows",
                   'BIN'         => "$cvsroot_windows/vpo_server/bin",
                   'ETC'         => "$cvsroot_windows/vpo_server/etc",
                   'SRC'         => "$cvsroot_windows/vpo_server/src",
                   'DOC'         => "$cvsroot_windows/vpo_server/doc",
                   'SQL'         => "$cvsroot_windows/vpo_server/sql",
                   'LIB'         => "$cvsroot_windows/BGI-ESM/lib",
                   'PL_LIB'      => "$cvsroot_windows/vpo_server/lib",
                   'BIN_UNIX'    => "$cvsroot_windows/vpo_server/bin/solaris",
                   'BIN_LINUX'   => "$cvsroot_windows/vpo_server/bin/linux",
                   'BIN_WINDOWS' => "$cvsroot_windows/vpo_server/bin/windows",
                   'ETC_UNIX'    => "$cvsroot_windows/vpo_server/etc/solaris",
                   'ETC_LINUX'   => "$cvsroot_windows/vpo_server/etc/linux",
                   'ETC_WINDOWS' => "$cvsroot_windows/vpo_server/etc/windows"
                    };

my $cvsroot_expected_sol = {
                   'CVSROOT'         => "$cvsroot_unix",
                   'BIN'         => "$cvsroot_unix/vpo_server/bin",
                   'ETC'         => "$cvsroot_unix/vpo_server/etc",
                   'SRC'         => "$cvsroot_unix/vpo_server/src",
                   'DOC'         => "$cvsroot_unix/vpo_server/doc",
                   'SQL'         => "$cvsroot_unix/vpo_server/sql",
                   'LIB'         => "$cvsroot_unix/BGI-ESM/lib",
                   'PL_LIB'      => "$cvsroot_unix/vpo_server/lib",
                   'BIN_UNIX'    => "$cvsroot_unix/vpo_server/bin/solaris",
                   'BIN_LINUX'   => "$cvsroot_unix/vpo_server/bin/linux",
                   'BIN_WINDOWS' => "$cvsroot_unix/vpo_server/bin/windows",
                   'ETC_UNIX'    => "$cvsroot_unix/vpo_server/etc/solaris",
                   'ETC_LINUX'   => "$cvsroot_unix/vpo_server/etc/linux",
                   'ETC_WINDOWS' => "$cvsroot_unix/vpo_server/etc/windows"
                    };

my $cvsroot_expected_lin = {
                   'CVSROOT'         => "$cvsroot_linux",
                   'BIN'         => "$cvsroot_linux/vpo_server/bin",
                   'ETC'         => "$cvsroot_linux/vpo_server/etc",
                   'SRC'         => "$cvsroot_linux/vpo_server/src",
                   'DOC'         => "$cvsroot_linux/vpo_server/doc",
                   'SQL'         => "$cvsroot_linux/vpo_server/sql",
                   'LIB'         => "$cvsroot_linux/BGI-ESM/lib",
                   'PL_LIB'      => "$cvsroot_linux/vpo_server/lib",
                   'BIN_UNIX'    => "$cvsroot_linux/vpo_server/bin/solaris",
                   'BIN_LINUX'   => "$cvsroot_linux/vpo_server/bin/linux",
                   'BIN_WINDOWS' => "$cvsroot_linux/vpo_server/bin/windows",
                   'ETC_UNIX'    => "$cvsroot_linux/vpo_server/etc/solaris",
                   'ETC_LINUX'   => "$cvsroot_linux/vpo_server/etc/linux",
                   'ETC_WINDOWS' => "$cvsroot_linux/vpo_server/etc/windows"
                    };

my $cvsroot_got_win      = get_cvs_locations('WINDOWS');
my $cvsroot_got_sol      = get_cvs_locations('UNIX');
my $cvsroot_got_lin      = get_cvs_locations('LINUX');

is_deeply($cvsroot_got_win, $cvsroot_expected_win, 'get_cvs_locations( WINDOWS ) should return a hash with the cvs location.');
is_deeply($cvsroot_got_sol, $cvsroot_expected_sol, 'get_cvs_locations(  UNIX   ) should return a hash with the cvs location.');
is_deeply($cvsroot_got_lin, $cvsroot_expected_lin, 'get_cvs_locations(  LINUX  ) should return a hash with the cvs location.');

#####################################
## get_program_hash #################
### Note: pulled from variable establishment.
print "\nGet Program Hash\n";
is_deeply ($program_hash, $program_hash, 'get_program_hash( ) returns the list of all programs in a multilayer hash.');

my $status = print_program_list();

is ($status, 1, 'print_program_list( ) should print the list of valid programs then return 1');


#####################################
## get_etc_locations($os) ###########
print "\nGet ETC Locations\n";
my $etc_location_win = get_etc_locations('WINDOWS');
my $etc_location_sol = get_etc_locations('UNIX');
my $etc_location_lin = get_etc_locations('LINUX');

print "\n\nConfig etc location source dir WINDOWS: $etc_location_win\n";
print   "\nConfig etc location source dir UNIX:    $etc_location_sol\n";
print   "\nConfig etc location source dir LINUX:   $etc_location_lin\n";

is ($etc_location_win, $etc_location_win, 'get_etc_location( OS ) will return the configuration file source location');
is ($etc_location_sol, $etc_location_sol, 'get_etc_location( OS ) will return the configuration file source location');
is ($etc_location_lin, $etc_location_lin, 'get_etc_location( OS ) will return the configuration file source location');


#####################################
## doc_check #######################
print "\n\nRunning doc_check routine\n\n";
foreach my $doc_item (sort keys %{$program_hash}) {
    
    my $should_doc_got = doc_check($doc_item);
    
    if ($should_doc_got) {
        print "\tDocument $doc_item: YES\n";
        is ($should_doc_got, 1, 'doc_check( $program ) will return a 1 if the program should be documented.');
    }
    else {
        print "\tDocument $doc_item: NO\n";
        is ($should_doc_got, 0, 'doc_check( $program ) will return a 0 if the program should *not* be documented.');
    }
    
    print "\n";
    
}

#####################################
## compile_check #######################
print "\n\nRunning compile_check routine\n\n";
foreach my $compile_item (sort keys %{$program_hash}) {
    
    my $should_compile_got = compile_check($compile_item);
    
    if ($should_compile_got) {
        print "\tCompile $compile_item: YES\n";
        is ($should_compile_got, 1, 'compile_check( $program ) will return a 1 if the program should be compiled.');
    }
    else {
        print "\tDocument $compile_item: NO\n";
        is ($should_compile_got, 0, 'compile_check( $program ) will return a 0 if the program should *not* be compiled.');
    }
    
    print "\n";
    
}

#####################################
## get_doc_file_name ################
print "\n\nProcessing get_doc_file_name\n\n";

foreach my $doc_fn (sort keys %{$program_hash}) {
    
    my $doc_file_name = get_doc_file_name($doc_fn);
    
    if ($doc_file_name) {
        print "\tDoc file name for $doc_fn: $doc_file_name\n";
    }
    else {
        print "\tUnable to determine doc file name\n";
    }
    
}

#####################################
## get_bin_base_file_name ###########
print "\n\nProcessing get_bin_base_file_name with current os\n\n";

foreach my $bin_fn (sort keys %{$program_hash}) {
    
    my $bin_file_name = get_bin_base_file_name($bin_fn);
    
    if ($bin_file_name) {
        print "\tBin file name for $bin_fn: $bin_file_name\n";
    }
    else {
        print "\tUnable to determine bin file name for $bin_fn\n";
    }
    
}


#####################################
## get_bin_name_with_compile_path ###
print "\n\nProcessing get_bin_name_with_compile_path\n\n";

foreach my $os (@oses) {
    
    print "\n\n\tGetting bin names for $os\n\n";
    
    foreach my $bin_comp_fn (sort keys %{$program_hash}) {

        my $bin_comp_file_name = get_bin_name_with_compile_path($bin_comp_fn, $os);
        
        if ($bin_comp_file_name) {
            print "\tBin file name for $bin_comp_fn: $bin_comp_file_name\n";
        }
        else {
            print "\tUnable to determine bin file name for $bin_comp_fn\n";
        }
    
    }
}

#####################################
## get_bin_name_with_cvs_path #######
print "\n\nget_bin_name_with_cvs_path\n";

my $bin_cvs_file_win = get_bin_name_with_cvs_path('nodestatus.delta', 'WINDOWS');
print "nodestatus.delta on WINDOWS: " . $bin_cvs_file_win . "\n";

my $bin_cvs_file_sol = get_bin_name_with_cvs_path('nodestatus.delta', 'UNIX');
print "nodestatus.delta on  UNIX  : " . $bin_cvs_file_sol . "\n";

my $bin_cvs_file_lin = get_bin_name_with_cvs_path('nodestatus.delta', 'LINUX');
print "nodestatus.delta on  LINUX : " . $bin_cvs_file_lin . "\n";


#############################################
#############################################
CVS_COMMIT:
{
	print "\nTODO: Write cvs commit test!\n\n";
    my $cvs_commit_status = "";
	
	
}

#############################################
#############################################
GET_PROGRAM_LIST_OS:
{
    print "\n\nGet Program List for an OS\n\n";
	my $program_list_os_win = get_program_exe_list_os('WINDOWS');
	my $program_list_os_sol = get_program_exe_list_os('UNIX');
	my $program_list_os_lin = get_program_exe_list_os('LINUX');
    
	print "\nProgram list for Windows\n\n";
	print Dumper ($program_list_os_win);
	print "\nProgram list for Solaris\n\n";
	print Dumper ($program_list_os_sol);
	print "\nProgram list for LINUX\n\n";
	print Dumper ($program_list_os_lin);
	
}

GET_PROGRAM_LIST:
{
    print "\n\nGet Program List\n\n";
    my $program_list = get_program_list();
    
    print Dumper ($program_list);
    
}

#############################################
#############################################
IS_EXECUTABLE:
{
    print "\n\nIs Executable\n\n";

	my $program = "TTI";
	
	my $check = is_executable($program);
	
	is ($check, 1, 'is_executable( $program ) should return 1 if the program is executable: ' . $program);
	
	$program = "ToSC_pmo.map";
	
	$check = is_executable($program);
	
	is ($check, 0, 'is_executable( $program ) should return 0 if the program is NOT executable: ' . $program);
	
	
	
}

#####################################
## post-processing clean up #########
#####################################



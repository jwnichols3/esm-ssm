
=head1 NAME

Test module for BGI ESM Compile SSM modules

=head1 SYNOPSIS

This is test suite for BGI::ESM::Compile::Ssm

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.17 $
    Date:     $Date: 2005/10/27 20:05:18 $

    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2005-08-26   nichj   Developing release 1
    #  2005-09-27   nichj   Refactoring to split common methods into
    #                        BGI::ESM::Compile::Common
    #  2005-10-27   nichj   Added Linux logic
    #####################################################################

=head1 TODO

- Write tests for the following:
	
=cut

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BGI-ESM-Common-Shared.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
use Test::More 'no_plan';

use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Compile::Common;
use BGI::ESM::Common::Shared qw(os_type);

$Data::Dumper::Sortkeys = 1;

my @subs = qw(
    compile_check
    compile_continue
    compile_location_summary
    compile_pgm
    doc_check
    doc_pgm
    get_bin_base_file_name
    get_bin_name_with_compile_path
    get_bin_name_with_cvs_path
    get_bin_version
    get_compile_locations
    get_compile_settings
    get_cvs_locations
    get_doc_file_name
    get_etc_locations
    get_exe_extension
    get_program_exe_list_os
    get_program_hash
    get_program_source_file
    get_source_version
    get_version
    print_program_list
    version_compare
    version_compare_all
    version_print
);

BEGIN { use_ok('BGI::ESM::Compile::Ssm', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'compile_check');
can_ok( __PACKAGE__, 'compile_continue');
can_ok( __PACKAGE__, 'compile_location_summary');
can_ok( __PACKAGE__, 'compile_pgm');
can_ok( __PACKAGE__, 'doc_check');
can_ok( __PACKAGE__, 'doc_pgm');
can_ok( __PACKAGE__, 'get_bin_base_file_name');
can_ok( __PACKAGE__, 'get_bin_name_with_compile_path');
can_ok( __PACKAGE__, 'get_bin_name_with_cvs_path');
can_ok( __PACKAGE__, 'get_bin_version');
can_ok( __PACKAGE__, 'get_compile_locations');
can_ok( __PACKAGE__, 'get_compile_settings');
can_ok( __PACKAGE__, 'get_cvs_locations');
can_ok( __PACKAGE__, 'get_doc_file_name');
can_ok( __PACKAGE__, 'get_etc_locations');
can_ok( __PACKAGE__, 'get_exe_extension');
can_ok( __PACKAGE__, 'get_program_exe_list_os');
can_ok( __PACKAGE__, 'get_program_hash');
can_ok( __PACKAGE__, 'get_program_source_file');
can_ok( __PACKAGE__, 'get_source_version');
can_ok( __PACKAGE__, 'get_version');
can_ok( __PACKAGE__, 'print_program_list');
can_ok( __PACKAGE__, 'version_compare');
can_ok( __PACKAGE__, 'version_compare_all');
can_ok( __PACKAGE__, 'version_print');


###############################################################################
## main tests #################################################################
###############################################################################

print "\n\nTesting Functions\n\n";

#####################################
## establish test vars ##############
my @oses         = qw(WINDOWS UNIX LINUX);
my $program_hash = get_program_hash();
my @types        = qw(DCE HTTPS);


#####################################
#####################################
COMPILE_CONINUE:
{
    print "\n==Compile Continue\n";
    my $status = compile_continue();
    
    is($status, 1, 'compile_continue( ) should return 1 if okay to compile.');
}

#####################################
## get_cvs_locations ################
GET_CVS_LOCATIONS:
{
    print "\n==Get CVS locations\n";
    my $cvsroot_windows = "c:/code/vpo";
    my $cvsroot_unix    = "/apps/esm/vpo";
    my $cvsroot_linux   = "/apps/esm/vpo";

    my $cvsroot_expected_win = {
                       'CVSROOT'         => "$cvsroot_windows",
                       'SSM_BIN'         => "$cvsroot_windows/SSM/bin",
                       'SSM_ETC'         => "$cvsroot_windows/SSM/etc",
                       'SSM_SRC'         => "$cvsroot_windows/SSM/src",
                       'SSM_DOC'         => "$cvsroot_windows/SSM/doc",
                       'SSM_LIB'         => "$cvsroot_windows/BGI-ESM/lib",
                       'SSM_BIN_UNIX'    => "$cvsroot_windows/SSM/bin/solaris",
                       'SSM_BIN_LINUX'   => "$cvsroot_windows/SSM/bin/linux",
                       'SSM_BIN_WINDOWS' => "$cvsroot_windows/SSM/bin/windows",
                       'SSM_ETC_UNIX'    => "$cvsroot_windows/SSM/etc/solaris",
                       'SSM_ETC_LINUX'   => "$cvsroot_windows/SSM/etc/linux",
                       'SSM_ETC_WINDOWS' => "$cvsroot_windows/SSM/etc/windows"
                        };
    
    my $cvsroot_expected_sol = {
                       'CVSROOT'         => "$cvsroot_unix",
                       'SSM_BIN'         => "$cvsroot_unix/SSM/bin",
                       'SSM_ETC'         => "$cvsroot_unix/SSM/etc",
                       'SSM_SRC'         => "$cvsroot_unix/SSM/src",
                       'SSM_DOC'         => "$cvsroot_unix/SSM/doc",
                       'SSM_LIB'         => "$cvsroot_unix/BGI-ESM/lib",
                       'SSM_BIN_UNIX'    => "$cvsroot_unix/SSM/bin/solaris",
                       'SSM_BIN_LINUX'   => "$cvsroot_unix/SSM/bin/linux",
                       'SSM_BIN_WINDOWS' => "$cvsroot_unix/SSM/bin/windows",
                       'SSM_ETC_UNIX'    => "$cvsroot_unix/SSM/etc/solaris",
                       'SSM_ETC_LINUX'   => "$cvsroot_unix/SSM/etc/linux",
                       'SSM_ETC_WINDOWS' => "$cvsroot_unix/SSM/etc/windows"
                        };

    my $cvsroot_expected_lin = {
                       'CVSROOT'         => "$cvsroot_linux",
                       'SSM_BIN'         => "$cvsroot_linux/SSM/bin",
                       'SSM_ETC'         => "$cvsroot_linux/SSM/etc",
                       'SSM_SRC'         => "$cvsroot_linux/SSM/src",
                       'SSM_DOC'         => "$cvsroot_linux/SSM/doc",
                       'SSM_LIB'         => "$cvsroot_linux/BGI-ESM/lib",
                       'SSM_BIN_UNIX'    => "$cvsroot_linux/SSM/bin/solaris",
                       'SSM_BIN_LINUX'   => "$cvsroot_linux/SSM/bin/linux",
                       'SSM_BIN_WINDOWS' => "$cvsroot_linux/SSM/bin/windows",
                       'SSM_ETC_UNIX'    => "$cvsroot_linux/SSM/etc/solaris",
                       'SSM_ETC_LINUX'   => "$cvsroot_linux/SSM/etc/linux",
                       'SSM_ETC_WINDOWS' => "$cvsroot_linux/SSM/etc/windows"
                        };
    
    my $cvsroot_got_win      = get_cvs_locations('WINDOWS');
    my $cvsroot_got_sol      = get_cvs_locations('UNIX');
    my $cvsroot_got_lin      = get_cvs_locations('LINUX');
    
    is_deeply($cvsroot_got_win, $cvsroot_expected_win, 'get_cvs_locations( WINDOWS ) should return a hash with the cvs location.');
    is_deeply($cvsroot_got_sol, $cvsroot_expected_sol, 'get_cvs_locations(  UNIX   ) should return a hash with the cvs location.');
    is_deeply($cvsroot_got_lin, $cvsroot_expected_lin, 'get_cvs_locations(  LINUX  ) should return a hash with the cvs location.');
}

#####################################
## get_program_hash #################
### Note: pulled from variable establishment.
GET_PROGRAM_HASH:
{
    print "\n==Get Program Hash\n";
    is_deeply ($program_hash, $program_hash, 'get_program_hash( ) returns the list of all programs in a multilayer hash.');
    
    my $status = print_program_list();
    
    is ($status, 1, 'print_program_list( ) should print the list of valid programs then return 1.');
}

#####################################
## get_etc_locations($os) ###########
GET_ETC_LOCATIONS:
{
    print "\n==Get ETC Locations\n";
    my $etc_location_win = get_etc_locations('WINDOWS');
    my $etc_location_sol = get_etc_locations('UNIX');
    my $etc_location_lin = get_etc_locations('LINUX');
    
    print "\n\nConfig etc location source dir WINDOWS: $etc_location_win\n";
    print   "\nConfig etc location source dir UNIX:    $etc_location_sol\n";
    print   "\nConfig etc location source dir LINUX:   $etc_location_lin\n";
    
    is ($etc_location_win, $etc_location_win, 'get_etc_location( OS ) will return the configuration file source location: ' . $etc_location_win);
    is ($etc_location_sol, $etc_location_sol, 'get_etc_location( OS ) will return the configuration file source location: ' . $etc_location_sol);
    is ($etc_location_lin, $etc_location_lin, 'get_etc_location( OS ) will return the configuration file source location: ' . $etc_location_lin);
}

#####################################
## doc_check #######################
DOC_CHECK:
{
    print "\n\n==doc_check \n\n";
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
}
#####################################
## compile_check #######################
COMPILE_CHECK:
{
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
}

#####################################
## get_doc_file_name ################
GET_DOC_FILE_NAME:
{
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
}

#####################################
## get_bin_base_file_name ###########
GET_BIN_BASE_FILE_NAME:
{
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
}

#####################################
## get_bin_name_with_compile_path ###
GET_BIN_BASE_NAME_WITH_COMPILE_PATH:
{
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
}

#####################################
## get_bin_name_with_cvs_path #######
GET_BIN_NAME_WITH_CVS_PATH:
{
    print "\n\nget_bin_name_with_cvs_path\n";
    
    my $bin_cvs_file_win = get_bin_name_with_cvs_path('filesys.monitor', 'WINDOWS');
    print "filesys.monitor on WINDOWS: " . $bin_cvs_file_win . "\n";
    
    my $bin_cvs_file_sol = get_bin_name_with_cvs_path('filesys.monitor', 'UNIX');
    print "filesys.monitor on  UNIX  : " . $bin_cvs_file_sol . "\n";

    my $bin_cvs_file_lin = get_bin_name_with_cvs_path('filesys.monitor', 'LINUX');
    print "filesys.monitor on  LINUX : " . $bin_cvs_file_lin . "\n";
}

#############################################
#############################################
GET_PROGRAM_LIST_OS:
{
	my $program_list_os_win = get_program_exe_list_os('WINDOWS');
	my $program_list_os_sol = get_program_exe_list_os('UNIX');
	my $program_list_os_lin = get_program_exe_list_os('LINUX');

	print "\nProgram list for Windows\n\n";
	print Dumper ($program_list_os_win);
	print "\nProgram list for Solaris\n\n";
	print Dumper ($program_list_os_sol);
	print "\nProgram list for Linux\n\n";
	print Dumper ($program_list_os_lin);
}

#############################################
#############################################
COMPILE_PGM:
{
    my $dry       = 1;
    my $logfile   = "BGI-ESM-Compile-SSM.log";
    my $cvscommit = 0;
    
    foreach my $compile_item (sort keys %{$program_hash}) {
        my $status = compile_pgm($compile_item, $logfile, $dry, $cvscommit);
        print "\tStatus of compile for $compile_item " . $status . "\n";
    }    
    
}

#############################################
#############################################
VERSION_PRINT:
{
    
    my $version;
    #foreach my $compile_item (sort keys %{$program_hash}) {
    #    my $status = version_print($compile_item);
    #}    
    
}

#############################################
#############################################
VERSION_COMPARE:
{
    
    my $version;
    #foreach my $compile_item (sort keys %{$program_hash}) {
    #    my $status = version_compare($compile_item);
    #}    
    
}
#####################################
## post-processing clean up #########
#####################################



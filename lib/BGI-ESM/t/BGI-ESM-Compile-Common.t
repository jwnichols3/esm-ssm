
=head1 NAME

Test module for BGI ESM Compile VpoServer modules

=head1 SYNOPSIS

This is test suite for BGI::ESM::Compile::VpoServer

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.5 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-08-26   nichj   Developing release 1
  #  2005-10-27   nichj   Adding Linux Logic
  #####################################################################

=head1 TODO

- Write tests for the following:
	
=cut

#########################

use warnings;
use strict;
use Data::Dumper;
use Carp;
use File::chmod qw(getmod);
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type);

$Data::Dumper::Sortkeys = 1;

my @subs = qw(
    compile
    cvs_commit
    dry_run_settings
    get_compile_settings
    get_cvs_root
    get_module_dir
    get_perldoc_settings
    perldoc_pgm
    set_permissions
    set_execute
    write_log
);

BEGIN { use_ok('BGI::ESM::Compile::Common', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'compile');
can_ok( __PACKAGE__, 'cvs_commit');
can_ok( __PACKAGE__, 'dry_run_settings');
can_ok( __PACKAGE__, 'get_compile_settings');
can_ok( __PACKAGE__, 'get_cvs_root');
can_ok( __PACKAGE__, 'get_module_dir');
can_ok( __PACKAGE__, 'get_perldoc_settings');
can_ok( __PACKAGE__, 'perldoc_pgm');
can_ok( __PACKAGE__, 'set_permissions');
can_ok( __PACKAGE__, 'set_execute');
can_ok( __PACKAGE__, 'write_log');


###############################################################################
## main tests #################################################################
###############################################################################


#####################################
## establish test vars ##############
my @oses         = qw(WINDOWS UNIX LINUX);
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
## get_cvs_root ################
print "\nGet CVS locations\n";
my $cvsroot_windows = "c:/code/vpo";
my $cvsroot_unix    = "/apps/esm/vpo";
my $cvsroot_linux   = "/apps/esm/vpo";

my $cvsroot_got_win      = get_cvs_root('WINDOWS');
my $cvsroot_got_sol      = get_cvs_root('UNIX');
my $cvsroot_got_lin      = get_cvs_root('LINUX');

is($cvsroot_got_win, $cvsroot_windows, 'get_cvs_root( WINDOWS ) should return a hash with the cvs root: ' . $cvsroot_got_win);
is($cvsroot_got_sol, $cvsroot_unix,    'get_cvs_root(  UNIX   ) should return a hash with the cvs root: ' . $cvsroot_got_sol);
is($cvsroot_got_lin, $cvsroot_linux,   'get_cvs_root(  LINUX  ) should return a hash with the cvs root: ' . $cvsroot_got_lin);

#############################################
#############################################
CVS_COMMIT:
{
	my $cvs_commit_status = "";
	
	
	
}

SET_PERMISSIONS:
{
    print "\n== Set Permissions\n\n";
    
    my $TESTFILE;
    my $test_file = "test-permissions.tmp";
    
    if (-e $test_file) { unlink $test_file or croak "Unable to remove $test_file"; }
    
    open ($TESTFILE, ">", $test_file) or croak "Unable to create $test_file: $!\n";
    print $TESTFILE "Testing at " . time;
    close $TESTFILE;
    
    print "\n\tThe permissions of the file before the change: ";
    print getmod($test_file);
    print "\n\n";

    my $status = set_permissions($test_file);
    
    is ($status, 1, 'set_permissions( $file ) should return 1 if successful.');
    
    print "\n\tThe permissions of the file: ";
    print getmod($test_file);
    print "\n\n";
    
    #unlink $test_file or croak "Unable to delete $test_file: $!\n";
    
    $status = set_permissions();
    
    is ($status, 0, 'set_permissions( no_file ) should return 0 if called wrong.');
    
}

SET_EXECUTE:
{
    print "\n== Set Execute\n\n";
    
    my $TESTFILE;
    my $test_file = "test-execute.tmp";
    
    if (-e $test_file) { unlink $test_file or croak "Unable to remove $test_file"; }

    open ($TESTFILE, ">", $test_file) or croak "Unable to create $test_file: $!\n";
    print $TESTFILE "Testing at " . time;
    close $TESTFILE;
    
    print "\n\tThe permissions of the file before the change: ";
    print getmod($test_file);
    print "\n\n";

    my $status = set_execute($test_file);
    
    is ($status, 1, 'set_execute( $file ) should return 1 if successful.');

    print "\n\tThe permissions of the file: ";
    print getmod($test_file);
    print "\n\n";

    #unlink $test_file or croak "Unable to delete $test_file: $!\n";
    
    $status = set_execute();
    
    is ($status, 0, 'set_execute( no_file ) should return 0 if called wrong.');
    
}

#####################################
## post-processing clean up #########
#####################################



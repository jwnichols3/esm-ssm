
=head1 NAME

Test module for BGI ESM Common ActivePerlUtils testing

=head1 SYNOPSIS

This is test suite for BGI::ESM::ActivePerlUtils

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.6 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-mm-dd   nichj   Developing release 1
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:
	
=cut


#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
use Carp;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::ActivePerlUtils;

my @subs = qw(
    get_module_list
    get_ppm_cmd
    get_ppm_upgrade_cmd
    get_ppm_install_cmd
    get_ppm_uninstall_cmd
    get_ppm_describe_cmd
    get_ppm_search_cmd
    new_version_check
    upgrade_module
    install_module
    uninstall_module
    module_installed
    is_module_installable
 );

BEGIN { use_ok('BGI::ESM::SelfService::Performance', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'get_module_list'       );
can_ok( __PACKAGE__, 'get_ppm_cmd'           );
can_ok( __PACKAGE__, 'get_ppm_upgrade_cmd'   );
can_ok( __PACKAGE__, 'get_ppm_install_cmd'   );
can_ok( __PACKAGE__, 'get_ppm_uninstall_cmd' );
can_ok( __PACKAGE__, 'get_ppm_describe_cmd'  );
can_ok( __PACKAGE__, 'get_ppm_search_cmd'    );
can_ok( __PACKAGE__, 'new_version_check'     );
can_ok( __PACKAGE__, 'upgrade_module'        );
can_ok( __PACKAGE__, 'install_module'        );
can_ok( __PACKAGE__, 'uninstall_module'      );
can_ok( __PACKAGE__, 'module_installed'      );
can_ok( __PACKAGE__, 'is_module_installable' );


#####################################
## pre-processing set up ############
#####################################

PREPROCESS:
{
    my $retval;
}


MODULE_INSTALLED:
{
    my @not_installed_list;
    my $list = get_module_list();
    
    foreach my $item (@{$list}) {
        
        print "\nChecking for module $item\n";
        my $status = module_installed($item);
        print "\tStatus: == $status ==\n";
        
        if (not $status) {
            push @not_installed_list, $item;
        }
        
    }
    
    print "\nThe following are modules that aren't installed and can be installed:\n";
    print "@not_installed_list\n";
    my $ppm_file = "ppm_status.log";
    my $PPMFILE;
    
    open ($PPMFILE, ">", $ppm_file) or croak "Unable to open $ppm_file: $!\n";
    
    print $PPMFILE "The following are modules that aren't installed and can be installed:\n\n";
    print $PPMFILE Dumper (\@not_installed_list);
    close $PPMFILE or croak "Unable to close $ppm_file: $!\n";;
    
};
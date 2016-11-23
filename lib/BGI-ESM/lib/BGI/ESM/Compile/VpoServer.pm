=head1 TITLE

SSM v2 Compile Module: BGI::ESM::Compile::VpoServer

=head1 DESCRIPTION

Use this module when wanting to compile VPO Server-based programs.

=head1 USAGE

use BGI::ESM::Compile::VpoServer

=head1 TODO

    Write test for cvs_commit method.


=head1 REVISIONS

CVS Revision: $Revision: 1.29 $
    Date:     $Date: 2007/07/19 15:30:20 $

  #####################################################################
  #  2005-09-26 - nichj    - Beginning development
  #  2005-09-27 - nichj    - Adding copy & update methods: get_all_programs & copy_program
  #                          Added 'EXECUTE' to hash structure
  #  2005-10-27 - nichj    - Added Linux Logic
  #  2005-11-01 - nichj    - Added VPO SQL Dir to hash
  #  2005-11-22 - nichj    - Added setting of permissions
  #  2005-11-27 - nichj    - Added setperm.pl to list
  #  2006-04-18 - nichj    - Added vpo_node_list and bgi_nodelist_raw.sql
  #  2006-08-06 - nichj    - Added ovo_monitor
  #  2007-07-19 - nichj    - Added copy_oper_audit_files
  #
  #####################################################################

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::Compile::VpoServer;
###############################################################################

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use File::stat;
use Data::Dumper;
use File::Basename;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os copy_file);
use BGI::ESM::Compile::Common;

###############################################################################

###############################################################################
### Require Section ###########################################################
require Exporter;
###############################################################################

###############################################################################
### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::Compile);
###############################################################################

###############################################################################
### Public Exports ############################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
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
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.29 $)[-1];
our $program_list = get_program_hash();
#################################################################################

#################################################################################
# Public Variables
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

=head2 get_cvs_locations($os) {
    returns reference to hash with the following structure:
    $hash = {
                'CVSROOT'     => "cvs root based on os",
                'BIN'         => "cvs SSM bin directory",
                'ETC'         => "cvs SSM etc directory",
                'SRC'         => "cvs SSM source directory",
                'DOC'         => "cvs SSM doc directory",
                'LIB'         => "cvs Perl library directory",
                'BIN_UNIX'    => "cvs SSM bin unix",
                'BIN_WINDOWS' => "cvs SSM bin windows",
                'ETC_UNIX'    => "cvs SSM etc UNIX",
                'ETC_WINDOWS' => "cvs SSM etc WINDOWS"
            }
=cut

sub get_cvs_locations {
    my $os      = shift;
    my $cvsroot = "";

    $os         = check_os($os);

    $cvsroot    = get_cvs_root($os);

    my $cvshash = {
                   'CVSROOT'     => "$cvsroot",
                   'BIN'         => "$cvsroot/vpo_server/bin",
                   'ETC'         => "$cvsroot/vpo_server/etc",
                   'SRC'         => "$cvsroot/vpo_server/src",
                   'DOC'         => "$cvsroot/vpo_server/doc",
                   'SQL'         => "$cvsroot/vpo_server/sql",
                   'VPOSQL'      => "/etc/opt/OV/share/conf/OpC/mgmt_sv/reports/C",
                   'PL_LIB'      => "$cvsroot/vpo_server/lib",
                   'LIB'         => "$cvsroot/BGI-ESM/lib",
                   'BIN_UNIX'    => "$cvsroot/vpo_server/bin/solaris",
                   'BIN_LINUX'   => "$cvsroot/vpo_server/bin/linux",
                   'BIN_WINDOWS' => "$cvsroot/vpo_server/bin/windows",
                   'ETC_UNIX'    => "$cvsroot/vpo_server/etc/solaris",
                   'ETC_LINUX'   => "$cvsroot/vpo_server/etc/linux",
                   'ETC_WINDOWS' => "$cvsroot/vpo_server/etc/windows",
                  };

    return $cvshash;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_base_path([$os])
    returns the base path to where the production files live
     if $os is not passed then the current $os is assumed.
=cut

sub get_base_path {
    my $os = shift;
       $os = check_os($os);
    my ($retval, $drive);

    if ($os eq 'WINDOWS') {
        $drive = "c:" if (-e "c:/" );
        $drive = "e:" if (-e "e:/" );
        $retval = "$drive/apps/esm";
    }
    else {
        $retval = "/apps/esm";
    }

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_program_hash($source_dir)
    returns reference to array with list of programs and their associated
     source file name
=cut

sub get_program_hash {

    my ($compile_locations) = get_compile_locations();
    my $source_dir          = $compile_locations->{'SOURCE'};
    my $bin_dir             = $compile_locations->{'BIN'};
    my $lib_dir             = $compile_locations->{'LIB'};
    my $pl_lib_dir          = $compile_locations->{'PL_LIB'};
    my $doc_dir             = $compile_locations->{'DOC'};
    my $sql_dir             = $compile_locations->{'SQL'};
    my $vpo_sql_dir         = $compile_locations->{'VPOSQL'};
    my $scauto_dir          = "/opt/OV/scauto";
    my $sql_dest            = "/etc/opt/OV/share/conf/OpC/mgmt_sv/reports/C";
    my $suppress_dir        = "/opt/OV/suppress";

    my ($base_path)         = get_base_path();
    my $etc_dir_sol         = get_etc_locations('UNIX');
    my $etc_dir_lin         = get_etc_locations('LINUX');
    my $etc_dir_win         = get_etc_locations('WINDOWS');
    my ($program_list);

    $program_list = {
        #####################  PROGRAMS AND COMPILABLES #######################
        'check-q'    =>
                                {
                                'SOURCE'    => "$source_dir/check-q.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/tti/bin",
                                'EXECUTE'   => "yes",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "check-q"
                                },

        'chg_own.c'    =>
                                {
                                'SOURCE'    => "$source_dir/chg_own.c",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$base_path/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => ""
                                },

        'copy_oper_audit_files'    =>
                                {
                                'SOURCE'    => "$source_dir/copy_oper_audit_files.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "copy_oper_audit_files"
                                },

        'data_map_report'    =>
                                {
                                'SOURCE'    => "$source_dir/data_map_report.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/reporting/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "data_map_report"
                                },

        'log-rotate'    =>
                                {
                                'SOURCE'    => "$source_dir/log-rotate.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/tti/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "log-rotate"
                                },

        'looking_glass_update'    =>
                                {
                                'SOURCE'    => "$source_dir/looking_glass_update.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/tti/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "looking_glass_update"
                                },

        'looking_glass_util'    =>
                                {
                                'SOURCE'    => "$source_dir/looking_glass_util.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/tti/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "looking_glass_util"
                                },

        'opc_notify'    =>
                                {
                                'SOURCE'    => "$source_dir/opc_notify.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/tti/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "opc_notify"
                                },

        'ovo_monitor'    =>
                                {
                                'SOURCE'    => "$source_dir/ovo_monitor.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/maintenance/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "ovo_monitor"
                                },

        'suppress_check'    =>
                                {
                                'SOURCE'    => "$source_dir/suppress_check.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$suppress_dir",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "suppress_check"
                                },

        'TTI'    =>
                                {
                                'SOURCE'    => "$source_dir/TTI.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/tti/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "TTI"
                                },

        'datamap_util'    =>
                                {
                                'SOURCE'    => "$source_dir/datamap_util.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/tti/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "datamap_util"
                                },

        'vpo_node_ip_report'    =>
                                {
                                'SOURCE'    => "$source_dir/vpo_node_ip_report.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/reporting/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "vpo_node_ip_report"
                                },

        'ToSC_eventmapTTI.tcl'    =>
                                {
                                'SOURCE'    => "$source_dir/ToSC/eventmapTTI.tcl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$scauto_dir/EventMap/ToSC",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "eventmapTTI.tcl"
                                },

        'FromSC_vpopmc.tcl'    =>
                                {
                                'SOURCE'    => "$source_dir/FromSC/vpopmc.tcl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$scauto_dir/EventMap/FromSC",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "vpopmc.tcl"
                                },

        'FromSC_vpopmo.tcl'    =>
                                {
                                'SOURCE'    => "$source_dir/FromSC/vpopmo.tcl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$scauto_dir/EventMap/FromSC",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "vpopmo.tcl"
                                },

        'netiq_node_list'    =>
                                {
                                'SOURCE'    => "$source_dir/netiq_node_list.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/node_sync/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "netiq_node_list"
                                },

        'netiq_node_sync'      =>
                                {
                                'SOURCE'    => "$source_dir/netiq_node_sync.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/node_sync/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "netiq_node_sync"
                                },

        'Node_Group_Extract'      =>
                                {
                                'SOURCE'    => "$source_dir/Node_Group_Extract.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/nodestatus/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "Node_Group_Extract"
                                },

        'node_source_populate'      =>
                                {
                                'SOURCE'    => "$source_dir/node_source_populate.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/node_sync/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "node_source_populate"
                                },

        'nodestatus.alert'      =>
                                {
                                'SOURCE'    => "$source_dir/nodestatus.alert.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/nodestatus/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "nodestatus.alert"
                                },

        'nodestatus.clean_up'      =>
                                {
                                'SOURCE'    => "$source_dir/nodestatus.clean_up.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/nodestatus/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "nodestatus.clean_up"
                                },

        'nodestatus.config_populate'      =>
                                {
                                'SOURCE'    => "$source_dir/nodestatus.config_populate.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/nodestatus/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "nodestatus.config_populate"
                                },

        'nodestatus.delta'      =>
                                {
                                'SOURCE'    => "$source_dir/nodestatus.delta.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/nodestatus/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "nodestatus.delta"
                                },

        'nodestatus.sweep'      =>
                                {
                                'SOURCE'    => "$source_dir/nodestatus.sweep.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/nodestatus/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "nodestatus.sweep"
                                },

        'ssm_email_monitor'      =>
                                {
                                'SOURCE'    => "$source_dir/ssm_email_monitor.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "ssm_email_monitor"
                                },

        'sync_mom'      =>
                                {
                                'SOURCE'    => "$source_dir/sync_mom.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/maintenance/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "sync_mom"
                                },

        'vpo_node_list'      =>
                                {
                                'SOURCE'    => "$source_dir/vpo_node_list.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/vpo_sync/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "vpo_node_list"
                                },

        'unix_node_list'      =>
                                {
                                'SOURCE'    => "$source_dir/unix_node_list.pl",
                                'COMPILE'   => "yes",
                                'PERLDOC'   => "yes",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/node_sync/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "unix_node_list"
                                },

        #####################  LIBRARIES ######################################
        'alarmpoint-functions'      =>
                                {
                                'SOURCE'    => "$pl_lib_dir/alarmpoint-functions.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/lib",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "alarmpoint-functions.pl"
                                },

        'all_server_common'      =>
                                {
                                'SOURCE'    => "$pl_lib_dir/all_server_common.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/lib",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "all_server_common.pl"
                                },

        'alternate-notification'      =>
                                {
                                'SOURCE'    => "$pl_lib_dir/alternate-notification.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/lib",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "alternate-notification.pl"
                                },

        'data-map'      =>
                                {
                                'SOURCE'    => "$pl_lib_dir/data-map.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/lib",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "data-map.pl"
                                },

        'looking_glass_functions'      =>
                                {
                                'SOURCE'    => "$pl_lib_dir/looking_glass_functions.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/lib",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "looking_glass_functions.pl"
                                },

        'node_source_common'      =>
                                {
                                'SOURCE'    => "$pl_lib_dir/node_source_common.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/lib",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "node_source_common.pl"
                                },

        'peregrine-functions'      =>
                                {
                                'SOURCE'    => "$pl_lib_dir/peregrine-functions.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/lib",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "peregrine-functions.pl"
                                },

        'server_common'      =>
                                {
                                'SOURCE'    => "$pl_lib_dir/server_common.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/lib",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "server_common.pl"
                                },

        'vpo-functions'      =>
                                {
                                'SOURCE'    => "$pl_lib_dir/vpo-functions.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "yes",
                                'DEST_PATH' => "$base_path/lib",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "vpo-functions.pl"
                                },

        #####################  HELP AND MISC ##################################
        #''      =>
        #                        {
        #                        'SOURCE'    => "$source_dir/vposend_help",
        #                        'COMPILE'   => "no",
        #                        'PERLDOC'   => "no",
        #                        'DEST_PATH' => "",
        #                        'WINDOWS'   => "vposend_help",
        #                        'LINUX'     => "",
        #                        'UNIX'      => "vposend_help"
        #                        },
        #
        #####################  SHELL, SCRIPT, AND BATCH #######################
        'chg_own_compile.sh'    =>
                                {
                                'SOURCE'    => "$source_dir/chg_own_compile.sh",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "chg_own_compile.sh"
                                },

        'scauto_check.sh'    =>
                                {
                                'SOURCE'    => "$source_dir/scauto_check.sh",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/tti/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "scauto_check.sh"
                                },

        'TTI.sh'    =>
                                {
                                'SOURCE'    => "$source_dir/TTI.sh",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/tti/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "TTI.sh"
                                },

        'ownedmessages.sh'      =>
                                {
                                'SOURCE'    => "$source_dir/ownedmessages.sh",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/maintenance/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "ownedmessages.sh"
                                },

        'setperm.pl'      =>
                                {
                                'SOURCE'    => "$source_dir/setperm.pl",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/maintenance/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "setperm.pl"
                                },

        'sync_mom.sh'      =>
                                {
                                'SOURCE'    => "$source_dir/sync_mom.sh",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/maintenance/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "sync_mom.sh"
                                },

        'unownedmessages.sh'      =>
                                {
                                'SOURCE'    => "$source_dir/unownedmessages.sh",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'EXECUTE'   => "yes",
                                'DEST_PATH' => "$base_path/maintenance/bin",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "unownedmessages.sh"
                                },


        #####################  CONFIGS ########################################
        'ToSC_pmc.map'      =>
                                {
                                'SOURCE'    => "$source_dir/ToSC/pmc.map",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$scauto_dir/EventMap/ToSC",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "pmc.map"
                                },

        'ToSC_pmo.map'      =>
                                {
                                'SOURCE'    => "$source_dir/ToSC/pmo.map",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$scauto_dir/EventMap/ToSC",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "pmo.map"
                                },

        'ToSC_pmu.map'      =>
                                {
                                'SOURCE'    => "$source_dir/ToSC/pmu.map",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$scauto_dir/EventMap/ToSC",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "pmu.map"
                                },

        'ToSC_vpopmc.map'      =>
                                {
                                'SOURCE'    => "$source_dir/ToSC/vpopmc.map",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$scauto_dir/EventMap/ToSC",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "vpopmc.map"
                                },

        'ToSC_vpopmo.map'      =>
                                {
                                'SOURCE'    => "$source_dir/ToSC/vpopmo.map",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$scauto_dir/EventMap/ToSC",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "vpopmo.map"
                                },

        'ToSC_vpopmu.map'      =>
                                {
                                'SOURCE'    => "$source_dir/ToSC/vpopmu.map",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$scauto_dir/EventMap/ToSC",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "vpopmu.map"
                                },

        # nichj - commenting out until clarification on use
        #'sync_server'      =>
        #                        {
        #                        'SOURCE'    => "$etc_dir_sol/sync_server",
        #                        'COMPILE'   => "no",
        #                        'PERLDOC'   => "no",
        #                        'DEST_PATH' => "$base_path/maintenance/etc",
        #                        'WINDOWS'   => "",
        #                        'LINUX'     => "",
        #                        'UNIX'      => "sync_server"
        #                        },

        #####################  SQL ############################################
        'all_nodes_formatted.sql'      =>
                                {
                                'SOURCE'    => "$sql_dir/all_nodes_formatted.sql",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$vpo_sql_dir",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "all_nodes_formatted.sql"
                                },

        'all_nodes_no_header.sql'      =>
                                {
                                'SOURCE'    => "$sql_dir/all_nodes_no_header.sql",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$vpo_sql_dir",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "all_nodes_no_header.sql"
                                },

        'all_nodes_with_ip_addr.sql'      =>
                                {
                                'SOURCE'    => "$sql_dir/all_nodes_with_ip_addr.sql",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$vpo_sql_dir",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "all_nodes_with_ip_addr.sql"
                                },

        'bgi_nodelist_raw.sql'      =>
                                {
                                'SOURCE'    => "$sql_dir/bgi_nodelist_raw.sql",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$vpo_sql_dir",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "bgi_nodelist_raw.sql"
                                },

        'vpo_message_groups_raw.sql'      =>
                                {
                                'SOURCE'    => "$sql_dir/vpo_message_groups_raw.sql",
                                'COMPILE'   => "no",
                                'PERLDOC'   => "no",
                                'DEST_PATH' => "$vpo_sql_dir",
                                'WINDOWS'   => "",
                                'LINUX'     => "",
                                'UNIX'      => "vpo_message_groups_raw.sql"
                                },

        };

  return $program_list;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_program_list_os($os)
    returns a reference to an array with the program executables based on the OS
    if $os is blank it will use the running OS.
=cut

sub get_program_exe_list_os {
    my $os = shift;
       $os = check_os($os);
    my $program_hash = get_program_hash();
    my (@return_list);

    foreach my $program ( sort keys %{$program_hash} ) {
        if ( compile_check($program) ) {
            if ( $program_hash->{$program}->{$os} ) {
                push @return_list, $program_hash->{$program}->{$os};
            }
        }
    }

    return \@return_list;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_program_list([$os])
    returns reference to array with a list of valid programs to copy
=cut

sub get_program_list {
    my $os = shift;
       $os = check_os($os);
    my @retval;

    my $program_hash = get_program_hash();

    @retval = keys %{$program_hash};

    return \@retval;

}

=head2 print_program_list()
    prints the source file list using Data::Dumper
=cut

sub print_program_list {
    my $option = shift;
    my $program_list = get_program_hash();

    if ( ($option) and (lc $option eq "all") ) {

        print "\nHere are the program names and the associated source files in the format\n";
        print '
           program name =>
                      {
                          SOURCE    => "source file"
                          COMPILE   => "yes | no"
                          PERLDOC   => "yes | no"
                          DEST_PATH => "destination path for file"
                          WINDOWS   => "Windows base exe name"
                          LINUX     => "Linux   base exe name"
                          SOLARIS   => "Solaris base exe name"
                      }
              ';
        print Dumper ($program_list);

    }
    else {

        print "\n\nHere are the list of valid programs:\n\n";

        foreach my $key (sort keys %{$program_list}) {
            print "\t$key\n";
        }

    }

    return 1;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_compile_locations()
    returns hash array with the following
        'SOURCE' => "",
        'BIN'    => "",
        'LIB'    => "",
        'PL_LIB' => "",
        'DOC'    => ""
=cut

sub get_compile_locations {
    my $os = shift;
       $os = check_os($os);

    my $compile_locations = {
                             'SOURCE' => "",
                             'BIN'    => "",
                             'LIB'    => "",
                             'PL_LIB' => "",
                             'DOC'    => "",
                             'SQL'    => "",
                             'VPOSQL' => "",
                            };


    my $cvsroot = get_cvs_locations($os);

    $compile_locations->{ 'SOURCE' }    = $cvsroot->{'SRC'   };
    $compile_locations->{ 'LIB'    }    = $cvsroot->{'LIB'   };
    $compile_locations->{ 'PL_LIB' }    = $cvsroot->{'PL_LIB'};
    $compile_locations->{ 'DOC'    }    = $cvsroot->{'DOC'   };
    $compile_locations->{ 'SQL'    }    = $cvsroot->{'SQL'   };
    $compile_locations->{ 'VPOSQL' }    = $cvsroot->{'VPOSQL'};

    if ($os eq 'WINDOWS') {

        $compile_locations->{'BIN'} = $cvsroot->{'BIN_WINDOWS'};

    }
    elsif ($os eq 'LINUX') {

        $compile_locations->{'BIN'} = $cvsroot->{'BIN_LINUX'};

    }
    else {

        $compile_locations->{'BIN'} = $cvsroot->{'BIN_UNIX'};

    }

    return ($compile_locations);

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_etc_locations($os)
    returns the location of the config (etc) directory based on the incoming $os
    and the current OS running (as defined by os_type()
=cut

sub get_etc_locations {
    my $os         = shift;
    my $current_os = os_type();

    if (not $os) { return 0; }

    if ($current_os eq 'WINDOWS') {

        if ($os eq 'WINDOWS') {
            return "c:/code/vpo/vpo_server/etc/windows";
        }
        elsif ($os eq 'LINUX') {
            
            return "c:/code/vpo/vpo_server/etc/linux";
            
        }
        else {
            return "c:/code/vpo/vpo_server/etc/solaris";
        }

    }
    else {

        if ($os eq 'WINDOWS') {
            return "/apps/esm/vpo/vpo_server/etc/windows";
        }
        elsif ($os eq 'LINUX') {
            
            return "c:/code/vpo/vpo_server/etc/linux";
            
        }
        else {
            return "/apps/esm/vpo/vpo_server/etc/solaris";
        }

    }

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 compile_continue($source_dir, $bin_dir, $lib_dir, $doc_dir)
=cut

sub compile_continue {
  my ($compile_locations) = get_compile_locations();
    my $source_dir = $compile_locations->{'SOURCE'};
    my $bin_dir    = $compile_locations->{'BIN'};
    my $lib_dir    = $compile_locations->{'LIB'};
    my $pl_lib_dir = $compile_locations->{'PL_LIB'};
    my $doc_dir    = $compile_locations->{'DOC'};

  my $retval = 1;

  if (not -e $source_dir) {
    print "Unable to find source_dir $source_dir\n";
    $retval = 0;
  }
  if (not -e $bin_dir)    {
    print "Unable to find bin_dir $bin_dir\n";
    $retval = 0;
  }

  if (not -e $lib_dir)    {
    print "Unable to find lib_dir $lib_dir\n";
    $retval = 0;
  }

  if (not -e $pl_lib_dir)    {
    print "Unable to find pl_lib_dir $pl_lib_dir\n";
    $retval = 0;
  }

  if (not -e $doc_dir)    {
    print "Unable to find doc_dir $doc_dir\n";
    $retval = 0;
  }

  return $retval;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 compile_pgm($program name as found in get_program_hash, $dry, $logfile)
    Returns
=cut

sub compile_pgm {
    my ($key, $dry, $logfile, $checkin) = @_;
    my $retval = 1;

    my $program_list = get_program_hash();

    my $exe          = get_bin_name_with_compile_path($key, os_type());
    #print "\tcompile_pgm: EXE for $key is $exe\n";

    if ($exe) {

        my $source_file  = $program_list->{$key}->{'SOURCE'};

        if ( compile_check_os($key, os_type()) ) {

            my $status = compile($source_file, $exe, $dry, $logfile, $checkin);


        }
        else {

            print "Skipping $key for " . os_type() . "\n";
            $retval = 0;

        }

    }
    else {

        $retval = 0;

    }

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_bin_name_with_compile_path($program_name, $os)
  returns the name of the bin file
=cut

sub get_bin_name_with_compile_path {
    my $program_name = shift;
    my $os           = shift;
  
    $os = check_os($os);

    my ($compile_locations) = get_compile_locations($os);
    my $source_dir = $compile_locations->{'SOURCE'};
    my $bin_dir    = $compile_locations->{'BIN'};
    my $lib_dir    = $compile_locations->{'LIB'};
    my $pl_lib_dir = $compile_locations->{'PL_LIB'};
    my $doc_dir    = $compile_locations->{'DOC'};

    my $bin_file;
    my $program_get  = get_bin_base_file_name($program_name, $os);
  
    if ($program_get) {
  
      $bin_file  = "$bin_dir/" . $program_get;
  
    }
  
    else {
  
      $bin_file = 0;
  
    }
  
    return $bin_file;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 doc_pgm($program name as found in get_program_hash, $dry, $logfile)
    returns 1 if successful
=cut

sub doc_pgm {
    my ($key, $dry, $logfile) = @_;
    my $retval;

    my $program_list = get_program_hash();

    if (doc_check($key)) {

        if (-e $program_list->{$key}->{'SOURCE'}) {

            my $source_file          = $program_list->{$key}->{'SOURCE'};

            my $doc_file             = get_doc_file_name($key);

            my $status = perldoc_pgm($source_file, $doc_file, $dry, $logfile);

        }
        else {

            print "\nError! Unable to find source file associated with $key\n";
            $retval = 0;

        }

    }
    else {

        print "This program: $key is marked to not be documented with perldoc\n";

    }

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 doc_check($program as defined in get_source_hash)
    returns 1 if should be documented, 0 if not
=cut

sub doc_check {
    my $key    = shift;
    my $retval = 0;
    my $doc_flag;

    my $program_list = get_program_hash();

    $doc_flag = $program_list->{$key}->{'PERLDOC'};

    if ($doc_flag) {
        if ($doc_flag eq "yes") {
            $retval = 1;
        }
    }

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 compile_check($program name as defined in get_source_hash)
    returns 1 if the program should be documented, 0 if not.
=cut

sub compile_check {
    my $key    = shift;
    my $retval = 0;

    my $program_list = get_program_hash();

    my $compile_flag = $program_list->{$key}->{'COMPILE'};

    if ( ($compile_flag) and ($compile_flag eq "yes") ) {
        $retval = 1;
    }

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 compile_check_os($program name as defined in get_source_hash, $os)
    returns 1 if the program should be compiled for $os, 0 if not.
=cut

sub compile_check_os {
    my $key    = shift;
    my $os     = shift;
    my $retval = 0;

    my $program_list = get_program_hash();

    if ( exists($program_list->{$key}->{$os}) ) {

        $retval = 1;

    }

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 get_doc_file_name($program)
  returns the name of the doc file
=cut

sub get_doc_file_name {
    my $program_name = shift;
    my ($compile_locations) = get_compile_locations();
        my $source_dir = $compile_locations->{'SOURCE'};
        my $bin_dir    = $compile_locations->{'BIN'};
        my $lib_dir    = $compile_locations->{'LIB'};
        my $pl_lib_dir = $compile_locations->{'PL_LIB'};
        my $doc_dir    = $compile_locations->{'DOC'};

    my ($doc_file,);

    #my $extension = get_exe_extension();

    $doc_file  = "$doc_dir/" . $program_name . ".doc";

    return $doc_file;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_bin_base_file_name($program, $os)
  returns the name of the doc file
=cut

sub get_bin_base_file_name {
    my $program_name = shift;
    my $os           = shift;
    my $program_list = get_program_hash();
    my $bin_file;

    $os = check_os($os);

    if (exists($program_list->{$program_name}->{$os})) {

        $bin_file = $program_list->{$program_name}->{$os};
    }

    return $bin_file;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 compile_location_summary()
=cut

sub compile_location_summary {

    my ($compile_locations) = get_compile_locations();
    my $source_dir  = $compile_locations->{'SOURCE'};
    my $bin_dir     = $compile_locations->{'BIN'};
    my $lib_dir     = $compile_locations->{'LIB'};
    my $pl_lib_dir  = $compile_locations->{'PL_LIB'};
    my $sql_dir     = $compile_locations->{'SQL'};
    my $vpo_sql_dir = $compile_locations->{'VPOSQL'};

    my $doc_dir     = $compile_locations->{'DOC'};

    print "We are using the following locations:\n";
    print "\tsource directory: $source_dir\n";
    print "\tbin directory:    $bin_dir\n";
    print "\tdoc directory:    $doc_dir\n";
    print "\tsql directory:    $sql_dir\n";
    print "\tpl lib directory: $pl_lib_dir\n";
    print "\tlib directory:    $lib_dir\n\n";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 print_version($program, $bin)
=cut

sub get_version {
    my ($program, $bin) = @_;
    my ($compile_locations) = get_compile_locations();
    my $source_dir = $compile_locations->{'SOURCE'};
    my $bin_dir    = $compile_locations->{'BIN'};
    my $lib_dir    = $compile_locations->{'LIB'};
    my $pl_lib_dir = $compile_locations->{'PL_LIB'};
    my $doc_dir    = $compile_locations->{'DOC'};
    my $program_list = get_program_hash();
    my $retval  = "unknown 0.00";

    if ($bin) {

      my $run_file = $program_list->{$program}->{os_type()};

      if ($run_file) {

          my $exe_pgm = $bin_dir . "/" . $run_file;
          $retval = `$exe_pgm -v`;

      }

    }

    else {

      my $pgm = $program_list->{$program}->{'SOURCE'};

      if ($pgm) {

        if (-e $pgm) {
              $retval = `perl $pgm -v`;
              chomp ($retval);
        }
        else {
            carp "get_version: Unable to find file $pgm\n";
            $retval = "0.00";
        }

      }

    }

    chomp ($retval);
    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 version_compare_all()
=cut

sub version_compare_all {
  my ($compile_locations) = get_compile_locations();
    my $source_dir = $compile_locations->{'SOURCE'};
    my $bin_dir    = $compile_locations->{'BIN'};
    my $lib_dir    = $compile_locations->{'LIB'};
    my $pl_lib_dir = $compile_locations->{'PL_LIB'};
    my $doc_dir    = $compile_locations->{'DOC'};

  my $program_list = get_program_hash();
  my ($version_compare, $version_diff, $version_like);
  my %version_compare; ##{ 'program' => { 'bin' => "ver", 'src' => "ver" } };
  my %version_diff;    ##{ 'program' => { 'bin' => "ver", 'src' => "ver" } };
  my %version_like;    ##{ 'program' => { 'bin' => "ver", 'src' => "ver" } };

  print "Retrieving versions... please wait\n";

  foreach my $key (keys %{$program_list}) {

    if (compile_check($key)) {

        my ($source_ver, $bin_ver) = version_compare($key);

        $version_compare->{$key}->{'src'} = $source_ver;
        $version_compare->{$key}->{'bin'} = $bin_ver;
    }

  }

  foreach my $ver_key (keys %{$version_compare}) {
    my $bin_ver = $version_compare->{$ver_key}->{'bin'};
    my $src_ver = $version_compare->{$ver_key}->{'src'};

    #print "\tprogram $ver_key -- bin: $bin_ver -- src: $src_ver\n";

    if ($bin_ver eq $src_ver) {
      $version_like->{$ver_key}->{'src'} = $src_ver;
      $version_like->{$ver_key}->{'bin'} = $bin_ver;
    }
    else {
      $version_diff->{$ver_key}->{'src'} = $src_ver;
      $version_diff->{$ver_key}->{'bin'} = $bin_ver;
    }
  }

  print "\n\nPrograms with MISMATCHED version:\n";

  if ($version_diff) {
    print Dumper ($version_diff);
  }
  else {
    print "NONE!\n";
  }

  print "\n\nPrograms with matching versions:\n";

  print Dumper ($version_like);

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 version_compare($program name as found in get_program_hash)
  returns ($source_ver, $bin_ver)
=cut

sub version_compare {
  my $program = shift;
  my ($source_ver, $bin_ver);

    $source_ver = get_source_version($program);
    $bin_ver    = get_bin_version($program);

    $source_ver = (split / /, $source_ver)[-1];
    $bin_ver    = (split / /, $bin_ver)[-1];

    chomp($source_ver);
    chomp($bin_ver);

  return ($source_ver, $bin_ver);

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 version_print($program name as found in get_program_hash)
=cut

sub version_print {
  my $pgm = shift;

    if ($pgm) {
        my ($source_ver, $bin_ver) = version_compare($pgm);

        print "Versions for $pgm\n";
        print "\tSource: $source_ver\n";
        print "\tBin   : $bin_ver\n";
    }
    else {
        carp "\tversion_print: the passed program variable was not set properly\n";
    }

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_source_version($program)
=cut

sub get_source_version {
  my $program = shift;
  my $bin     = 0;

  return get_version($program, $bin);

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_bin_version($program)
=cut

sub get_bin_version {
  my $program = shift;
  my $bin     = 1;

  return get_version($program, $bin);

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_program_source_file($program)

=cut

sub get_program_source_file {
    my $program = shift;
    my $bin     = 1;
    my $program_list = get_program_hash();

    if ( exists($program_list->{$program}->{'SOURCE'}) ) {

        return $program_list->{$program}->{'SOURCE'};

    }
    else {

        return 0;

    }

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_bin_name_with_cvs_path($program, $os_to_get)
    This determines the running OS, gets the cvs path, then returns
    the path of the program based on the incoming os.
    Returns: scalar with path to program.
=cut

sub get_bin_name_with_cvs_path {
    my ($program, $os) = @_;
    my $current_os     = os_type();
    my ($bin_location, $retval);

    my $cvs_root = get_cvs_locations($current_os);

    if ($os eq 'WINDOWS') {
        $bin_location = $cvs_root->{'BIN_WINDOWS'};
    }
    elsif ($os eq 'LINUX') {
        
        $bin_location = $cvs_root->{'BIN_LINUX'};
        
    }
    else {
        $bin_location = $cvs_root->{'BIN_UNIX'};
    }

    my $bin_file = get_bin_base_file_name($program, $os);

    if ($bin_file) {
        $retval = $bin_location . "/" . $bin_file;
    }
    else {
        $retval = 0;
    }

    return $retval;

}



=head2 get_distrib_dest_file_name($program, $os, $type)
    returns the distribution destination file name based on program, os, and type
=cut

sub get_dest_file_name {
    my ($program, $os) = @_;

    return _dest_file_name($program, $os);

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 copy_program($program, $os, $logfile, $dry)
    Copies the program to the destination file based on the program name.
    Writes out the results to $logfile
    Doesn't process if $dry is set
=cut

sub copy_program {
    my ($program, $logfile, $dry) = @_;
    my ($status);
    my $retval = 1;

    my $os = check_os();


    if (not $dry) {
        my $write_text  = "";
        my $from_file   = get_from_file_name($program, $os);
        my $dest_file   = get_destination_file_name($program, $os);
           $write_text  = "For real: $program, $os\n" .
                          "\tFrom file: " . $from_file . "\n" .
                          "\tTo file:   " . $dest_file . "\n";

        if (should_copy($program, $os)) {

            $status = _copy_program($program, $os);

            if (not $status) {
                carp "There was a problem copying the distribution file: $!\n";
                $retval = 0;
            }

            $write_text = $write_text . "\tCopy status: $status\n";
            
            $status = set_permissions_server($dest_file);
            
            $write_text = $write_text . "\tPermission set status: $status\n";

            if (not $status) {
                carp "There was a problem updating the permissions of the destination file $dest_file: $!\n";
                $retval = 0;
            }
        }
        else {
            $write_text = $write_text . "\tStatus: should not copy\n";
        }

        write_log($logfile, $write_text);

    }
    else {
        my $write_text = "";

        my $from_file   = get_from_file_name($program, $os);
        my $dest_file   = get_destination_file_name($program, $os);

        if ( not $from_file ) {

            $write_text = "Unable to determine from file name for $program\n";
            $retval = 0;
        }
        else {

            $write_text = "Dry run:  $program, $os\n" .
                             "\tFrom file: " . $from_file . "\n" .
                             "\tTo file:   " . $dest_file . "\n";

            if (should_copy($program, $os)) {
                $write_text = $write_text . "\tStatus: COPY\n";
            }
            else {

                $write_text = $write_text . "\tStatus: should not copy\n";
            }

            write_log($logfile, $write_text);
        }

        print $write_text;
    }

    return $retval;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


sub get_destination_file_name {
    my ($program, $os, $type) = @_;

    return _get_copy_file($program, $os, 'to');
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

sub get_from_file_name {
    my ($program, $os, $type) = @_;

    return _get_copy_file($program, $os, 'from');
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


sub should_copy {
    my ($program, $os) = @_;
    my $program_list   = get_program_hash();
    my $retval         = 0;

    if (exists($program_list->{$program}->{$os}) ) {
        if ($program_list->{$program}->{$os} ne "") {
            $retval = 1;
        }
    }

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 is_executable($program)
    returns 1 if the program should be flagged as executable
=cut

sub is_executable {
    my $key    = shift;
    my $retval = 0;
    
    my $program_list = get_program_hash();

    if ( lc ($program_list->{$key}->{'EXECUTE'}) eq "yes" ) {

        $retval = 1;

    }

    return $retval;
    
    
}
#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################

#################################################################################
### Private Methods / Functions #################################################
#################################################################################

=head2 _copy_program($program, $os)
    this is the private method of _copy_program.
    It takes input from $program and $os to determine the from and to files
    It removes the old $to file
    It copies the from file to the $to file
    If all is successful it returns 1, else it returns 0
=cut

sub _copy_program {
    my ($program, $os) = @_;
    my $retval         = 0;

    my $copy_from = get_from_file_name($program, $os);
    my $copy_to   = get_destination_file_name($program, $os);

    if (copy_file($copy_from, $copy_to)) {
        $retval = 1;
    }
    else {
        carp "Unable to copy $copy_from to $copy_to: $!\n";
    }

    if (not set_permissions($copy_to)) {
        carp "Unable to set permissions on $copy_to: $!";
    }

    if (is_executable($program)) {
        if (not set_execute($copy_to)) {
            carp "Unable to set execute on $copy_to: $!";
        }
    }

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _get_copy_file($program, $os, $type, $direction)
    returns the full path to the file name to copy.
    $direction should be either 'from' or 'to'
=cut

sub _get_copy_file {
    my ($program, $os, $direction) = @_;
    my $retval;

    if (lc $direction eq 'from') {

        # determine if it is an exe, then find & return the exe based on the os
        # else return the source file
        if (compile_check($program)) {

            $retval = get_bin_name_with_cvs_path($program, $os);
            #$dist_dir_hash->{'BIN'} . "/" . get_bin_base_name($program, $os);

        }
        else {

            $retval = get_program_source_file($program, $os);

        }

    }
    elsif (lc $direction eq 'to') {

        ## get the to destination directory and file name based on the os

        $retval = get_dest_file_name($program, $os);

    }

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

sub _dest_file_name {
    my $program       = shift;
    my $os            = shift;
    my $program_list  = get_program_hash();
    my $dist_dir      = $program_list->{$program}->{'DEST_PATH'};
    my $retval;

    if (exists($program_list->{$program}->{$os})) {
        return $dist_dir . "/" . $program_list->{$program}->{$os};
    }
    else {
        return 0;
    }

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^






#################################################################################
### End of Private Methods / Functions ##########################################
#################################################################################

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head2 DEVELOPER'S NOTES


=cut


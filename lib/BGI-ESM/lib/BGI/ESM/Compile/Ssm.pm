=head1 TITLE

SSM v2 Compile Module: BGI::ESM::Compile::Ssm

=head1 DESCRIPTION

Use this module when wanting to compile SSM programs.

=head1 USAGE

use BGI::ESM::Compile::Ssm

=head1 TODO



=head1 REVISIONS

CVS Revision: $Revision: 1.67 $
    Date:     $Date: 2007/05/23 23:44:20 $

    #####################################################################
    #  2005-09-01 - nichj - Migrated to Perl Module
    #  2005-09-06 - nichj - minor POD updates
    #  2005-09-06 - nichj - refactored areas, added get_bin_file_name & get_doc_file_name
    #  2005-09-09 - nichj - refactored to do multi-layer hash around program names
    #  2005-09-16 - nichj - adding cvs_commit
    #  2005-09-20 - nichj - updated cvs_commit to use $! for status message
    #  2005-09-22 - nichj - added get_agent_info and send_agent_info files
    #  2005-10-11 - nichj - added alarmpoint_java_client_monitor to list
    #  2005-10-27 - nichj - Added LINUX logic
    #  2005-11-22 - nichj - Added get_compile_ssm_version
    #  2005-12-14 - nichj - Added process.exe for Windows distribution
    #  2005-12-15 - nichj - Added description to main hash
    #  2006-01-19 - nichj - Added SSM_TEST variable.
    #  2006-03-25 - nichj - Added the following programs and config files to the big hash:
    #       -- alarmpoint_phone_monitor
    #       -- send_sms
    #       -- cpu_count.dat
    #       -- filesize.dat
    #       -- fork.dat
    #       -- fork_ignore.dat
    #       -- inet.dat
    #       -- mtu_size.dat
    #       -- ntp_time.dat
	# 		-- cpu_count.monitor
	# 		-- filesize.monitor
	# 		-- inet.monitor
	# 		-- mount.monitor
	# 		-- mtu_size.monitor
	# 		-- ntp_time.monitor
	# 		-- ptree.monitor
	# 		-- qchk
	# 		-- smartaction
	# 		-- testing_generic_port
	# 		-- testing_ldap
	# 		-- testing_rpc
    # 2007-04-11 - nichj / kolosov - added bgi_esm_hbp_emitter to hash
    # 2007-05-24 - nichj - added notify program
    #####################################################################

=cut

#################################################################################
### Package Name ################################################################
package BGI::ESM::Compile::Ssm;
#################################################################################

#################################################################################
### Module Use Section ##########################################################
use 5.008000;
use strict;
use warnings;
use File::stat;
use Data::Dumper;
use File::Basename;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Compile::Common;
use BGI::ESM::Common::Shared qw(os_type check_os);
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::Compile);
#################################################################################

#################################################################################
### Public Exports ##############################################################
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
    doc_check
    doc_pgm
    get_bin_base_file_name
    get_bin_name_with_compile_path
    get_bin_name_with_cvs_path
    get_bin_version
    get_compile_locations
    get_compile_settings
    get_compile_ssm_version
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
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.67 $)[-1];
our $program_list = get_program_hash();
#################################################################################

#################################################################################
# Public Variables
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

=head2 get_compile_ssm_version

    returns a scalar with the version of this module

=cut

sub get_compile_ssm_version {
    return $VERSION;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_cvs_locations($os) {
    returns reference to hash with the following structure:
    $hash = {
                'CVSROOT'         => "cvs root based on os",
                'SSM_BIN'         => "cvs SSM bin directory",
                'SSM_ETC'         => "cvs SSM etc directory",
                'SSM_SRC'         => "cvs SSM source directory",
                'SSM_DOC'         => "cvs SSM doc directory",
                'SSM_LIB'         => "cvs Perl library directory",
                'SSM_BIN_UNIX'    => "cvs SSM bin unix",
                'SSM_BIN_LINUX'   => "cvs SSM bin LINUX",
                'SSM_BIN_WINDOWS' => "cvs SSM bin windows",
                'SSM_ETC_UNIX'    => "cvs SSM etc UNIX",
                'SSM_ETC_LINUX'   => "cvs SSM etc LINUX",
                'SSM_ETC_WINDOWS' => "cvs SSM etc WINDOWS"
            }
=cut

sub get_cvs_locations {
    my $os      = shift;
    my $cvsroot = "";

    $os         = check_os($os);

    $cvsroot = get_cvs_root($os);

    my $cvshash = {
                   'CVSROOT'         => "$cvsroot",
                   'SSM_BIN'         => "$cvsroot/SSM/bin",
                   'SSM_ETC'         => "$cvsroot/SSM/etc",
                   'SSM_SRC'         => "$cvsroot/SSM/src",
                   'SSM_DOC'         => "$cvsroot/SSM/doc",
                   'SSM_LIB'         => "$cvsroot/BGI-ESM/lib",
                   'SSM_TEST'        => "$cvsroot/SSM/t",
                   'SSM_BIN_UNIX'    => "$cvsroot/SSM/bin/solaris",
                   'SSM_BIN_LINUX'   => "$cvsroot/SSM/bin/linux",
                   'SSM_BIN_WINDOWS' => "$cvsroot/SSM/bin/windows",
                   'SSM_ETC_UNIX'    => "$cvsroot/SSM/etc/solaris",
                   'SSM_ETC_LINUX'   => "$cvsroot/SSM/etc/linux",
                   'SSM_ETC_WINDOWS' => "$cvsroot/SSM/etc/windows"
                  };

    return $cvshash;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_program_hash($source_dir)
    returns reference to array with list of programs and their associated
     source file name
=cut

sub get_program_hash {
    my ($source_dir, $bin_dir, $lib_dir, $doc_dir) = get_compile_locations();
    my $etc_dir_sol  = get_etc_locations('UNIX');
    my $etc_dir_win  = get_etc_locations('WINDOWS');
    my $etc_dir_lin  = get_etc_locations('LINUX');

    #adding to support copying directly from source
    my $cvs_location = get_cvs_locations();

    my $bin_dir_win  = $cvs_location->{'SSM_BIN_WINDOWS'};
    my $bin_dir_sol  = $cvs_location->{'SSM_BIN_UNIX'};
    my $bin_dir_lin  = $cvs_location->{'SSM_BIN_LINUX'};
    my $ssm_test_dir = $cvs_location->{'SSM_TEST'};

    my ($program_list);

    ###### The structure of this hash:
    #  'program name' => {
    #                     'SOURCE'  => "$source_dir/program_source_name" - the source file, based on the current running os",
    #                     'COMPILE' => "yes | no" - is this program compilable
    #                     'PERLDOC' => "yes | no",- should this program be perldoc'd
    #                     'WINDOWS'  => "chk_conf_files.exe",
    #                     'SOLARIS'  => "chk_conf_files"

    $program_list = {
        #####################  PROGRAMS AND COMPILABLES #######################
        'chk_conf_files'    =>
                                {
                                'SOURCE'   => "$source_dir/chk_conf_files.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "chk_conf_files.exe",
                                'LINUX'    => "chk_conf_files",
                                'UNIX'     => "chk_conf_files",
                                'DESCRIPTION' => "",
                                },

        'fileage.monitor'   =>
                                {
                                'SOURCE'   => "$source_dir/fileage.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "fileage.monitor.exe",
                                'LINUX'    => "fileage.monitor",
                                'UNIX'     => "fileage.monitor",
                                'DESCRIPTION' => "",
                                },

        'ptree.monitor'   =>
                                {
                                'SOURCE'   => "$source_dir/ptree.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "ptree.monitor.exe",
                                'LINUX'    => "ptree.monitor",
                                'UNIX'     => "ptree.monitor"
                                },

        'filesize.monitor'   =>
                                {
                                'SOURCE'   => "$source_dir/filesize.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "filesize.monitor.exe",
                                'LINUX'    => "filesize.monitor",
                                'UNIX'     => "filesize.monitor"
                                },

        'filesys.monitor'   =>
                                {
                                'SOURCE'   => "$source_dir/filesys.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "filesys.monitor.exe",
                                'LINUX'    => "filesys.monitor",
                                'UNIX'     => "filesys.monitor",
                                'DESCRIPTION' => "",
                                },

        'filesys.monitor.rewrite'   =>
                                {
                                'SOURCE'   => "$source_dir/filesys.monitor.rewrite.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "filesys.monitor.rewrite.exe",
                                'LINUX'    => "filesys.monitor.rewrite",
                                'UNIX'     => "filesys.monitor.rewrite",
                                'DESCRIPTION' => "",
                                },

        'get_logs'          =>
                                {
                                'SOURCE'   => "$source_dir/get_logs.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "get_logs.exe",
                                'LINUX'    => "get_logs",
                                'UNIX'     => "get_logs",
                                'DESCRIPTION' => "",
                                },

        'get_agent_info'    =>
                                {
                                'SOURCE'   => "$source_dir/get_agent_info.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "get_agent_info.exe",
                                'LINUX'    => "get_agent_info",
                                'UNIX'     => "get_agent_info",
                                'DESCRIPTION' => "",
                                },

        'hostalias'    =>
                                {
                                'SOURCE'   => "$source_dir/hostalias.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "hostalias",
                                'UNIX'     => "hostalias",
                                'DESCRIPTION' => "",
                                },

        'send_agent_info'          =>
                                {
                                'SOURCE'   => "$source_dir/send_agent_info.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "send_agent_info.exe",
                                'LINUX'    => "send_agent_info",
                                'UNIX'     => "send_agent_info",
                                'DESCRIPTION' => "",
                                },

        'addl_notification' =>
                                {
                                'SOURCE'   => "$source_dir/addl_notification.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "addl_notification.exe",
                                'LINUX'    => "addl_notification",
                                'UNIX'     => "addl_notification",
                                'DESCRIPTION' => "",
                                },

        'list_conf_files'   =>
                                {
                                'SOURCE'   => "$source_dir/list_conf_files.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "list_conf_files.exe",
                                'LINUX'    => "list_conf_files",
                                'UNIX'     => "list_conf_files",
                                'DESCRIPTION' => "",
                                },

        'process.monitor'   =>
                                {
                                'SOURCE'   => "$source_dir/process.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "process.monitor.exe",
                                'LINUX'    => "process.monitor",
                                'UNIX'     => "process.monitor",
                                'DESCRIPTION' => "",
                                },

        'powerpath.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/powerpath.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "powerpath.monitor.exe",
                                'LINUX'    => "powerpath.monitor",
                                'UNIX'     => "powerpath.monitor",
                                'DESCRIPTION' => "",
                                },

        'precanned'         =>
                                {
                                'SOURCE'   => "$source_dir/precanned.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "precanned.exe",
                                'LINUX'    => "precanned",
                                'UNIX'     => "precanned",
                                'DESCRIPTION' => "",
                                },

        'ssm_uptime'        =>
                                {
                                'SOURCE'   => "$source_dir/ssm_uptime.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "ssm_uptime.exe",
                                'LINUX'    => "ssm_uptime",
                                'UNIX'     => "ssm_uptime",
                                'DESCRIPTION' => "",
                                },

        'rotate.monitor'    =>
                                {
                                'SOURCE'   => "$source_dir/rotate.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "rotate.monitor.exe",
                                'LINUX'    => "rotate.monitor",
                                'UNIX'     => "rotate.monitor",
                                'DESCRIPTION' => "",
                                },

        'vposend'           =>
                                {
                                'SOURCE'   => "$source_dir/vposend.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "vposend.exe",
                                'LINUX'    => "vposend",
                                'UNIX'     => "vposend",
                                'DESCRIPTION' => "",
                                },

        'check_mssql_jobs'  =>
                                {
                                'SOURCE'   => "$source_dir/check_mssql_jobs.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "check_mssql_jobs.exe",
                                'LINUX'    => "check_mssql_jobs",
                                'UNIX'     => "check_mssql_jobs",
                                'DESCRIPTION' => "",
                                },
        'mssql_job'         =>
                                {
                                'SOURCE'   => "$source_dir/mssql_job.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "mssql_job.exe",
                                'LINUX'    => "mssql_job",
                                'UNIX'     => "mssql_job",
                                'DESCRIPTION' => "",
                                },
        'svcenter_chk'      =>
                                {
                                'SOURCE'   => "$source_dir/svcenter_chk.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "svcenter_chk.exe",
                                'LINUX'    => "svcenter_chk",
                                'UNIX'     => "svcenter_chk",
                                'DESCRIPTION' => "",
                                },
        'get_sybase_logs'   =>
                                {
                                'SOURCE'   => "$source_dir/get_sybase_logs.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "get_sybase_logs.exe",
                                'LINUX'    => "get_sybase_logs",
                                'UNIX'     => "get_sybase_logs",
                                'DESCRIPTION' => "",
                                },

        'get_ssm_common_ver' =>
                                {
                                'SOURCE'   => "$source_dir/get_ssm_common_ver.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "get_ssm_common_ver.exe",
                                'LINUX'    => "get_ssm_common_ver",
                                'UNIX'     => "get_ssm_common_ver",
                                'DESCRIPTION' => "",
                                },

        'performance.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/performance.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "performance.monitor.exe",
                                'LINUX'    => "performance.monitor",
                                'UNIX'     => "performance.monitor",
                                'DESCRIPTION' => "",
                                },

        'performance.capture' =>
                                {
                                'SOURCE'   => "$source_dir/performance.capture.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "performance.capture.exe",
                                'LINUX'    => "performance.capture",
                                'UNIX'     => "performance.capture",
                                'DESCRIPTION' => "",
                                },

        'send_sms' =>
                                {
                                'SOURCE'   => "$source_dir/send_sms.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "send_sms.exe",
                                'LINUX'    => "send_sms",
                                'UNIX'     => "send_sms",
                                'DESCRIPTION' => "Send SMS messages.",
                                },

        'alarmpoint_java_client_monitor' =>
                                {
                                'SOURCE'   => "$source_dir/alarmpoint_java_client_monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "alarmpoint_java_client_monitor.exe",
                                'LINUX'    => "alarmpoint_java_client_monitor",
                                'UNIX'     => "alarmpoint_java_client_monitor",
                                'DESCRIPTION' => "",
                                },

        'alarmpoint_phone_monitor' =>
                                {
                                'SOURCE'   => "$source_dir/alarmpoint_phone_monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "alarmpoint_phone_monitor.exe",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'DESCRIPTION' => "",
                                },

        'cpu_count.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/cpu_count.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "",
                                'UNIX'     => "cpu_count.monitor",
                                'DESCRIPTION' => "",
                                },

        'filesize.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/filesize.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "filesize.monitor.exe",
                                'LINUX'    => "filesize.monitor",
                                'UNIX'     => "filesize.monitor",
                                'DESCRIPTION' => "",
                                },

        'inet.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/inet.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "",
                                'UNIX'     => "inet.monitor",
                                'DESCRIPTION' => "",
                                },

        'mount.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/mount.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "",
                                'UNIX'     => "mount.monitor",
                                'DESCRIPTION' => "",
                                },

        'mtu_size.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/mtu_size.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "",
                                'UNIX'     => "mtu_size.monitor",
                                'DESCRIPTION' => "",
                                },

        'ntp_time.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/ntp_time.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "",
                                'UNIX'     => "ntp_time.monitor",
                                'DESCRIPTION' => "",
                                },

        'ptree.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/ptree.monitor.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "",
                                'UNIX'     => "ptree.monitor",
                                'DESCRIPTION' => "",
                                },

        'smartaction.monitor' =>
                                {
                                'SOURCE'   => "$source_dir/smartaction.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "smartaction.exe",
                                'LINUX'    => "smartaction",
                                'UNIX'     => "smartaction",
                                'DESCRIPTION' => "",
                                },

        'testing_generic_port' =>
                                {
                                'SOURCE'   => "$source_dir/testing_generic_port.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "",
                                'UNIX'     => "testing_generic_port",
                                'DESCRIPTION' => "",
                                },

        'testing_ldap' =>
                                {
                                'SOURCE'   => "$source_dir/testing_ldap.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "",
                                'UNIX'     => "testing_ldap",
                                'DESCRIPTION' => "",
                                },

        'testing_rpc' =>
                                {
                                'SOURCE'   => "$source_dir/testing_rpc.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "",
                                'LINUX'    => "",
                                'UNIX'     => "testing_rpc",
                                'DESCRIPTION' => "",
                                },

        'bgi_esm_ovohbp_emitter' =>
                                {
                                'SOURCE'   => "$source_dir/bgi_esm_ovohbp_emitter.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "no",
                                'WINDOWS'  => "bgi_esm_hbp_emitter.exe",
                                'LINUX'    => "bgi_esm_hbp_emitter",
                                'UNIX'     => "bgi_esm_hbp_emitter",
                                'DESCRIPTION' => "Heartbeat Message Emitter",
                                },

        'notify' =>
                                {
                                'SOURCE'   => "$source_dir/notify.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "notify.exe",
                                'LINUX'    => "notify",
                                'UNIX'     => "notify",
                                'DESCRIPTION' => "Notify",
                                },

        #####################  LIBRARIES ######################################
        'ssm_common.pm'     =>
                                {
                                'SOURCE'   => "$source_dir/ssm_common.pm",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "ssm_common.pm",
                                'LINUX'    => "ssm_common.pm",
                                'UNIX'     => "ssm_common.pm",
                                'DESCRIPTION' => "",
                                },
        'setvar.pm'         =>
                                {
                                'SOURCE'   => "$source_dir/setvar.pm",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "setvar.pm",
                                'LINUX'    => "setvar.pm",
                                'UNIX'     => "setvar.pm",
                                'DESCRIPTION' => "",
                                },
        'parse_alert_config.pl'   =>
                                {
                                'SOURCE'   => "$source_dir/parse_alert_config.pl",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "yes",
                                'WINDOWS'  => "parse_alert_config.pl",
                                'LINUX'    => "parse_alert_config.pl",
                                'UNIX'     => "parse_alert_config.pl",
                                'DESCRIPTION' => "",
                                },
        #####################  HELP, PREVIOUSLY COMPILED PROGRAMS, AND MISC ##
        'vposend_help'      =>
                                {
                                'SOURCE'   => "$source_dir/vposend_help",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'WINDOWS'  => "vposend_help",
                                'LINUX'    => "vposend_help",
                                'UNIX'     => "vposend_help",
                                'DESCRIPTION' => "",
                                },
        'vposend_action_help' =>
                                {
                                'SOURCE'   => "$source_dir/vposend_action_help",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'WINDOWS'  => "vposend_action_help",
                                'LINUX'    => "vposend_action_help",
                                'UNIX'     => "vposend_action_help",
                                'DESCRIPTION' => "",
                                },
        'setvar'            =>
                                {
                                'SOURCE'   => "$source_dir/setvar",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'WINDOWS'  => "setvar",
                                'LINUX'    => "setvar",
                                'UNIX'     => "setvar",
                                'DESCRIPTION' => "",
                                },

        'Process.exe'            =>
                                {
                                'SOURCE'   => "$bin_dir_win/Process.exe",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'WINDOWS'  => "Process.exe",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'DESCRIPTION' => "",
                                },

        #####################  TEST PROGRAMS ##################################
        'SSM-vposend-Gen.test'            =>
                                {
                                'SOURCE'   => "$ssm_test_dir/SSM-vposend-Gen.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "no",
                                'WINDOWS'  => "SSM-vposend-Gen.exe",
                                'LINUX'    => "SSM-vposend-Gen",
                                'UNIX'     => "SSM-vposend-Gen",
                                'DESCRIPTION' => "SSM test generator for vposend",
                                },

        'SSM-vposend-Data_Validate.test'            =>
                                {
                                'SOURCE'   => "$ssm_test_dir/SSM-vposend-Data_Validate.pl",
                                'COMPILE'  => "yes",
                                'PERLDOC'  => "no",
                                'WINDOWS'  => "SSM-vposend-Data_Validate.exe",
                                'LINUX'    => "SSM-vposend-Data_Validate",
                                'UNIX'     => "SSM-vposend-Data_Validate",
                                'DESCRIPTION' => "SSM data validation for vposend test",
                                },


        #####################  SHELL AND BATCH ################################
        'chk_conf_files.sh' =>
                                {
                                'SOURCE'   => "$source_dir/chk_conf_files.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "chk_conf_files.sh",
                                'UNIX'     => "chk_conf_files.sh",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },
        'fileage.monitor.sh' =>
                                {
                                'SOURCE'   => "$source_dir/fileage.monitor.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "fileage.monitor.sh",
                                'UNIX'     => "fileage.monitor.sh",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'filesize.monitor.sh' =>
                                {
                                'SOURCE'   => "$source_dir/filesize.monitor.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "filesize.monitor.sh",
                                'UNIX'     => "filesize.monitor.sh",
                                'WINDOWS'  => ""
                                },

        'ptree.monitor.sh' =>
                                {
                                'SOURCE'   => "$source_dir/ptree.monitor.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "ptree.monitor.sh",
                                'UNIX'     => "ptree.monitor.sh",
                                'WINDOWS'  => ""
                                },

        'filesys.monitor.sh' =>
                                {
                                'SOURCE'   => "$source_dir/filesys.monitor.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "filesys.monitor.sh",
                                'UNIX'     => "filesys.monitor.sh",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'powerpath.monitor.sh' =>
                                {
                                'SOURCE'   => "$source_dir/powerpath.monitor.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "powerpath.monitor.sh",
                                'UNIX'     => "powerpath.monitor.sh",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'performance.capture.sh' =>
                                {
                                'SOURCE'   => "$source_dir/performance.capture.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "performance.capture.sh",
                                'UNIX'     => "performance.capture.sh",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'process.monitor.sh' =>
                                {
                                'SOURCE'   => "$source_dir/process.monitor.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "process.monitor.sh",
                                'UNIX'     => "process.monitor.sh",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'rotate.monitor.sh' =>
                                {
                                'SOURCE'   => "$source_dir/rotate.monitor.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "rotate.monitor.sh",
                                'UNIX'     => "rotate.monitor.sh",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'ssm_reboot_check.sh' =>
                                {
                                'SOURCE'   => "$source_dir/ssm_reboot_check.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "ssm_reboot_check.sh",
                                'UNIX'     => "ssm_reboot_check.sh",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        #'vposend.shell'           =>
        #                        {
        #                        'SOURCE'   => "$source_dir/vposend",
        #                        'COMPILE'  => "no",
        #                        'PERLDOC'  => "no",
        #                        'WINDOWS'  => "",
        #                        'LINUX'    => "vposend",
        #                        'UNIX'     => "vposend",
        #                        'DESCRIPTION' => "VPOSEND shell script that calls vposend after setting path.",
        #                        },
        #

        'get_agent_info.sh' =>
                                {
                                'SOURCE'   => "$source_dir/get_agent_info.sh",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "get_agent_info.sh",
                                'UNIX'     => "get_agent_info.sh",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'chk_conf_files.bat' =>
                                {
                                'SOURCE'   => "$source_dir/chk_conf_files.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "chk_conf_files.bat",
                                'DESCRIPTION' => "",
                                },

        'fileage.monitor.bat' =>
                                {
                                'SOURCE'   => "$source_dir/fileage.monitor.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "fileage.monitor.bat",
                                'DESCRIPTION' => "",
                                },

        'filesize.monitor.bat' =>
                                {
                                'SOURCE'   => "$source_dir/filesize.monitor.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "filesize.monitor.bat"
                                },

        'ptree.monitor.bat' =>
                                {
                                'SOURCE'   => "$source_dir/ptree.monitor.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "ptree.monitor.bat"
                                },

        'filesys.monitor.bat' =>
                                {
                                'SOURCE'   => "$source_dir/filesys.monitor.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "filesys.monitor.bat",
                                'DESCRIPTION' => "",
                                },

        'powerpath.monitor.bat' =>
                                {
                                'SOURCE'   => "$source_dir/powerpath.monitor.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "powerpath.monitor.bat",
                                'DESCRIPTION' => "",
                                },

        'process.monitor.bat' =>
                                {
                                'SOURCE'   => "$source_dir/process.monitor.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "process.monitor.bat",
                                'DESCRIPTION' => "",
                                },

        'processinfo-cleanup.bat' =>
                                {
                                'SOURCE'   => "$source_dir/processinfo-cleanup.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "processinfo-cleanup.bat",
                                'DESCRIPTION' => "",
                                },

        'performance.capture.bat' =>
                                {
                                'SOURCE'   => "$source_dir/performance.capture.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "performance.capture.bat",
                                'DESCRIPTION' => "",
                                },

        'rotate.monitor.bat' =>
                                {
                                'SOURCE'   => "$source_dir/rotate.monitor.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "rotate.monitor.bat",
                                'DESCRIPTION' => "",
                                },

        'ssm_reboot_check.bat' =>
                                {
                                'SOURCE'   => "$source_dir/ssm_reboot_check.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "ssm_reboot_check.bat",
                                'DESCRIPTION' => "",
                                },

        'get_agent_info.bat' =>
                                {
                                'SOURCE'   => "$source_dir/get_agent_info.bat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "get_agent_info.bat",
                                'DESCRIPTION' => "",
                                },

        #####################  CONFIGS ########################################
        'conf_files.dat.unix'     =>
                                {
                                'SOURCE'   => "$etc_dir_sol/conf_files.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "conf_files.dat",
                                'UNIX'     => "conf_files.dat",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'conf_files.dat.windows'        =>
                                {
                                'SOURCE'   => "$etc_dir_win/conf_files.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "conf_files.dat",
                                'DESCRIPTION' => "",
                                },

        'fileage.monitor.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/fileage.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "fileage.dat",
                                'UNIX'     => "fileage.dat",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'fileage.monitor.dat.windows'    =>
                                {
                                'SOURCE'   => "$etc_dir_win/fileage.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "fileage.dat",
                                'DESCRIPTION' => "",
                                },

        'filesize.monitor.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/filesize.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "filesize.dat",
                                'UNIX'     => "filesize.dat",
                                'WINDOWS'  => ""
                                },

        'ptree.monitor.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/fork.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "fork.dat",
                                'UNIX'     => "fork.dat",
                                'WINDOWS'  => ""
                                },

        'ptree.monitor.ignore.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/fork_ignore.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "fork_ignore.dat",
                                'UNIX'     => "fork_ignore.dat",
                                'WINDOWS'  => ""
                                },

        'filesys.monitor.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/filesys.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "filesys.dat",
                                'UNIX'     => "filesys.dat",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'filesys.monitor.dat.windows'    =>
                                {
                                'SOURCE'   => "$etc_dir_win/filesys.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "filesys.dat",
                                'DESCRIPTION' => "",
                                },

        'powerpath.monitor.dat.unix' =>
                                {
                                'SOURCE'   => "$etc_dir_sol/powerpath.dat.san-unix",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "powerpath.dat.san-unix",
                                'UNIX'     => "powerpath.dat.san-unix",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'powerpath.monitor.dat.windows' =>
                                {
                                'SOURCE'   => "$etc_dir_win/powerpath.dat.san-win",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "powerpath.dat.san-win",
                                'DESCRIPTION' => "",
                                },

        'process.monitor.dat.ovo.unix'   =>
                                {
                                'SOURCE'   => "$etc_dir_sol/process.dat.ovo",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "process.dat.ovo",
                                'UNIX'     => "process.dat.ovo",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'process.monitor.dat.ovo.windows' =>
                                {
                                'SOURCE'   => "$etc_dir_win/process.dat.ovo",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "process.dat.ovo",
                                'DESCRIPTION' => "",
                                },

        'ssm_logfiles.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/ssm_logfiles.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "ssm_logfiles.dat",
                                'UNIX'     => "ssm_logfiles.dat",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'ssm_logfiles.dat.windows'    =>
                                {
                                'SOURCE'   => "$etc_dir_win/ssm_logfiles.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "ssm_logfiles.dat",
                                'DESCRIPTION' => "",
                                },

        'rotate.monitor.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/rotate.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "rotate.dat",
                                'UNIX'     => "rotate.dat",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'rotate.monitor.dat.windows'    =>
                                {
                                'SOURCE'   => "$etc_dir_win/rotate.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'     => "rotate.dat",
                                'DESCRIPTION' => "",
                                },

        'reboot.monitor.template.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/reboot.dat.template",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "reboot.dat.template",
                                'UNIX'     => "reboot.dat.template",
                                'WINDOWS'  => "",
                                'DESCRIPTION' => "",
                                },

        'reboot.monitor.template.windows' =>
                                {
                                'SOURCE'   => "$etc_dir_win/reboot.dat.template",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "",
                                'WINDOWS'  => "reboot.dat.template",
                                'DESCRIPTION' => "",
                                },

        'cpu_count.dat.linux'    =>
                                {
                                'SOURCE'   => "$etc_dir_lin/cpu_count.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "cpu_count.dat",
                                'UNIX'     => "",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'filesize.dat.linux'    =>
                                {
                                'SOURCE'   => "$etc_dir_lin/filesize.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "filesize.dat",
                                'UNIX'     => "",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'fork.dat.linux'    =>
                                {
                                'SOURCE'   => "$etc_dir_lin/fork.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "fork.dat",
                                'UNIX'     => "",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'fork_ignore.dat.linux'    =>
                                {
                                'SOURCE'   => "$etc_dir_lin/fork_ignore.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "fork_ignore.dat",
                                'UNIX'     => "",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'inet.dat.linux'    =>
                                {
                                'SOURCE'   => "$etc_dir_lin/inet.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "inet.dat",
                                'UNIX'     => "",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'mtu_size.dat.linux'    =>
                                {
                                'SOURCE'   => "$etc_dir_lin/mtu_size.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "mtu_size.dat",
                                'UNIX'     => "",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'ntp_time.dat.linux'    =>
                                {
                                'SOURCE'   => "$etc_dir_lin/ntp_time.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "ntp_time.dat",
                                'UNIX'     => "",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'fork.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/fork.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "fork.dat",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'fork_ignore.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/fork_ignore.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "fork_ignore.dat",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'inet.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/inet.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "inet.dat",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'mtu_size.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/mtu_size.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "mtu_size.dat",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
                                },

        'ntp_time.dat.unix'    =>
                                {
                                'SOURCE'   => "$etc_dir_sol/ntp_time.dat",
                                'COMPILE'  => "no",
                                'PERLDOC'  => "no",
                                'LINUX'    => "",
                                'UNIX'     => "ntp_time.dat",
                                'WINDOWS'     => "",
                                'DESCRIPTION' => "",
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
                          SOURCE      => "source file"
                          COMPILE     => "yes | no"
                          PERLDOC     => "yes | no"
                          WINDOWS     => "Windows base exe name"
                          LINUX       => "Linux   base exe name"
                          SOLARIS     => "Solaris base exe name"
                          DESCRIPTION => "Description of the program"
                      }
              ';
        print Dumper ($program_list);

    }
    else {

        print "\n\nHere are the list of valid programs:\n\n";

        foreach my $key (sort keys %{$program_list}) {
            print " $key";
            if ($program_list->{'DESCRIPTION'}) {
                print "Description: " . $program_list->{'DESCRIPTION'};
            }
            print "\n";
        }

    }

    return 1;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_compile_locations()
    returns $source_dir, $bin_dir, $lib_dir, $doc_dir
=cut

sub get_compile_locations {
    my $os = shift;
       $os = check_os($os);

    my ($source_dir, $bin_dir, $lib_dir, $doc_dir);

    my $cvsroot = get_cvs_locations($os);

    $source_dir = $cvsroot->{'SSM_SRC'};
    $lib_dir    = $cvsroot->{'SSM_LIB'};
    $doc_dir    = $cvsroot->{'SSM_DOC'};

    if ($os eq 'WINDOWS') {
        $bin_dir  = $cvsroot->{'SSM_BIN_WINDOWS'};
    }
    elsif ( $os eq 'LINUX' ) {
        $bin_dir = $cvsroot->{'SSM_BIN_LINUX'};
    }
    else {
        $bin_dir  = $cvsroot->{'SSM_BIN_UNIX'};
    }

    return ($source_dir, $bin_dir, $lib_dir, $doc_dir);

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
            return "c:/code/vpo/SSM/etc/windows";
        }
        elsif ($os eq 'LINUX') {
            return "c:/code/vpo/SSM/etc/linux";
        }
        else {
            return "c:/code/vpo/SSM/etc/solaris";
        }

    }
    else {

        if ($os eq 'WINDOWS') {
            return "/apps/esm/vpo/SSM/etc/windows";
        }
        elsif ($os eq 'LINUX') {
            return "/apps/esm/vpo/SSM/etc/linux";
        }
        else {
            return "/apps/esm/vpo/SSM/etc/solaris";
        }

    }

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 compile_continue($source_dir, $bin_dir, $lib_dir, $doc_dir)
=cut

sub compile_continue {
  my ($source_dir, $bin_dir, $lib_dir, $doc_dir) = get_compile_locations();
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

  if (not -e $doc_dir)    {
    print "Unable to find doc_dir $lib_dir\n";
    $retval = 0;
  }

  return $retval;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 compile_pgm($program name as found in get_program_hash, $dry, $logfile)

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

        #my $compile      = "$compile_pgm $compile_opts $exe $source_file";
        #write_log($logfile, "compile entry: $compile");
        ##print "\n\tcompile entry: " . $compile . "\n\n";
        #
        #if (not $dry) {
        #  my $status = `$compile`;
        #
        #  write_log($logfile, $status);
        #
        #  print $status . "\n";
        #}
        #
        #my $cvs_checkin_message = "Checking $source_file post-compile in at " . time;
        #my ($cvs_status, $cvs_message) = cvs_commit($exe, $checkin, $cvs_checkin_message, $dry);
        #
        #if ($checkin) {
        #    if (not $cvs_message) { $cvs_message = "unknown message"; }
        #    if (not $cvs_status)  { $cvs_status  = "unknown status";  }
        #    my $cvs_logtext = "CVS Checkin for $exe is $cvs_status: $cvs_message\n";
        #
        #    write_log($logfile, $cvs_logtext);
        #}

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

    my ($source_dir, $bin_dir, $lib_dir, $doc_dir) = get_compile_locations($os);
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
    returns
=cut

sub doc_pgm {
    my ($key, $dry, $logfile) = @_;
    my $retval;

    my ($compile_pgm, $compile_opts) = get_compile_settings();

    my $program_list = get_program_hash();

    if (doc_check($key)) {

        if (-e $program_list->{$key}->{'SOURCE'}) {

          my $source_file      = $program_list->{$key}->{'SOURCE'};

          my $doc_file         = get_doc_file_name($key);

          my $status = perldoc_pgm($source_file, $doc_file, $dry, $logfile);

          #my $doc_line = "$doc_pgm $doc_opts $source_file $doc_file";
          #write_log($logfile, "documentation entry: $doc_line");
          #print "\n\tdocumentation entry: " . $doc_line . "\n\n";
          #
          #if (not $dry) {
          #  my $status = `$doc_line`;
          #
          #  write_log($logfile, $status);
          #
          #  print $status . "\n";
          #  $retval = 1;
          #}

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
    my ($source_dir, $bin_dir, $lib_dir, $doc_dir) = get_compile_locations();
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

    my ($source_dir, $bin_dir, $lib_dir, $doc_dir) = get_compile_locations();

    print "We are using the following locations:\n";
    print "\tsource directory: $source_dir\n";
    print "\tbin directory:    $bin_dir\n";
    print "\tdoc directory:    $doc_dir\n";
    print "\tlib directory:    $lib_dir\n\n";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 print_version($program, $bin)
=cut

sub get_version {
    my ($program, $bin) = @_;
    my ($source_dir, $bin_dir, $lib_dir, $doc_dir) = get_compile_locations();
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
  my ($source_dir, $bin_dir, $lib_dir, $doc_dir) = get_compile_locations();
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

sub version_compare ($) {
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

sub get_source_version ($) {
  my $program = shift;
  my $bin     = 0;

  return get_version($program, $bin);

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_bin_version($program)
=cut

sub get_bin_version ($) {
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
        $bin_location = $cvs_root->{'SSM_BIN_WINDOWS'};
    }
        elsif ($os eq 'LINUX') {
        $bin_location = $cvs_root->{'SSM_BIN_LINUX'};
    }
    else {
        $bin_location = $cvs_root->{'SSM_BIN_UNIX'};
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

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################

#################################################################################
### Private Methods / Functions #################################################
#################################################################################






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


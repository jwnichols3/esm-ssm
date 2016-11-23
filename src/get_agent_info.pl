###################################################################
#
#             File: get_agent_info.pl
#         Revision: 2.50
#
#           Author: Bill Dooley
#
#    Original Date: 11/03
#
#      Description: This program will gather information about the
#                   node to pass back to VPO.
#                   
#           Usage:  get_agent_info.pl  
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  11/03      wpd           <Initial Version>
#  05-2004    jwn           Made some revisions to Windows logic:
#                           Also converted to SSM variables.
#
#  2005-04-12 nichj   2.50: General update to use latest header file
#                           Used print_array
#                           Cleaned up residual code.
#
#####################################################################

$version             = "$0 version 2.50\n";
$program_description = "Get Agent Information";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;

# ===================================================================
# Get Command Line Options
# ===================================================================
GetOptions( "v", "version",
            "h", "help",
            "d", "debug", "debugextensive"
          );

# ===================================================================
# Version Check
# ===================================================================
if ( $opt_v or $opt_version ) { print "$version";
                                exit 0;           }

# ===================================================================
# Help Check
# ===================================================================
if ( $opt_h or $opt_help ) {
  usage();
  exit 0;
}

# ===================================================================
# Set up the standard variables
# ===================================================================
get_ssm_vars();

# ===================================================================
# Incorporate the common functions
# ===================================================================
get_ssm_common_functions();

# ===================================================================
# Determine Debug settings
# ===================================================================
## Calling the check_debug_settings will evaluate the command line options and the debug files
## $debug and/or $debug_extensive are set to true if the corresponding setting is true

$DEBUG_FILENAME           = "get_agent_info.debug";                 
$DEBUG_EXTENSIVE_FILENAME = "get_agent_info.debugextensive";        
check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");


# ===================================================================
# ===================================================================
# Begining of Main
# ===================================================================
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

$status_file = "$SSM_LOGS" . "get_agent_info.status";
status_report("$program_description", "$status_file", "start");

$disp_date = get_display_date();

#
# Print Run Time information
#

print "*** This file was create on \n";
print "*** $disp_date\n";
print "*** on $HOSTNAME\n\n";

#
# Print Agent Information
#
print "*****************************\n";
print "*** vpo agent information ***\n";
print "*****************************\n";

#
# Show templates assigned to agent
#
@template = `$OpC_BIN/opctemplate`;
@template = trim(@template);
#chomp(@template);
print "\n\n== Template Information ==\n\n";
print "\n\nTemplates assigned to $HOSTNAMEn\n";
print_array(@template);

# This section is being commented out because the interrogation program
# is not getting past this on some systems.  --jwn 05-2004
#
# Show agent queue lengths
#
# @queue = `$SSM_BIN/qchk agent`;
# print "\n\n== VPO Agent Queue lenghts for $HOSTNAME ==\n\n";
# print " @queue";

#
# Show the agent status
#
@status = `$OpC_BIN/opcagt -status`;
print "\n\n== VPO Agent Status for $HOSTNAME ==\n\n";
print_array(@status);

#
# Show the agent configuration information
#
$nodeinfo_file = $OpC_CONF . "nodeinfo";
@nodeinfo      = read_file_contents("$nodeinfo_file");
print "\n\n== Contents of $nodeinfo_file ==\n\n";
print_array(@nodeinfo);

$opcinfo_file = $OpC_INSTALL . "opcinfo";
@opcinfo      = read_file_contents("$opcinfo_file");
print "\n\n== Contents of $opcinfo_file ==\n\n";
print_array(@opcinfo);

@conf = `$LL $OpC_CONF`;
print "\n\n== Files in $OpC_CONF ==\n\n";
print_array(@conf);

$mgrconf_file = "$OpC_CONF/mgrconf";
print "\n\n== Contents of $mgrconf_file ==\n\n";
if ( -e "$mgrconf_file" ) {
   @mgrconf = read_file_contents("$OpC_CONF/mgrconf");
   print_array(@mgrconf);
} else {
   print "    Issue! The file does not exist.  Check agent installation.\n\n";
}

$primmgr_file = "$OpC_CONF/primmgr" ;
if ( -e "$primmgr_file" ) {
   @primmgr = read_file_contents("$primmgr_file");
   print "\n\n== Contents of $primmgr_file ==\n\n";
   print_array(@primmgr);
}

#
# Display the SSM monitoring information
#
print "\n";
print "*******************************************\n";
print "*** self service monitoring information ***\n";
print "*******************************************\n\n";

@monitor_programs = qw(
   vposend filesys.monitor get_logs fileage process.monitor ssm_uptime powerpath.monitor
   rotate.monitor chk_conf_files precanned addl_notification
   );

foreach $monitor_command (@monitor_programs) {
   @capture = `$SSM_BIN/$monitor_command -v`;
   print_array(@capture);
}
#
# Show the configuration files
#
@process   = `$SSM_BIN/list_conf_files --monitor_prefix=process`;
@service   = `$SSM_BIN/list_conf_files --monitor_prefix=service`;
@filesys   = `$SSM_BIN/list_conf_files --monitor_prefix=filesys`;
@fileage   = `$SSM_BIN/list_conf_files --monitor_prefix=fileage`;
@mail      = `$SSM_BIN/list_conf_files --monitor_prefix=email`;
@ppath     = `$SSM_BIN/list_conf_files --monitor_prefix=powerpath`;
@rotate    = `$SSM_BIN/list_conf_files --monitor_prefix=rotate`;
@get_logs  = `$SSM_BIN/list_conf_files --monitor_prefix=get_logs`;
@mssql_job = `$SSM_BIN/list_conf_files --monitor_prefix=mssql_job"`;
@svcenter  = `$SSM_BIN/list_conf_files --monitor_prefix=svcenter"`;

print "\n\nContents of ssm configuration files for $HOSTNAME\n\n";
print_array(@filesys);
print_array(@fileage);
print_array(@mail);
print_array(@process);
print_array(@service);
print_array(@ppath);
print_array(@rotate);
print_array(@get_logs);
print_array(@mssql_job);
print_array(@svcenter);

#
# Show OS level Information
#

print "\n";
print "************************************************************\n";
print "***            Operating System information              ***\n";
print "***                                                      ***\n";
print "*** NOTE: the operating system information is a snapshot ***\n";
print "*** and should not be used for real-time troubleshooting ***\n";
print "*** purposes.                                            ***\n";
print "************************************************************\n\n";

if ( "$OS" eq "SunOS" ) {
   print "== OS Information ==\n\n";
   @sys = `uname -X`;
   print_array(@sys);
   print "\n\n";
   print "== Kernel Information ==\n\n";
   @kernel = `grep "set " /etc/system |grep -v "^\*"`;
   print "\n\nKernel parameters set on $HOSTNAME\n\n";
   print_array(@kernel);
   print "\n\n";
   print "== Process Information ==\n\n";
   @process = `ps -ef`;
   print_array(@process);
}

if ( "$platform" eq "MSWin32" ) {
   print "== OS Information ==\n\n";
  # the script that runs this executes a program that lists
  #  various OS things.  This script sends its output to a file
  #  called cmd_results.
   @sys = read_file_contents("cmd_results");
   print_array(@sys);
   #foreach $sys (@sys) {
   #   chomp($sys);
   #   ($chk, $rest) = split(/ /,$sys);
   #     print "$sys\n";
   #}
   print "\n\n";
   
   print "== Process and Service Information ==\n\n";
   @process = `$NT_PS`;
   @service = `$PS`;
   print_array(@process);
   print "\n\n";
   print_array(@service);
}

# 
# show Environment Variables
#

print "\n\n== Environment Variables ==\n\n";
if ( "$platform" eq "MSWin32" ) {
   print "\{Output of set\}\n\n";
   @set = `set`;
   print_array(@set);
#   foreach $set (@set) {
#      chomp ($set);
#      $len = length($set);
#      if ($len > 300) {
#         $set = "   ** line is too long - Stopping Display of set command **";
#         print "$set\n";
#         last;
#      }
#      print "$set\n";
#   }
} else {

   @env = `env`;
   print "\{Output of env\}\n\n";
   print_array(@env);
   
}

# 
# show Disk Space Information
#

print "\n\n== Disk Space Information ==\n\n";
@disk = `$DF`;
print_array(@disk);

status_report("$program_description", "$status_file", "end_pass");
print "\n$program_description completed successfully\n";
exit 0;


# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# ===================================================================
# ===================================================================
# End of Main
# ===================================================================
# ===================================================================


# ===================================================================
# Beginning of Functions
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
  
Program USAGE:

get_agent_info --debug | --debug_extensive | --help | --version

";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_ssm_vars()
#  this function is called to setup all standard variables.
# -------------------------------------------------------------------
sub get_ssm_vars {
   $platform = "$^O";
   chomp ($platform);
   
   if ( "$platform" eq "MSWin32" ) {
     # Windows Platform
     $ov_dir    = $ENV{"OvAgentDir"};
     
     if ( "$ov_dir" eq "" ) {
        $ov_dir = "c:/usr/OV";
     }
     
     require      $ov_dir . "/bin/OpC/cmds/setvar.pm";
     $vposend   = $ov_dir . "/bin/opc/cmds/vposend.exe";
      
    } elsif ( "$platform" eq "aix" ) {
     # AIX Platform  
     require      "/var/lpp/OV/OpC/cmds/setvar.pm";
     $vposend   = "/var/lpp/OV/OpC/cmds/vposend";
   
    } else {
     # Everything else, assume Solaris
     require      "/var/opt/OV/bin/OpC/cmds/setvar.pm";
     $vposend   = "/var/opt/OV/bin/OpC/cmds/vposend";
   }
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_ssm_common_functions()
#  this function is called to incorporate all ssm common functions
# -------------------------------------------------------------------
sub get_ssm_common_functions {
   my $ssm_common_functions_file = $SSM_BIN . "ssm_common.pm";
   
   if (-e $ssm_common_functions_file) {
      require $ssm_common_functions_file;
   }
   
   if ($debug) { print " Incorporated $ssm_common_functions_file\n"; }
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


# ===================================================================
# End of Functions
# ===================================================================

# ===================================================================
# Developer's Notes
#  insert any comments or thought processes here
# ===================================================================

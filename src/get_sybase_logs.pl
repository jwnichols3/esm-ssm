###################################################################
#
#             File: get_sybase_logs.pl
#         Revision: 1.0
#
#           Author: Bill Dooley
#          Company: Pepperweed Consulting, LLC
#                   © Pepperweed Consulting, LLC
#
#    Original Date: 04/03
#
#      Description: This program will return the names of the sybase
#                   logfiles that are to be monitored.
#                   
#           Usage:  get_sybase_logs
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  04/03      wpd           <Initial Version>
#####################################################################

use Getopt::Std;

getopts('v,d');
$version = "$0 version 1.00\n";
if ( $opt_v ) { die $version }

$debug = "N";
if ( $opt_d ) { $debug = "Y"; }

# ===================================================================
# Begining of Main
# ===================================================================

#
# Set up the standard variables
#
$platform = "$^O";
chomp ($platform);

if ( "$platform" eq "MSWin32" ) {
   $ov_dir = $ENV{"OvAgentDir"};
   if ( "$ov_dir" eq "" ) {
      $ov_dir = "c:\\usr\\OV";
   }
   require $ov_dir . "/bin/OpC/cmds/setvar.pm";
} elsif ( "$platform" eq "aix" ) {
   require "/var/lpp/OV/OpC/cmds/setvar.pm";
} else {
   require "/var/opt/OV/bin/OpC/cmds/setvar.pm";
}

#
# Get the files in /opt/home/sybase/etc/syb_errlogs or
#                  /apps/home/sybase/etc/syb_errlogs
#

if ( -e "/opt/home/sybase/etc/syb_errlogs" ) {
   $SYBASE_POINTERS = "/opt/home/sybase/etc/syb_errlogs";
} else {
   $SYBASE_POINTERS = "/apps/home/sybase/etc/syb_errlogs";
}

if ( "$debug" eq "Y" ) {
   print "Getting logfiles from $SYBASE_POINTERS\n";
}

if ( -e "$SYBASE_POINTERS" ) {
   if ( "$debug" eq "Y" ) {
      print "Processing SYB pointer file $PWC_ETC/ssm_pointers\n";
   }
   open (SYB_POINTERS, "$SYBASE_POINTERS");
   @pointers = <SYB_POINTERS>;
   @sybase_logs_pointers = grep(/sybase/, @pointers);
   close(SYB_POINTERS);
   foreach $pointer (@sybase_logs_pointers) {
      chomp($pointer);
      push (@sybase_log_files, "$pointer\n");
   }
}

#
# Get information from $PWC_ETC/process.dat
#

$sybase_conf_file = $PWC_CONF . "syb_errlogs";

if ( "$debug" eq "Y" ) {
   print "Processing standard configuration file $sybase_conf_file\n";
}

if ( -e "$sybase_conf_file" ) {
   push (@sybase_log_files, "$sybase_conf_file\n");
}

#
# Get files from the .ssm directories for a mountpoint
#

if ( "$debug" eq "Y" ) {
   print "Processing configuration files in the for each mount/drive\n";
}

$MountInfo = $PWC_LOGS . "mount.info";
open (MOUNTPOINT, "$MountInfo");
@mountpoints = <MOUNTPOINT>;
close(MOUNTPOINT);

foreach $mount (@mountpoints) {
   chomp($mount);
   if ( "$platform" eq "MSWin32" ) {
      $app_config_file = $mount . "\\ssm\\syb_errlogs";
      if ( -e "$app_config_file" ) {
         if ( "$debug" eq "Y" ) {
            print "Checking for file in $app_config_file\n";
         }
         push (@sybase_log_files, "$app_config_file\n");
      }
   } else {
      $app_config_file = $mount . "/.ssm/syb_errlogs";
      if ( -e "$app_config_file" ) {
         if ( "$debug" eq "Y" ) {
            print "Checking for file in $app_config_file\n";
         }
         push (@sybase_log_files, "$app_config_file\n");
      }
   }
}

#
# Check if any log files have been found
#

$log_found =+ @sybase_log_files;

if ( "$debug" eq "Y" ) {
   print "Log files found = $log_found\n";
   print "Files found are: \n @sybase_log_files";
}

if ( $log_found == 0 ) {
   if ( "$debug" eq "Y" ) {
      print "No logfiles to monitor\n";
   }
   exit 0;
}

#
# Process all the log file configuration files
#

foreach $logfile (@sybase_log_files) {
   chomp($logfile);
   if ( "$debug" eq "Y" ) {
      print "Processing $logfile\n";
   }
   $logfile =~ s/ /\\ /g;
   $logs = $logs . $logfile . " ";
   if ( -e "$logfile" ) { 
      next;
   } else {
      # `touch $logfile`;
   }
}

`echo $logs > $PWC_LOGS/get_sybase_logs`;
print "$logs\n";

exit 0;

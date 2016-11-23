###################################################################
#
#             File: check_mssql_jobs.pl
#         Revision: 1.0
#
#           Author: Bill Dooley
#          Company: Pepperweed Consulting, LLC
#                   © Pepperweed Consulting, LLC
#
#    Original Date: 04/03
#
#      Description: This program will maintain trigger files that 
#                   will be used by the fileage monitor to determine
#                   if an internal mssql job is running too long or
#                   did not start on time.
#                   
#           Usage:  check_mssql_jobs
#      Files Used:  $PWC_HOLD/<job_name>_running_too_long
#                   $PWC_HOLD/<job_name>_has_not_started
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

# print "Setting variables for $platform from setvar.pm\n";

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
# Get the names of the jobs to maintain by running the MSSQL DBA
# supported proc xxxxxxxxxx.  
# The input for the proc is the time (in mm/dd/yyyy hh:mm format)
# of the last run of this program.  The proc will return all the 
# jobs that have started, completed or still running since the 
# time passed.  The output of this proc will be as follows:
#
#    <job_name>,<started>,<completed>
#    job1,1,          # The job is running
#    job2,1,1         # The job has completed
#

#
# Set Time Variables
#

($sec,$min,$hour,$mday) = localtime(time);
if ( "$platform" eq "MSWin32" ) {
   $disp_date = `date/t`;
   chomp($disp_date);
   $chk_date = $disp_date;
} else {
   $disp_date = `date`;
   chomp($disp_date);
   $chk_date = `date +%Y%m%d`;
   chomp($chk_date);
}

$this_run = "$chk_date" . "_" . "$hour:$min:$sec";

if ( "$debug" eq "Y" ) {
   print "The date and time of this run is $this_run\n\n";
   print "Getting the date and time from the last run\n\n";
}

$last_run_file = $PWC_HOLD . "mssql_job_run";

if ( -e "$last_run_file" ) {
   open (LAST_RUN_FILE, "$last_run_file");
   @last_run = <LAST_RUN_FILE>;
   close (LAST_RUN_FILE);
} else {
   @last_run = qw(20030101_00:00:00);
}

if ( "$debug" eq "Y" ) {
   print "The date and time of the last run is $last_run[0]\n\n";
}

#
# Update the last_run_file with the current date and time
#

`echo $this_run > $last_run_file`;

# PUT THE COMMAND HERE passing the $last_run[0] as a parameter
#
#@jobs = `mssql job command with the -t for trusted job`;
@jobs = qw(job1,1, job2,1, job3,1,1);

foreach $job(@jobs) {
   chomp($job);

   ($job_name,$started,$completed) = split(/,/,$job);

   $running_file = $PWC_HOLD . $job_name . "_running_too_long";
   $started_file = $PWC_HOLD . $job_name . "_has_not_started";

   if ( "$debug" eq "Y" ) {
      print "Processing $job - started = $started - completed = $completed\n";
      print "Check files are:\n";
      print "   running - $running_file\n   started - $started_file\n\n";
   }

   if ("$completed" gt "" ) {
      if ( "$debug" eq "Y" ) {
         print "Processing the completion of $job\n";
      }
      unlink $running_file;
   } else {
      #
      # Create the trigger file to indicate the job has started running.
      #
      if ( !-e "$running_file" ) {
         `echo "started" > $running_file`;
      }
   }

   #
   # Update the trigger file to indicate that the job has started
   #
   `echo "started" > $started_file`;

}

exit 0;

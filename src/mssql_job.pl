#!/usr/local/bin/perl
###################################################################
#
#             File: mssql_job.pl
#         Revision: 1.0
#
#           Author: Bill Dooley
#          Company: Pepperweed Consulting
#
#    Original Date: 03/03
#
#      Description: This program will accept the following input:
#                       Server Name
#                       Database Name
#                       Minutes
#                       Type
#                   It will check if an error should be sent based 
#                   on the information in the mssql_job.dat.mssql file.
#                  
#                   
#           Usage:  sql_log_shipping <server> <dbname> <min> <type>
#                    (use $PWC_ETC/mssql_job.dat.mssql)
#
# Revision History:
#
#  Date     Initials   Version     Description of Change
#
#  03/03      wpd        1.00      <Initial Version>
#####################################################################

use Getopt::Std;

getopts('v');
$version = "$0 version 1.10\n";
if ( $opt_v ) { die $version }

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
# Get run time parmameters
#

$in_server = $ARGV[0];
$in_dbname = $ARGV[1];
$in_min    = $ARGV[2];
$in_type   = $ARGV[3];

#
# Set up local variables
#

$now = time;
# print "Now = $now\n";
if ( "$platform" eq "MSWin32" ) {
   $disp_time = `time/t`;
   chomp($disp_time);
   $disp_date = `date/t`;
   chomp($disp_date);
   $chk_date = $disp_date;
   $disp_date = $disp_date . $disp_time;
   # print "Disp_Date = $disp_date\n";
} else {
   $disp_date = `date`;
   chomp($disp_date);
   $chk_date = `date +%Y%m%d`;
   chomp($chk_date);
}

$mssql_job = "$PWC_ETC" . "mssql_job.dat.mssql";

if ( ! -e "$mssql_job" ) {
   exit 1;
}

%opts = (
   "S" => { cl => "-s", lf => "server=" },
   "D" => { cl => "-d", lf => "dbname=" },
   "M" => { cl => "-m", lf => "minutes=", },
   "T" => { cl => "-t", lf => "times=", },
);

#
# Get the files in $PWC_ETC/ssm_pointers
#

if ( -e "$PWC_ETC/ssm_pointers" ) {
   print "Processing pointers\n";
   @fileage_pointers = grep(/mssql_job/, @pointers);
   close(ssm_pointers);
   foreach $pointer (@mssql_job_pointers) {
      chomp($pointer);
      push (@appl_files, "$pointer\n");
   }
}

#
# Get the mssql_job.dat.mssql files to process
#

@conf_files = `$LL $mssql_job`;
chomp(@conf_files);

foreach $conf_file (@conf_files) {
   if ( "$platform" eq "MSWin32" ) {
      $config_file = $PWC_ETC . $conf_file;
   } else {
      $config_file = $conf_file;
   }
   push (@appl_files, "$config_file\n");
}

#
# Get files from the .ssm directories for a mountpoint
#

$MountInfo = $PWC_LOGS . "mount.info";
open (mountpoint, "$MountInfo");
@mountpoints = <mountpoint>;
close(mountpoint);

foreach $mount (@mountpoints) {
   chomp($mount);
   if ( "$platform" eq "MSWin32" ) {
      $app_config_file = $mount . "\\ssm\\mssql_log.dat";
      @app_files = `$LL $app_config_file`;
      chomp(@app_files);
      $app_files_found += @app_files;
      # print "Checking for .ssm using $LL $app_config_file\n";
      if ( $app_files_found > 0 ) {
         foreach $app_file (@app_files) {
            push (@appl_files, "$mount\\ssm\\$app_file\n");
         }
      }
   } else {
      $app_config_file = $mount . "/.ssm/mssql_log.dat";
      @app_files = `$LL $app_config_file 2>/dev/null`;
      chomp(@app_files);
      $app_files_found += @app_files;
      # print "Checking for .ssm in $mount\n";
      if ( $app_files_found > 0 ) {
         foreach $app_file (@app_files) {
            push (@appl_files, "$app_file\n");
         }
      }
   }
}

foreach $config_file (@appl_files) {

   chomp($config_file);
   print "\nProcessing config file $config_file \n";

   open (mssqljobinfo, "$config_file");
   @mssqljobinfo = <mssqljobinfo>;
   close(mssqljobinfo);

   @mssql_rec = grep(/$in_server/, @mssqljobinfo);
   @mssql_rec1 = grep(/$in_dbname/, @mssql_rec);
   $found += @mssql_rec1;
   
   if ( $found > 0 ) {
      foreach $line (@mssql_rec1) {
         chomp($line);

         #
         # Check for blank line
         #
         $line =~ s/^\s+//;
         $blank = (substr($line, 0, 1));
         if ("$blank" eq "") {next;};

         # 
         # Skip the line if it is a comment
         #
         $comment   = (substr($line, 0, 1));
         if ("$comment" eq "#") {next;}
         if ("$comment" eq "\n") {next;}
 
         # print "Processing line $line\n";
         chomp($line);
         @fargs = $line;
         foreach $o ( keys %opts ) {
            $fargs[$fidx] =~ s/$opts{$o}{lf}/\t$opts{$o}{cl}\t/i;
         }

         #
         # Strip leading spaces from each argument
         #
         $fargs[$fidx] =~ s/^\s*//;

         # 
         # Get the arguments from the configuration record into a standard array
         #
         @PARMS = split /\t/,$fargs[$fidx];
    
         #
         # Process the argument array
         #
         $server = $dbname = $min = $time = "";
         foreach $a (@PARMS) { 
            #
            # Strip leading AND trailing spaces per field ...arrrg
            #
            $a =~ s/^\s*(.*?)\s*$/$1/; 
            if ( $arg_cnt == 1 ) {
               #
               # Set the variables used for processing
               # 
               # print "Processing arg $vposend_arg value = $a\n";
               if ( "$mssql_job_arg" eq "-s" ) { $server = "$a"; }
               if ( "$mssql_job_arg" eq "-d" ) { $dbname = "$a"; }
               if ( "$mssql_job_arg" eq "-m" ) { $min = "$a"; }
               if ( "$mssql_job_arg" eq "-t" ) { $time = "$a"; }
               $arg_cnt = 0;
            } else {
               $arg_cnt = 1;
               $mssql_job_arg = $a;
            }
         }

         print "\n\n";
         print "Server=$server DB=$dbname Min=$min Time=$time\n\n";
         print "Input Server=$in_server DB=$in_dbname Min=$in_time Type=$in_type\n";
          
         &chk_file;
      }
   }
}
####################################
#  End of foreach files
####################################

sub chk_file {
   
   print "Checking for error\n";

   $file = $PWC_LOGS . "mssql_job_" . $in_server . "_" . $in_dbname . "_" . $in_type;
   $file_times = $file . ".times";

   if ( -e $file ) {
      #
      # Check number of times going down
      #
      open (file , "$file");
      @file = <file>;
      close(file);
      $chk_cnt = $file[0];
      if ($chk_cnt > $in_min) {
         print "Job is ok now\n";
         unlink $file_times;
         open (file , ">$file");
         print file ("$in_min\n");
         close(file);
         open (file_times, ">>$file_times");
         print file_times ("$in_server $in_dbname $in_type $in_min\n");
         close(file_times);
         exit 1;
      }
      if ( -e $file_times ) {
         open (file_times, "$file_times");
         @file_times = <file_times>;
         close (file_times);
         $file_times_rec += @file_times;
         print "Checking $file_times_rec vs $time\n";
         if ( $file_times_rec >= $time ) {
            print "Processing error for $in_server $in_dbname\n";
            $ERR="Y";
            unlink $file_times;
         }
      }
   }
   open (file , ">$file");
   print file ("$in_min\n");
   close(file);

   open (file_times, ">>$file_times");
   print file_times ("$in_server $in_dbname $in_type $in_min\n");
   close(file_times);

   if ("$ERR" eq "Y") {
      print "Processing error for $in_server $in_dbname\n";
      exit 0;
   }
   exit 1;

} # end of chk_file subroutine

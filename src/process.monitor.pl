###################################################################
#
#             File: process.monitor.pl
#         Revision: 2.51
#
#           Author: Bill Dooley
#
#    Original Date: 08/01
#
#      Description: This program will check the process/services
#                   running on the system against the configuration
#                   in $SSM_ETC/process.dat* and service.dat* files
#                   
#           Usage:  process.monitor.pl  (must run in $SSM_BIN)
#
# Revision History:
#
#  Date     Initials  Vers  Description of Change
#
#  08/01      wpd     1.00  <Initial Version>
#  08/02      wpd           Changed the configuration files to be
#                           SSM like arguments.  Use vposend instead
#                           of opcmsg.
#  01/03      wpd     1.10  Add date/time stamp to vposend calls
#                           Fixed problems.
#  02/04      wpd     1.20  Split out the services to use a
#                           service.dat.* file.
#
#  Jun 2004   jwn     2.00  Changed PWC variables to SSM
#                           Added debug and debug extensive
#                           Lowered the process.info error messages to Minor
#             wpd     2.01  Resolved issue with windows filenames using special characters
#
#  Sep 2004   wpd     2.10: Add ability to check for new source_host
#                           variable.
#            nichj          Added -d / -debug cli option
#                           changed onhostname to source_host
#                           functionalized the source_host processing
#                           added inclusion of ssm_common.pm
#                           added -h / -help usage option
#                           changed to getopt::long
#                           changed to using vposend instead of ssm.log file
#
#  Mar 2005  nichj    2.11: added standard heading structure
#
#  2005-04-06 nichj   2.50: Added status_report functionality.
#
#  2005-04-26 nichj   2.51: Fixed dayofweek issue with multiple records
#                           cleaned up some of the previously commented code.
#
#####################################################################

$version             = "$0 version 2.51\n";
$program_description = "process monitor";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;

# ===================================================================
# Get Command Line Options
# ===================================================================
GetOptions(
            "t", "test",
            "v", "version",
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
# Check debug configuration
# ===================================================================

$DEBUG_EXTENSIVE_ON  = "$SSM_CONF" . "process.monitor.debugextensive";    # if this file is there then debug extensive is on
$DEBUG_ON            = "$SSM_CONF" . "process.monitor.debug";             # if this file is there then debug is on

check_debug_settings($DEBUG_ON, $DEBUG_EXTENSIVE_ON);

# ===================================================================
# Begining of Main
# ===================================================================
if ($debug) { print "=== debug output ===\n\n"; }
if ($debug) { print "\n  Debug: platform = $platform\n"; }

$status_file         = "$SSM_LOGS" . "process.monitor.status";
status_report("$program_description", "$status_file", "start");

%opts = (
   "F" => { cl => "-F", lf => "process="       },
   "n" => { cl => "-n", lf => "servicent="     },
   "I" => { cl => "-I", lf => "pid="           },
   "a" => { cl => "-a", lf => "app=",          },
   "R" => { cl => "-R", lf => "parameters="    },
   "H" => { cl => "-H", lf => "start="         },
   "J" => { cl => "-J", lf => "stop="          },
   "W" => { cl => "-W", lf => "dayofweek="     },
   "D" => { cl => "-D", lf => "description="   },
   "r" => { cl => "-r", lf => "max_runtime="   },
   "A" => { cl => "-A", lf => "action="        },
   "p" => { cl => "-p", lf => "min_running="   },
   "P" => { cl => "-P", lf => "max_running="   },
   "s" => { cl => "-s", lf => "sev="           },
   "z" => { cl => "-z", lf => "severity="      },
   "M" => { cl => "-M", lf => "message_age=",  },
   "E" => { cl => "-E", lf => "error_times="   },
   "S" => { cl => "-S", lf => "service=",      },
   "O" => { cl => "-O", lf => "source_host=",  },
);

#
# Get the time
#
$time                                                   = time;

#
# Set Time Variables
#
$now                                                    = time;
($sec,$min,$hour,$day,$month,$year,$wkday,$julian,$dls) = localtime($time);

if ($debug)                                                          { print "  Debug: hour = $hour. min = $min\n\n"; }

if ( "$platform" eq "MSWin32" ) {
   $disp_time = `time/t`;
   chomp($disp_time);
   $disp_date = `date/t`;
   chomp($disp_date);
   $chk_date  = $disp_date;
   $disp_date = $disp_date . $disp_time;
   
   if ($debug)                                                       { print "Disp_Date = $disp_date\n"; }
   
} else {
   $disp_date = `date`;
   chomp($disp_date);
   $chk_date  = `date +%Y%m%d`;
   chomp($chk_date);
}

#
# Check to see if another instance of the monitor is running
#

$running_status = chk_running("process.monitor");

$ProcessInfo = "$SSM_LOGS" . "process.info";

#
# Gather process/service information
#
if ("$os_ver" eq "B.10.01") {
   
   system "ps -ef >t1";
   open (ps_info, "t1");
   @ps_info = <ps_info>;
   close(ps_info);
   open (processinfo, ">$ProcessInfo");
   
   foreach $ps_rec(@ps_info) {
      chomp($ps_rec);
      $ps_cmd   = substr($ps_rec, 48);
      $date_chk = substr($ps_rec, 26, 1);
      
      if ("$date_chk" ne ":") {
         $time = "23:00:00";
      }
      else {
         $time = substr($ps_rec, 24, 8);
      }
      
      print processinfo ("${time} ${ps_cmd}\n");
   }
   
   close(processinfo);
   
} elsif ("$platform" eq "Linux") {
   
   system "$PS >t1";
   open (ps_info, "t1");
   @ps_info = <ps_info>;
   close(ps_info);
   open (processinfo, ">$ProcessInfo");
   
   foreach $ps_rec(@ps_info) {
      chomp($ps_rec);
      $ps_cmd   = substr($ps_rec, 59);
      $date_chk = substr($ps_rec, 48, 1);
      
      if ("$date_chk" ne ":") {
         $time  = "23:00:00";
      }
      else {
         $time  = substr($ps_rec, 43, 8);
      }
      
      print processinfo ("${time} ${ps_cmd}\n");
   }
   
   close(processinfo);
   
} elsif ("$platform" eq "MSWin32") {
   
   open (processinfo, ">$ProcessInfo");

   chdir "$SSM_BIN";
   print "Running $NT_PS PS = $PS DF = $DF LL = $LL\n";
 
   $process_found = 0;
   
   while ( $process_found < 10 ) {
      @ntprocess      = `$NT_PS`;
      $process_found += @ntprocess;
      print "Processes found $process_found\n";
   }

   foreach $inrec(@ntprocess) {
      $proc = substr($inrec,0,20);
      if ( "$proc" eq "Process             " ) { next; }
      if ( "$proc" eq "System              " ) { next; }
      if ( "$proc" eq "System Idle Process " ) { next; }
      
      $pid_chk      = substr($inrec,25,1);
      
      if ( "$pid_chk" eq " " ) {
         $proc_pid  = substr($inrec,21,4);
         $proc_time = substr($inrec,27,10);
      } else {
         $proc_pid  = substr($inrec,21,5);
         $proc_time = substr($inrec,28,10);
      }
      
      $proc_run_min  = ($now - $proc_time) / 60;
      $proc_run_hour = int($proc_run_min / 60);
      $proc_run_day  = int($proc_run_hour / 24);
      $proc_run_hour = $proc_run_hour - ($proc_run_day * 24);
      $proc_run_min  = int($proc_run_min - ($proc_run_hour * 60) - ($proc_run_day * 24));
      $len           = length($proc_run_day);
      $lenh          = length($proc_run_hour);
      $d1            = substr("00",0,2-$len) . $proc_run_day . "-" . substr("00",0,2-$lenh) . $proc_run_hour . ":" . $proc_run_min . ":" . "00 " . $proc_pid . " " . $proc;
      
      print processinfo ("$d1\n");
      
      if ($debug)                                                    { print "  Debug: Processing $proc $proc_pid $proc_time $proc_run_day $proc_run_hour $proc_run_min $d1\n"; }
      
   }

   @NTSERVICE    = `$PS`;

   @service_rec  = grep(/Started/, @NTSERVICE);
   
   foreach $inrec(@service_rec) {
      $ntservice = substr($inrec,0,60);
      $d1        = "00-00:00:00 0000 " . $ntservice;
      
      print processinfo ("$d1\n");
      
   }
   
   close(processinfo);
   
} else {
   
   system "$PS >$ProcessInfo";
   
}
## end gather section

#
# Process Processes/Services
#

# if the process information isn't there, send an error message.
##
## 2005-04-06: Nichj: Changed to use the status report function
unless (open(processdata, "$ProcessInfo")) {
   
  $errmsg_text = "Cannot open $ProcessInfo.";
  #$MATCH_KEY   = "ESM:ProcessMonitor:major";
  #$message     = "Message from process monitoring $disp_date $disp_time vposend_options: app=esm sev=minor message=$errmsg_text";

  #process_vposend($message);
   
  status_report("$program_description", "$status_file", "end_fail", "$errmsg_text");

  die   ("cannot open input file $ProcessInfo\n");
   
}

@processdata = <processdata>;
close(processdata);

#
# Check if any processes have been captured by making sure the process.info file size is > 0
#
$size = (stat ("$ProcessInfo"))[7];
if ( $size != 0 ) {
   
   if ($debug)                                                       { print "  Debug: valid process.info file size\nCurrent size of $ProcessInfo is $size.\n"; }
   
} else {
   
  ##
  ## 2005-04-06: Nichj: Changed to use the status report function
  $errmsg_text = "Empty $ProcessInfo.";
  #$MATCH_KEY   = "ESM:ProcessMonitor:major";
  #$message     = "Message from process monitoring $disp_date $disp_time vposend_options: app=esm sev=minor message=$errmsg_text";
  #process_vposend($message);
   
  status_report("$program_description", "$status_file", "end_fail", "$errmsg_text");

  exit 1;
   
}

#
# Get files from the .ssm directories for a mountpoint
#
if ( "$platform" eq "MSWin32" ) {
  @config_prefix_list = ( "process", "service" );
} else {
  @config_prefix_list = ( "process" );
}
@appl_files = get_config_files(@config_prefix_list);


print "Process each file\n";

## get each file and process the alert config records
##
foreach $file (@appl_files) {

   print "\n*** Processing configuration file $file\n\n";
   @processconf   = read_file_contents($file);
   #open(processconf, "$file");
   #@processconf   = <processconf>;
   #close(processconf);

   $conf_type     = "Process";
   $conf_type1    = "processes";
   $proc_serv     = grep(/service/,$file);
   
   if ( $proc_serv > 0 ) {
      $conf_type  = "Service";
      $conf_type1 = "services";
   }

   #
   # Process the configuration records for each file
   #
   ($sec,$min,$hour,$day,$month,$year,$wkday,$julian,$dls) = localtime($time);
   #
   # Check the day of week and set $wkday to readable format.
   #
   if (      $wkday == 0 ) {
      $wkday = "sun";
   } elsif ( $wkday == 1 ) {
      $wkday = "mon";
   } elsif ( $wkday == 2 ) {
      $wkday = "tue";
   } elsif ( $wkday == 3 ) {
      $wkday = "wed";
   } elsif ( $wkday == 4 ) {
      $wkday = "thu";
   } elsif ( $wkday == 5 ) {
      $wkday = "fri";
   } else {
      $wkday = "sat";
   }
   
   foreach $line (@processconf) {
      
      
      chomp($line);
      
      #
      # Skip the line if it is a comment
      #
      $comment     = (substr($line, 0, 1));
      if ("$comment" eq "#") { next; }

      #
      # Check for blank line
      #
      if ($debug)                                                    { print "Processing $line\n\n"; }
      
      $line  =~ s/^\s+//;
      $blank =  (substr($line, 0, 1));
      if ("$blank" eq "") { next; };

      ##
      ## Clear settings for each run: Standard variables
      ##
      $file = $appl = $age = $action                                             = "";
      $dayofweek = $appl = $desc = $cmd = $severity = $Service                   = "";
      $start = $stop = $Error_Times = $ITO_AGE = $source_host                    = "";
      
      ##
      ## Clear settings for each run: Process monitor specific
      $pid = $NTservice = $process = $runtime = $maxtime = $min_proc = $max_proc = "";

      if ($debug)                                                    { print "Process line $line\n"; }

      @fargs = $line;
      foreach $o ( keys %opts ) {
         $fargs[$fidx] =~ s/$opts{$o}{lf}/\t$opts{$o}{cl}\t/i;
      }

      #
      # Strip leading spaces from each argument
      #
      $fargs[$fidx]    =~ s/^\s*//;

      #
      # Get the arguments from the configuration record into a standard array
      #
      @PARMS           =  split /\t/,$fargs[$fidx];

      #
      # Process the argument array
      #
      
      foreach $a (@PARMS) {
         #
         # Strip leading AND trailing spaces per field ...arrrg
         #
         $a =~ s/^\s*(.*?)\s*$/$1/;
         
         if ( $arg_cnt == 1 ) {
            #
            # Set the variables used for processing
            #
            if ($debug)                                              { print "  Debug: Processing arg $vposend_arg value = $a\n"; }
            
            if ( "$vposend_arg" eq "-F" ) { $process     = "$a";               }
            if ( "$vposend_arg" eq "-n" ) { $process     = "$a";               }
            if ( "$vposend_arg" eq "-I" ) { $pid         = "$a";               }
            if ( "$vposend_arg" eq "-a" ) { $appl        = lc($a);             }
            if ( "$vposend_arg" eq "-R" ) { $runtime     = $a;                 }
            if ( "$vposend_arg" eq "-H" ) { $start       = $a;                 }
            if ( "$vposend_arg" eq "-J" ) { $stop        = $a;                 }
            if ( "$vposend_arg" eq "-W" ) { $dayofweek   = $a;                 }
            if ( "$vposend_arg" eq "-D" ) { $desc        = "$a";               }
            if ( "$vposend_arg" eq "-r" ) { $maxtime     = "$a";               }
            if ( "$vposend_arg" eq "-A" ) { $cmd         = "action=" . lc($a); }
            if ( "$vposend_arg" eq "-p" ) { $min_proc    = "$a";               }
            if ( "$vposend_arg" eq "-P" ) { $max_proc    = "$a";               }
            if ( "$vposend_arg" eq "-s" ) { $severity    = lc($a);             }
            if ( "$vposend_arg" eq "-z" ) { $severity    = lc($a);             }
            if ( "$vposend_arg" eq "-M" ) { $ITO_AGE     = $a;                 }
            if ( "$vposend_arg" eq "-E" ) { $Error_Times = $a;                 }
            if ( "$vposend_arg" eq "-S" ) { $Service     = $a;                 }
            if ( "$vposend_arg" eq "-O" ) { $source_host = $a;                 }
            $arg_cnt     = 0;
            
         } else {
            
            $arg_cnt     = 1;
            $vposend_arg = $a;
            
         }
      } # end processing the configuration records for each file
      
      chomp ($source_host);
  
      # Source Host Check - if source_host_check returns 1 the source_host option matches
      if (source_host_check($source_host)) {
         if ($debug_extensive) { print " match on source host: $source_host\n"; }
      } else {
         if ($debug_extensive) { print " no match on source host: $source_host\n"; }
         next;
      }

      # set the defaults
      #
      if ("$process"      eq "")        {
         $process     = $NTservice;
      }
      
      if ("$start"        eq "")        {
         $start       = "00";
      }
      
      if ("$stop"         eq "")        {
         $stop        = "24";
      }
      
      if ("$dayofweek"    eq "all")     {
         $dayofweek   = "sun mon tue wed thu fri sat";
      }
      
      if ("$dayofweek"    eq "")        {
         $dayofweek   = "sun mon tue wed thu fri sat";
      }
      
      if ("$maxtime"      eq " ")       {
         $maxtime     = "";
      }

      if ($desc           eq "")        {
         
         if ( $pid        eq "" ) {
            $desc     = "$process $runtime";
         } else {
            $desc     = "$pid $runtime";
         }
      }
      
      if ("$min_proc"     eq ""
           && "$max_proc" gt "")        {
         $min_proc    = 0;
      }
      
      if ("$max_proc"     eq ""
           && "$min_proc" gt "")        {
         $max_proc    = 999;
      }
      
      chomp($severity);
      if ( "$severity"    eq "" )       {
         $severity    = "major";
      }
      
      if (    "$severity" ne "critical"
           && "$severity" ne "major"
           && "$severity" ne "minor"
           && "$severity" ne "warning"
           && "$severity" ne "normal" ) {
         $severity    = "major";
      }
      
      chomp($ITO_AGE);
      if ( "$ITO_AGE"     eq "" )       {
         $ITO_AGE     = "60";
      }
      
      chomp($Error_Times);
      if ( "$Error_Times" eq "" )       {
         $Error_Times = "0";
      }
      
      chomp($Service);
      if ( "$Service" eq "" )           {
         $Service     = "os";
      }

      $maxtime_err = "N";
      $runtime_err = "N";
      #
      # Check if within start and stop monitor times
      #
      # If stop time is > than start time then add 24 hours to stop
      # time and to the hour to handle next day processing.
      #
      if ($stop < $start) {
        
         $stop = $stop + 24;
         
         if ($hour < $start) {
            $hour = $hour + 24;
         }
         
      }

      # print "check for Process $process PID $pid Start $start Stop $stop Hour $hour \n";

      $dayofweek =~ s/,/ /g;
      $dayofweek =  lc($dayofweek);

      @dayofweek =  "";
      push(@dayofweek, "$dayofweek");

      $dw_found  = grep(/$wkday/, @dayofweek);

      if ($debug)                                                    { print "  Debug: Checking for $wkday in @dayofweek start=$start stop=$stop hour=$hour\n"; }
      
      if ($debug_extensive) {
                                                                       print "  \n";
                                                                       print "  debug variable: process     = $process     \n";   
                                                                       print "  debug variable: pid         = $pid         \n";   
                                                                       print "  debug variable: appl        = $appl        \n"; 
                                                                       print "  debug variable: runtime     = $runtime     \n";     
                                                                       print "  debug variable: start       = $start       \n";     
                                                                       print "  debug variable: stop        = $stop        \n";     
                                                                       print "  debug variable: dayofweek   = $dayofweek   \n";     
                                                                       print "  debug variable: desc        = $desc        \n";   
                                                                       print "  debug variable: maxtime     = $maxtime     \n";   
                                                                       print "  debug variable: cmd         = $cmd         \n"; 
                                                                       print "  debug variable: min_proc    = $min_proc    \n";   
                                                                       print "  debug variable: max_prox    = $max_proc    \n";   
                                                                       print "  debug variable: severity    = $severity    \n"; 
                                                                       print "  debug variable: ito_age     = $ITO_AGE     \n";     
                                                                       print "  debug variable: errortimes  = $Error_Times \n";     
                                                                       print "  debug variable: service     = $Service     \n";
                                                                       print "  debug variable: Source Host = $source_host\n";
                                                                       print "  \n";
      }

      # if within the start/stop hours and within day of week.
      if (    ($hour >= $start)
           && ($hour <  $stop )
           && ($dw_found > 0  )) {
         #
         # Check process data
         #
         if ( $pid eq "" ) {
            @process_rec  = grep(/$process/, @processdata);
         } else {
            @process_rec  = grep(/$pid/, @processdata);
         }
         #
         # Check if run time parameters are specified.
         #
         if ("$runtime" ne "") {
            
            if ($debug)                                              { print "  Debug: checking for runtime parms $runtime\n\n"; }
            
            @process_rec  = grep(/$runtime/, @process_rec);
         }
         
         $num_process  = 0;
         $run_day      = $run_hour = $run_min = 0;
         $num_process += @process_rec;
         
         if ($debug)                                                 { print "  Debug: Found $num_process occurrances of $process\n\n"; }
         
         $chk_days     = (substr($process_rec[0],2,1));
         if ("$os" eq "HP-UX") {
            
            if ("$chk_days" eq "-") {
               
               $process_time = ( substr($process_rec[0],0,11));
               $process_cmd  = ( substr($process_rec[0],12)  );
               $run_day      = ((substr($process_time,0,2)   ) * 24) * 60;
               $run_hour     = ( substr($process_time,3,2)   ) * 60;
               $run_min      =   substr($process_time,6,2);
               
            } else {
               
               $process_time = (substr($process_rec[0],0,8));
               $process_cmd  = (substr($process_rec[0],9)  );
               $run_day      = 0;
               
               if ("$os_ver" eq "B.10.01") {
                  $run_hour = (substr($process_time,0,2));
                  $run_min  = substr($process_time,3,2);
                  
                  if ($debug)                                        { print "  Debug: Hour=$run_hour . $hour. Min=$run_min . $min\n\n"; }
                  
                  if ($hour < $run_hour) {
                     $run_hour = (($hour + 24) - $run_hour) * 60;
                  } else {
                     $run_hour = ($hour - $run_hour) * 60;
                  }
                  
                  if ($min < $run_min) {
                     $run_min  = (($min + 60) - $run_min);
                     $run_hour = ($run_hour - 60);
                  } else {
                     $run_min  = ($min - $run_min);
                  }
                  
               } else {
                  
                  $run_hour = (substr($process_time,0,2)) * 60;
                  $run_min  =  substr($process_time,3,2);
               }

               if ($debug)                                           { print "  Debug: time=$process_time. hour=$run_hour. min=$run_min\n\n"; }
            }
            
         } else {
            
            $process_time = ( substr($process_rec[0],0,11));
            $process_pid  = ( substr($process_rec[0],12,5));
            $process_cmd  = ( substr($process_rec[0],18)  );
            $run_day      = ((substr($process_time,0,2)   ) * 24) * 60;
            $run_hour     = ( substr($process_time,3,2)   ) * 60;
            $run_min      =   substr($process_time,6,2);
         }
            
         chop($process_cmd);

         if ("$process_cmd" ne "") {
            #
            # Calculate total run time here (total_min)
            #
            $total_min = $run_day + $run_hour + $run_min;
            
            if ($debug)                                              { print "  Debug: check elasped_time $total_min run_day=$run_day. run_hour=$run_hour. run_min=$run_min. against $maxtime\n"; }
            if ($debug)                                              { print "  Debug: for $process_time\n\n"; }
            
            if ($total_min >= $maxtime  && $maxtime > 0) {
               $errmsg      = "$conf_type $desc is running longer than configuration allows. Total minutes = $total_min on server $HOSTNAME";
               $running_err = "Y";
               
            } elsif ($maxtime == 0  && "$maxtime" ne "") {
               
               $errmsg      = "$conf_type $desc is running and should never run on server $HOSTNAME";
               $running_err = "Y";
               
            } elsif ("$min_proc" ne "" || "$max_proc" ne "") {
               
               print "checking number of $conf_type1 for $process $runtime $num_process. range $min_proc - $max_proc\n";
               
               if (${num_process} >= ${min_proc} && ${num_process} <= ${max_proc}) {
                  $errmsg      = "Correct number of $conf_type1 running for  $desc on server $HOSTNAME";
                  $running_err = "N";
               } else {
                  $errmsg      = "Correct number of $conf_type1 not running for $desc.  Number of $conf_type1 running = $num_process.  Minimun = $min_proc.  Maximum = $max_proc on server $HOSTNAME";
                  $running_err = "Y";
               }
               
            } else {
               
               $errmsg      = "$conf_type $desc is running and should be running on server $HOSTNAME";
               $running_err = "N";
            }
            
         } else {
            
            if ("$min_proc" ne "" || "$max_proc" ne "") {
               
               print "checking number of $conf_type1 for $process $runtime $num_process. range $min_proc - $max_proc\n";
               
               if (${num_process} >= ${min_proc} && ${num_process} <= ${max_proc}) {
                  $errmsg          = "Correct number of $conf_type1 running for  $desc on server $HOSTNAME";
                  $running_err     = "N";
               
               } else {
               
                  $errmsg      = "Correct number of $conf_type1 not running for $desc.  Number of $conf_type1 running = $num_process.  Minimun = $min_proc.  Maximum = $max_proc. on server $HOSTNAME";
                  $running_err = "Y";
               }
               
            } elsif ("$maxtime" eq "") {
                  
               if ($debug) { print "  Debug: maxtime=$maxtime. min_proc=$min_proc. max_proc=$max_proc\n\n"; }
                  
               $errmsg      = "$conf_type $desc is down and should be running on server $HOSTNAME";
               $running_err = "Y";
            
            } else {
               
               $errmsg      = "$conf_type $desc is down and should never run or has a maxtime. on server $HOSTNAME";
               $running_err = "N";
            }
         }
         
      } else {
         
         $errmsg = "No check for $desc.  Out of time range.  $start-$stop on days $dayofweek for server $HOSTNAME";
         print "$errmsg\n";
         next;
      }
      
      print "$errmsg\n";
      #
      # Check if error should be reported to vpo
      #
      $process =~ tr/ /./;
      $file    =  "process.$process";

      #
      # If no automatic action is configured then perform a ps -ef on the
      # process
      #
      # Nichj: Commenting out this section as it appears to break
      #
      #if ("$cmd" eq "") {
      #   
      #   if ("$runtime" eq "") {
      #      
      #      $cmd = "$PS |grep $process ";
      #      
      #   } else {
      #      
      #      $cmd = "$PS |grep $process |grep \"$runtime\"";
      #      
      #   }
      #}

      $runtime  =~ tr/ \//../;
      $process  =~ tr/ \//../;
      $file     =~ tr/ \//../;
      $file     =~ s/\\\$/../g;

      if ( $pid eq "" ) {
         
         $holdfile =  $SSM_HOLD . $file;
         $timefile =  $SSM_HOLD . $file . ".times";

      } else {

         $holdfile =  $SSM_HOLD . "process\.pid\." . $pid;
         $timefile =  $SSM_HOLD . "process\.pid\." . $pid . ".times";

      }
      
      print "hold - $holdfile time - $timefile\n";
      
      if ( "$runtime" eq "" ) {
         
         $ito_obj = "$process";
         
      } else {
         
         $ito_obj = "$process $runtime";
         
      }
      
      if ("$runtime" ne "") {

         $holdfile = $holdfile . "." . $runtime;
         $timefile = $timefile . "." . $runtime;
         
         if ($debug)                                                 { print "  Debug: creating hold file $holdfile with runtime $runtime\n"; }
         
      }
      
      if ("$running_err" eq "Y") {
         
         if ($debug)                                                 { print "  Debug: Checking for hold file $holdfile\n"; }
         
         if (-e "$holdfile") {
            
            # Stat the file
            ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $fsize, $atime, $mtime, $ctime, $blk, $blks) = stat ("$holdfile");

            # Check how old the file is in minutes

            $diff          = $now - $mtime;
            $ageInMinutes  = $diff / 60;

            # Check how many minutes since last notification occurred

            $notifydiff    = $now - $atime;
            $notifyMinutes = $notifydiff / 60;

            if ( $ageInMinutes > $ITO_AGE ) {
               
               #
               # check number of times error has occurred today
               #
               if ($debug)                                           { print "  Debug: Check 1 calling check_times. Age=$notifyMinutes vs $Notify_Age\n\n"; }

               &check_times;
               $cmd       =~ s/"//g;
               $MATCH_KEY =  $appl . ":" . $ito_obj . ":" . $severity;

               if ($debug_extensive)                                 { print "  variable cmd after splitting: $cmd\n"; }

               $message = "Message from process monitoring $disp_date $disp_time vposend_options: app=$appl sev=$severity message=$errmsg $cmd";
               
               process_vposend($message);

               system "echo $severity > $holdfile";
               
            } else {
               
               $ageInMinutes = int($ageInMinutes);
               print "Already reported $ageInMinutes minute(s) ago\n";
               
            }
         }
         
         else {
          
            #
            # check number of times error has occurred today
            #
            
            if ($debug)                                              { print "  Debug: Check 2 calling check_times\n"; }
            
            &check_times;
            $cmd       =~ s/"//g;
            $MATCH_KEY =  $appl . ":" . $ito_obj . ":" . $severity;

            if ($debug_extensive)                                    { print "  variable cmd after splitting: $cmd\n"; }

            $message = "Message from process monitoring $disp_date $disp_time vposend_options: app=$appl sev=$severity message=$errmsg $cmd";
            
            process_vposend($message);

            if ($debug)                                              { print "  Debug: Creating hold file for $holdfile\n\n"; }
            
            system "echo $severity > $holdfile";
         }
      
      } else {
         
         if ( -e "$holdfile" ) {
            
            unlink "$holdfile";
            $cmd       =~ s/"//g;
            $severity  =  "normal";
            $MATCH_KEY =  $appl . ":" . $ito_obj . ":" . $severity;
            
         }
         
      }
      
   }
   
}

status_report("$program_description", "$status_file", "end_pass");
   
print "\n$program_description completed successfully\n";
exit 0;

# ===================================================================
# Start of FUNCTIONS
# ===================================================================
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
        $ov_dir = "c:\\usr\\OV";
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
# Function: check_times()
#  
# -------------------------------------------------------------------
sub check_times {
# 
# This subroutine will check how many times the error has been reported today
#

   if ($debug_extensive) { print "\n debug process: check_times sub *** start *** v\n\n"; }

   #
   # Add a date record for this error
   #
   if ($debug_extensive) { print "Check 3 check_times for $timefile\n\n"; }
   
   system "echo $chk_date >> $timefile";
   open (time_file, "$timefile");
   @time_file = <time_file>;
   close(time_file);

   $newfile   = $timefile . "new";
   open (new_file, ">$newfile");

   #
   # Remove all records that are not equal to today
   #
   foreach $date_rec(@time_file) {
      
      chomp($date_rec);
      $date_rec =~ s/ //g;
      $chk_date =~ s/ //g;
      
      if ( "$date_rec" eq "$chk_date" ) {
         print new_file ("$chk_date\n");
      }
      
   }

   close(new_file);
   open (new_file, "$newfile");
   @new_file = <new_file>;
   close(new_file);

   #
   # Count the number of times error occurred today
   #
   
   $no_errors  = 0;
   $no_errors += @new_file;

   if ( $no_errors > $Error_Times && $Error_Times > 0 ) {
      #
      # Put Number of times error to vpo
      #
      $cmd         =~ s/"//g;
      $MATCH_KEY   =  $appl . ":" . $ito_obj . ":times:" . $severity;

      if ($debug_extensive) { print "  variable cmd after splitting: $cmd\n"; }

      $errmsg_text =  "$conf_type errors have occurred $no_errors times for $desc on server $HOSTNAME.";
      
      $message = "Message from process monitoring $disp_date $disp_time via $config_file vposend_options: app=$appl sev=$severity message=$errmsg_text $cmd";
      
      process_vposend($message);

   } 
   
   #
   # Reset the count hold file
   #

   unlink "$timefile";
   
   if ( "$platform" eq "MSWin32" ) {
      `move $newfile $timefile`;
   } else {
      `mv $newfile $timefile`;
   }

   if ($debug_extensive) {
      print "  \n";
      print "  Debug variable: newfile     = $newfile\n";
      print "  Debug variable: date_rec    = $date_rec\n";
      print "  Debug variable: chk_date    = $chk_date\n";
      print "  Debug variable: timefile    = $timefile\n";
      print "  Debug variable: no_erros    = $no_erros\n";
      print "  Debug variable: match_key   = $match_key\n";
      print "  Debug variable: errmsg_text = $errmsg_text\n";
      print "  \n";
   }

   if ($debug_extensive) { print "\n debug process: check_times sub ***  end  *** ^\n\n"; }

}
# End of check_times
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

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
USAGE\n
";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: proces_vposend($vposend_entry)
#  use this function to send the vposend message
#  nichj: this will take the $message input in the format of a SSM logfile
#   split the message apart at 'vposend_options:' and sendrun vposend -f
#   with the everything to the right of 'vposend_options:'
#  this will also write the entry to the ssm.log file for audit/troubleshooting
# -------------------------------------------------------------------
sub process_vposend {
  
   my $message        = $_[0];
   my $dummy          = "";
   my $vposend_params = "";
   
   if ($debug) { print "\n * * * processing error: $message\n"; }
   
   open  (vposend, ">>$SSM_LOG");
   print  vposend ("$message\n");
   close (vposend);
   
   ($dummy, $vposend_params) = split(/vposend_options:/, $message);
   
   $vposend_params           = trim($vposend_params);

   if ($debug_extensive) { print "\n   *** vposend params: $vposend_params\n"; }

   @status = `$vposend -f "$vposend_params"`;
   
   if ($debug_extensive) {
      
      print " vposend status: \n";
      
      foreach $line (@status) {
         print "  $line\n";
      }
      
   }

   return 0;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ===================================================================
# Developer's Comments
# ===================================================================
#
# 2004 09-21: nichj : oh how i bless and curse Komod. Such sweet formatting
#  how can it be so slow at times?
#
#  converting from using the ssm.log file to using straight vposend has been
#  more than painful.  there are at least five different places in this code where
#  where errors are written to ssm.log.
#
#  Ended up assembling the message text and passing it to a newly created function
#  called process_vposend($message).  Original, i know. At some point this must become
#  a global function with all the right parameters.
#
#  Wading through this code it is apparent it needs
#  restructuring.  The good thing is I'll be very knowledgable when we go to
#  redesign.
#

###################################################################
#
#             File: ssm_uptime.pl
#         Revision: 2.50
#
#           Author: John Nichols (original by Bill Dooley)
#
#    Original Date: 2004 Oct 10
#
#      Description: This program returns the uptime in various formats
#                   This program will also determine if a system has been
#                   rebooted and 
#
#           Usage:  ssm_uptime --process=<reboot> 
#                              --output=<output option> --time_format=<output type> --test=<option>
#
#                   if --process=reboot then the program will check the reboot.time file
#                    and send an opcmsg if the current up-time is different than what is in the file
#                    it will then update the reboot.time file.
#
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  2004-09   wpd            <Initial Version>
#
#  09-2004  nichj      1.10 renamed ssm_uptime and rewrote.
#
#  03-2005  nichj      1.11 restructured to use latest standard header,
#                           removed trim function from local
#                           included ssm_common.pm
#
#  2005-03  nichj      1.20 added option to make sure the reboot message
#                           is sent after sufficient time has passed for
#                           the vpo agent to be up and running properly.
#
#  2005-04-07 nichj  2.50: added status reporting
#                          added chk_running
#  
#####################################################################

$version             = "$0 version 2.50\n";
$program_description = "reboot monitor (ssm_uptime)";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;
use Time::Local;
use Time::localtime;

# ===================================================================
# Get Command Line Options
# ===================================================================
GetOptions(
            "v", "version",
            "h", "help",
            "d", "debug",
            "process:s"          => \$process,
            "p:s"                => \$process,
            "time_format:s"      => \$time_format,
            "output:s"           => \$output,
            "o:s"                => \$output,
            "test:s"             => \$test_scenario
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

$DEBUG_EXTENSIVE_ON  = "$SSM_CONF" . "ssm_uptime.debugextensive";
$DEBUG_ON            = "$SSM_CONF" . "ssm_uptime.debug";

check_debug_settings($DEBUG_ON, $DEBUG_EXTENSIVE_ON);

# ===================================================================
# Begining of Main
# ===================================================================

$status_file = "$SSM_LOGS" . "reboot.monitor.status";
status_report("$program_description", "$status_file", "start");

$running_status = chk_running("ssm_uptime");

if ($debug) {
  print "switch option process:     $process\n";
  print "switch option time_format: $time_format\n";
  print "switch option output:      $output\n";
}

# set defaults for command line options
if ($time_format eq "") {
  $time_format = "epoch";
}
if ($output eq "") {
  $output_str = "verbose";
}

# Get the uptime in epoch
$uptime_epoch = get_uptime();

# REBOOT PROCESSING
if ( $process eq "reboot" ) {
   
  reboot_process();
   
} else {

  # DISPLAY PROCESSING
  if ( index($output, "ter") ge 0) {
     $terse      = 1;
  } else {
     $terse      = 0;
     $output_str = "The system $HOSTNAME has been up";
  }
  
  # Format the display options based on the command line input
  if (     index($time_format, "epo") ge 0) {
     
     $display_time = "$uptime_epoch seconds.";
     
  } elsif (index($time_format, "min") ge 0) {
     
     $display_time = time_display($uptime_epoch, "min") . " minutes.";
     
  } elsif (index($time_format, "hou") ge 0) {
     
     $display_time = time_display($uptime_epoch, "hou") . " hour(s).";
     
  } elsif (index($time_format, "day") ge 0) {
     
     $display_time = time_display($uptime_epoch, "day") . " day(s).";
     
  } else {
     
     $display_time = "$uptime_epoch seconds.\n";
     
  }
  
  # Output the information.
  if ($terse) {
     print "$display_time\n";
  } else {
     print "$output_str $display_time\n";
  }
  
}

status_report("$program_description", "$status_file", "end_pass");
 
print "\n$program_description completed successfully\n";
exit 0; 
   
# ===================================================================
# End of Main
# ===================================================================

# ===================================================================
# Beginning of Functions
# ===================================================================

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: Usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
  
Purpose: This program returns the uptime of a system in various formats.

Notes:   All options are case sensitive.

Usage:   ssm_uptime --output=<output option> --time_format=<output type> --test=<option>
                    --process=reboot 
                    --debug --help --version

  
  --output=<output option> : verbose (default) | terse
                             verbose displays more information about the uptime
                             terse returns just the asked for <time format option> with a single word description
   
  --time_format=<time format option>
                           : epo(ch) (default) | min(utes) | hou(rs) | day(s)

  --process=reboot         : used to process and determine if a system has been rebooted.
  
  --test=<option>          : run through a series of tests to determine if the uptime option is working
                             (use for troubleshooting only)
  
  examples:
  > ssm_uptime --output=terse --time_format=min
    returns
     451.12 minutes
  > ssm_uptime --output=verbose --time_format=hours
    returns
     The system rdcuxsrv005 has been up for 56.111 hour(s)

";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_uptime()
#  this function is called to return the epoch in seconds.
#  this function calls the appropriate uptime function based on OS.
# -------------------------------------------------------------------
sub get_uptime {

   my $uptime;
   
   if ("$platform" eq "MSWin32") {
   
      $uptime = uptime_windows("uptime", $test_scenario);
      
   } else {
   
      $uptime = uptime_unix($test_scenario);
   
   }
   
   return $uptime;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: uptime_windows(what_to_return)
#  this will return the uptime in epoch.
#  if what_to_return = boot_time then return the epoch boot_time
#  otherwise return the uptime epoch
# -------------------------------------------------------------------
sub uptime_windows {
   
   my ($uptime, $dummy1, $boot_time_rec, $boot_date, $boot_time, $am,
       $month, $day, $year, $hour, $min, $starttime, $boot_time_epoch,
       $uptime_total_epoch, $what_to_return) = "";
   
   $what_to_return = $_[0];  # if this is boot_time then return epoch of
                             #  of the boot time, otherwise return the uptime
   
   my $sec           = 0;    # default set for second
   my $now           = time;
   
   
   my $CALC_EPOCH_MIN  = 60;                    # number of seconds in a minute
   my $CALC_EPOCH_HOUR = 60 * $CALC_EPOCH_MIN;  # number of seconds in an hour
   my $CALC_EPOCH_DAY  = 24 * $CALC_EPOCH_HOUR; # number of seconds in a day
   

   @uptime = `net statistics workstation`;      # take the output of the command
   
   if ($debug) {
      print "output of raw uptime command\n";
      foreach $line (@uptime) {
         print "$line";
      }
   }
   
   # get everything after the word "since" from the earlier command
   @uptime = grep(/since/,@uptime);
   
   # the first line of @uptime should be the date the system was started
   $uptime = $uptime[0];
   
   # futher filter the date into macro fields
   ($dummy1, $boot_time_rec) = split(/since /,$uptime);
   ($boot_date, $boot_time, $am) = split(/ /,$boot_time_rec);
   
   chomp($am);
   $am = trim($am);
   
   if ($debug) {
         print "epoch now: $now\n";
         print "boot date: $boot_date\n"; 
         print "boot time: $boot_time\n"; 
         print "am/pm:     $am\n";
      }
   
   # split time into specific fields
   ($month, $day, $year) = split(/\//,$boot_date);
   ($hour, $min) = split(/\:/,$boot_time);
   
   # If the am/pm is PM then add 12 hours, unless it is 12PM
   if ($hour le 12) {
    if ( $am eq "PM" ) {
       if ($hour ne 12) {
          if ($debug) { print "In PM: Addmin 12 hours\n"; }
          $hour = $hour + 12;
       }
    }
   }
   
   $month = $month - 1;    # the month value is 0 based, so 1 has to be subtracted.
   $year  = $year  - 1900; # 
   
   if ($debug) {
      print "processed time variables\n";
      print "year:  $year\n";
      print "month: $month\n";
      print "day:   $day\n";
      print "hour:  $hour\n";
      print "min:   $min\n";
      print "sec:   $sec\n";
   }
   
   @starttime = ($sec,$min,$hour,$day,$month,$year);
   
   if ($debug) {
      print "unformatted start time\n";
      foreach $line (@starttime) {
         print "$line\n";
      }
   }
   
   $boot_time_epoch = timelocal(@starttime);
   
   $uptime_total_epoch = $now - $boot_time_epoch;
   $uptime_total_mins  = $uptime_total_epoch / 60;
   $uptime_total_hours = $uptime_total_mins / 60;
   $uptime_total_days  = $uptime_total_hours / 24;

   if ($debug) {
      print "boot time epoch:         ",     $boot_time_epoch,     "\n"; 
      print "uptime total epoch:      ",     $uptime_total_epoch,  "\n";
      print "uptime in minutes:       ", int($uptime_total_mins),  "\n";
      print "uptime in hours:         ", int($uptime_total_hours), "\n";
      print "uptime in days:          ",     $uptime_total_days,  "\n";
   }

   # return epoch time
   if ($what_to_return eq "boot_time") {
      return $boot_time_epoch;
   } else {
      return $uptime_total_epoch;
   }

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: uptime_unix
# call this function to get the uptime in epoch
# -------------------------------------------------------------------
sub uptime_unix {
   
   my $test_option = $_[0];
  
   my ($uptime_str, $find, $location,
       $updays, $uphours, $first, $second, $third,
       $uptime_days_epoch, $uptime_mins_epoch,
       $process_mins_field, $mins_found, $days_found, $days_find_str, $mins_find_str,
       $uptime_total_epoch) = "";

   my $CALC_EPOCH_MIN  = 60;
   my $CALC_EPOCH_HOUR = 60 * $CALC_EPOCH_MIN;
   my $CALC_EPOCH_DAY  = 24 * $CALC_EPOCH_HOUR;
   
   # The actual uptime command
   $uptime_str = `uptime`;
   
   # Test uptime formats
   if ($test_option eq "1") { $uptime_str = "  2:25pm  up 6 day(s), 59 min(s),  5 users,  load average: 1.18, 1.27, 1.44"; }
   if ($test_option eq "2") { $uptime_str = " 10:53pm  up 24 day(s), 14:34,  1 user,  load average: 0.04, 0.07, 0.11";     }
   if ($test_option eq "3") { $uptime_str = " 11:06pm  up 6 min(s),  1 user,  load average: 0.30, 0.52, 0.28";             }
   if ($test_option eq "4") { $uptime_str = "  3:13pm  up 114 day(s),  1:52,  1 user,  load average: 2.10, 2.34, 2.26";    }
   if ($test_option eq "5") { $uptime_str = "  8:00am  up 9 hr(s),  2 users,  load average: 0.09, 0.09, 0.12";             }
   if ($test_option eq "6") { $uptime_str = "  8:01am  up  9:01,  2 users,  load average: 0.15, 0.11, 0.13";               }
   if ($test_option eq "7") { $uptime_str = "  8:01am  up 6 day(s), 9 hr(s),  2 users,  load average: 0.15, 0.11, 0.13";   }
   
   if ($test_option ne "" ) { print "RUNNING TEST OPTION $test_option!\n"; }

   if ($debug) { print "Output of uptime:     $uptime_str\n"; }
   
   $find       = "up";
   $location   = index($uptime_str, $find);
   
   if ($debug) { print "the location of 'up': $location\n"; }
   
   $uptime_str = substr($uptime_str, $location+3);
   
   if ($debug) { print "prior to trimming:    $uptime_str \n"; }
   
   $uptime_str = trim($uptime_str);
   
   if ($debug) { print "post trimming:        $uptime_str \n"; }
   
   ($first, $second, $third) = split/\,/,$uptime_str;
   
   $first  = trim($first);
   $second = trim($second);
   $third  = trim($third);
   
   if ($debug) {
      print " first:  $first\n";
      print " second: $second\n";
      print " third:  $third\n";
   }
   
   #uptime returns one of six formats:
   # 1: x day(s), HH:mm, ...
   # 2: x day(s), y min(s), ...
   # 3: x day(s), k hr(s), ...
   # 4: y min(s), ...
   # 5: k hr(s), ...
   # 6: HH:mm, ...
   
   $days_find_str = "day";
   $mins_find_str = "min";
   $hrs_find_str  = "hr";
   $hhmm_find_str = "\:";
   
   $days_found_first   = index($first,  $days_find_str );
   $hours_found_first  = index($first,  $hrs_find_str  );
   $mins_found_first   = index($first,  $mins_find_str );
   $hhmm_found_first   = index($first,  $hhmm_find_str );
   $hours_found_second = index($second, $hrs_find_str  );
   $mins_found_second  = index($second, $mins_find_str );
   $hhmm_found_second  = index($second, $hhmm_find_str );
   
   
   if      (($days_found_first ge 0) and ($hhmm_found_second  ge 0)) { # SCENARIO 1: x day(s), HH:mm, ...
      
      $updays  = unix_process_days($first);
      $uphours = 0;
      $upmins  = unix_process_mins($second);
      
   } elsif (($days_found_first ge 0) and ($mins_found_second  ge 0)) { # SCENARIO 2: x day(s), y min(s), ...
      
      $updays  = unix_process_days($first);
      $uphours = 0;
      $upmins  = unix_process_mins($second);
      
   } elsif (($days_found_first ge 0) and ($hours_found_second ge 0)) { # SCENARIO 3: x day(s), k hr(s), ...
      
      $updays  = unix_process_days($first);
      $uphours = unix_process_hours($second);
      $upmins  = 0;
      
   } elsif ($mins_found_first  ge 0)                                 { # SCENARIO 4: y min(s), ...
      
      $updays  = 0;
      $uphours = 0;
      $upmins  = unix_process_mins($first);
      
   } elsif ($hours_found_first ge 0)                                 { # SCENARIO 5: k hr(s), ...
      
      $updays  = 0;
      $uphours = unix_process_hours($first);
      $upmins  = 0;
      
   } elsif ($hhmm_found_first  ge 0)                                 { # SCENARIO 6: HH:mm, ...
      
      $updays  = 0;
      $uphours = 0;
      $upmins  = unix_process_mins($first);
      
   } else                                                            { # In the event of an unexpected scenario, return a suitably high number

      return 100000;

   }
   
   if ($debug) { 
      print "numeric days:    $updays\n";
      print "numeric hours:   $uphours\n";
      print "numeric minutes: $upmins\n";
   }
   
   $uptime_days_epoch  = $CALC_EPOCH_DAY * $updays;
   
   $uptime_mins_epoch  = $CALC_EPOCH_MIN * $upmins;
   
   $uptime_hours_epoch = $CALC_EPOCH_HOUR * $uphours;
   
   if ($debug) { 
      print "number of seconds up for $updays days:  $uptime_days_epoch\n";
      print "number of seconds up for $uphours hours:  $uptime_hours_epoch\n";
      print "number of seconds up for $upmins minutes: $uptime_mins_epoch\n";
   }
   
   $uptime_total_epoch = $uptime_days_epoch + $uptime_hours_epoch + $uptime_mins_epoch;
   
  # return value 
  return $uptime_total_epoch;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: unix_process_days
# the passed variable is the string with the days in it.
# -------------------------------------------------------------------
sub unix_process_days {
  if ($debug) { print "\n--- process days ---\n"; }
  my $days = "";
  $days = $_[0];
  ($days) = split/\s/,$days;
  $days = trim($days);
  
  if ($debug) { print "days in process_days: $days\n"; }
  
  return $days;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: unix_process_hours
# the passed variable is the string with the hours in it.
# -------------------------------------------------------------------
sub unix_process_hours {
  if ($debug) { print "\n--- process hours ---\n"; }
  my $hours = "";
  $hours = $_[0];
  ($hours) = split/\s/,$hours;
  $hours = trim($hours);
  
  if ($debug) { print "hours in process_days: $hours\n"; }
  
  return $hours;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: unix_process_mins
# the passed variable is the string with the minutes in it.  There are two formats:
#  y min(s)
#  HH:mm
# Return the number of minutes
# -------------------------------------------------------------------
sub unix_process_mins {
  
  if ($debug) { print "\n--- process mins ---\n"; }

  
  my ($mins, $find_str, $hours_split, $mins_split) = "";
  $mins = $_[0];
  $mins = trim($mins);
  $find_str = ":";
     

  if ( index($mins, $find_str) ge 0 ) { #the format is HH:mm
    
    ($hours_split, $mins_split) = split/\:/,$mins;
    $mins = ($hours_split * 60) + $mins_split;
    
  } else {
    
    if ($debug) { print "mins prior to split: $mins\n"; }
    
    ($mins) = split/\s/,$mins;  # the format is y min(s)

    if ($debug) { print "mins post split: $mins\n"; }
    
  }

  return $mins;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: time_display(epoch, format)
# calculate and return the numeric format of the time requested.
#  Return options are:
#   epo(ch) (default), min(s), hou(rs), day(s)
# -------------------------------------------------------------------
sub time_display {
   
   my $epoch  = $_[0];
   my $format = $_[1];

   my $CALC_EPOCH_MIN  = 60;
   my $CALC_EPOCH_HOUR = 60 * $CALC_EPOCH_MIN;
   my $CALC_EPOCH_DAY  = 24 * $CALC_EPOCH_HOUR;

   # set the default return type
   if ($format eq "") { $format = "epo"; }
   
   if ($debug) { print "time format requested: $format\n"; }

   my $uptime_total_min   = $epoch / $CALC_EPOCH_MIN;
   
   my $uptime_total_hour  = $epoch / $CALC_EPOCH_HOUR;
   
   my $uptime_total_day   = $epoch / $CALC_EPOCH_DAY;

   if ($debug) { 
      print "total number of seconds up for $updays days, $upmins minutes: $uptime_total_epoch\n";
      print "total number of minutes up for $updays days, $upmins minutes: $uptime_total_min\n";
      print "total number of hours   up for $updays days, $upmins minutes: $uptime_total_hour\n";
      print "total number of days    up for $updays days, $upmins minutes: $uptime_total_day\n";
   }

  # return value asked for
  if ( index($format, "epo" ) ge 0 ) { return $epoch;              }
  if ( index($format, "min" ) ge 0 ) { return $uptime_total_min;   }
  if ( index($format, "hou" ) ge 0 ) { return $uptime_total_hour;  }
  if ( index($format, "day" ) ge 0 ) { return $uptime_total_day;   }

  return $epoch;  # if this falls through then return the epoch

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
#
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: reboot_process()
#  
# -------------------------------------------------------------------
sub reboot_process {
   
   my ($boot_time, $uptime_reboot, $reboot_file, $boot_time_from_file, $update, $success) = "";
   
   $uptime_reboot       = get_uptime();
      if ($debug)                                                     { print ":: reboot process - uptime:                   $uptime_reboot\n";       }
      
   $boot_time           = get_boot_time($uptime_reboot);
      if ($debug)                                                     { print ":: reboot process - boot time:                $boot_time\n";           }

   $reboot_file         = $SSM_LOGS . "reboot.time";
      if ($debug)                                                     { print ":: reboot process - reboot file:              $reboot_file\n";         }
   
   $success             = check_reboot_file($reboot_file, $boot_time);
      if ($debug)                                                     { print ":: reboot process - check reboot file status: $success\n";             }
   
   $boot_time_from_file = read_reboot_file($reboot_file);
      if ($debug)                                                     { print ":: reboot process - boot time from file:      $boot_time_from_file\n"; }

   $boot_time_diff      = $boot_time - $boot_time_from_file;
      if ($debug)                                                     { print ":: reboot process - boot time difference:     $boot_time_diff\n"; }

  ($rebooted,
   $update_file)        = check_for_reboot($boot_time_diff, $uptime_reboot);
      if ($debug)                                                     { print ":: reboot process - rebooted:                 $rebooted\n";
                                                                        print ":: reboot process - update reboot file:       $update_file\n";}

  if ($rebooted) {
    $success            = reboot_alert($uptime_reboot);
      if ($debug)                                                     { print "Status of reboot_alert: $success\n"; }
   }
    
   if ($update_file) {
    $update             = 1;
    $success            = check_reboot_file($reboot_file, $boot_time, $update);
      if ($debug)                                                     { print "Status of check_reboot_file: $success\n"; }
   }
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_boot_time()
#  This function will return the boot time in epoch
# -------------------------------------------------------------------
sub get_boot_time {
   my $boot_time = "";
   
   if ("$platform" eq "MSWin32") {
   
      $boot_time = get_boot_time_windows();
      
   } else {
   
      $boot_time = get_boot_time_unix($test_scenario);
   
   }
   
   return $boot_time;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_boot_time_unix($uptime_epoch)
#  this function will use the `who -b` command to determine the boot
#  time.
#  The $uptime is used to compare against if a system has been up for
#  more than a year.
# -------------------------------------------------------------------
sub get_boot_time_unix {
   my $uptime    =  $_[0];
   my $EPOCH_DAY =  86400;            # number of seconds in a day
   my $EPOCH_MON =  $EPOCH_DAY * 28;  # number of seconds in a month: 28 days being the least number of days in a month
   my $EPOCH_YR  =  $EPOCH_DAY * 365; # number of seconds in a standard year
   my $var       =  `who -b`;
   my $find_str  =  "system boot";
   my $loc       =  index($var, $find_str);
   my $tm        =  localtime;
   my $sec       =  00; # place holder for seconds

   # array of numeric month values
   my %mons      =
          (Jan => 1,
           Feb => 2,
           Mar => 3,
           Apr => 4,
           May => 5,
           Jun => 6,
           Jul => 7,
           Aug => 8,
           Sep => 9,
           Oct => 10,
           Nov => 11,
           Dec => 12);

   
   if ($loc lt 0) { die "Problem with who -b command: $var\n"; }
   if ($debug) { print "output of raw who -b: $var\n"; }

   $loc          = $loc + 11;  # add 11 characters to the location.
   
   $var          = substr($var, $loc);  #take everything from $loc to the end of the string
   
   $var          = trim($var);  #trim the spaces from the beginning and end

   $var          =~ s/\s\s/ /;  # make any double spaces into single
   
   if ($debug) { print "output of processed who -b: $var\n"; }

   ($mon, $day, $hour, $min) = split/\s|\:/,$var;  # split the value into fields
   
   # reminder: months are zero based
   ($current_mon, $current_year)  = ($tm->mon, ($tm->year+1900));
   
   if ($debug) { print "String months: $mon\n"; }
   
   $mon = $mons{$mon};  # conver to the numeric month
   $mon = $mon - 1;     # make the months zero based
   
   if ($debug) {
      print "Boot month:   $mon (zero based) \n";
      print "Boot day:     $day           \n";
      print "Boot hour:    $hour          \n";
      print "Boot min:     $min           \n";
      print "Current year: $current_year  \n";
      print "Current mon:  $current_mon   \n";
   }
   
   $year = $current_year; # the default year.  It gets manipulated below
   
   $month_diff = ($current_mon - $mon);
   
   if ($debug) { print "difference in months: $month_diff\n"; }
   
   # if the difference in months is less than 0 then the boot time versus
   #  the current time has spanned a year-end.
   if ($month_diff lt 0) {
      if ($debug) { print "looks like the reboot happened last year\n"; }
      $year        = $year - 1;
      $month       = $month_diff + 12;
   }
   
   # if the difference in months is 0 then either the system was rebooted within this month
   #  or it has been up for more than a year.
   if ($month_diff eq 0) {

      $years_up = int($uptime / $EPOCH_YR);
      $year     = $year - $years_up;
      
      if ($debug) {
         print "It looks like either the same month reboot or a year or more has passed\n";
         print "years up: $years_up\n";
         print "year:     $year\n";
      }
      
   }
   
   $boot_time = timelocal($sec, $min, $hour, $day, $month, $year);
   
   if ($debug) {
      print "boot time in epoch: $boot_time\n";
      print "boot time second:   $sec\n";
      print "boot time min:      $min\n";
      print "boot time hour:     $hour\n";
      print "boot time day:      $day\n";
      print "boot time month:    $month\n";
      print "boot time year:     $year\n";
   }
   
   return $boot_time;
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_boot_time_windows()
#  this function will call the get_uptime_windows("boot_time") command
#
#  This isn't entirely necessary; however, consistentcy is key.
# -------------------------------------------------------------------
sub get_boot_time_windows {

      my $boot_time = uptime_windows("boot_time");
      
      return $boot_time;
}

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: check_reboot_file($file, $epoch_time, $update)
#  this will create and/or update the reboot file
#  with the $epoch_time value
#  the $update value should be 1: update file
# -------------------------------------------------------------------
sub check_reboot_file {
   my $file       = $_[0];
   my $epoch_time = $_[1];
   my $update     = $_[2];
   
   if ($update eq "") { $update = 0; }

   if ((not (-e $file)) or $update) {
      open (REBOOT_FILE, ">$file") || die "open: $!\n";
      print REBOOT_FILE  "$epoch_time\n";
      close REBOOT_FILE;
      if ($debug) {
         print "file       = $file\n";
         print "epoch_time = $epoch_time\n";
         print "update     = $update\n";
      }
      
   }

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: read_reboot_file($file)
#  This will read the contents of $file and return the first line
#  which should always be the epoch value of the boot time.
# -------------------------------------------------------------------
sub read_reboot_file {
   my $file   = $_[0];
   my $retavl = "";
   
   if (not (-e $file)) {
      die "Error: unable to find $file\n";
   } else {
      open (REBOOT_FILE, "$file") || die "open: $!\n";
      
      if ($debug) {
         print "reboot file: $file\n";
         print "-- read contents of reboot file --\n";
      }
      
      while (<REBOOT_FILE>) {
         chomp;
         @reboot_file_contents = $_;
         if ($debug) {
            print "reboot file contents: $_\n";
         }
      }

      $retval = $reboot_file_contents[0];
      if ($debug) { print "Reboot file retval:  $retval\n"; }

   }   

   return $retval;
      
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: check_for_reboot($boot_time_diff, $boot_time, $uptime)
#  this will check to see if a system has been rebooted by analyzing
#   $boot_time_diff.
#  It will also check to make sure $boot_time_diff isn't greater than an hour
#   in case the server has been up for awhile AND
#   it will make sure there is sufficient time for the vpo agent to be up
#   and running properly.

#  This function returns two values of either true or false:
#   - $reboot_alert - send reboot alert
#   - $update_file  - update reboot.time file
#
# -------------------------------------------------------------------
sub check_for_reboot {
   my $boot_time_diff      = $_[0];
   my $uptime_epoch        = $_[1];
   my $TRUE                = 1;
   my $FALSE               = 0;
   my $reboot_alert        = $FALSE;
   my $file_update         = $FALSE;
   my $EPOCH_DAY           = 86400;
   my $HIGH_THRESHOLD      = 3600;         # if it thinks the system has been up for more than an hour then there is a problem.
   my $LOW_THRESHOLD       = 200;          # number of seconds to wait before sending a reboot message.
                                           #  this will prevent the reboot process from trying to alert when
                                           #  the vpo agent is not available.
   
   $boot_time_diff = trim($boot_time_diff);
   
   if ($debug) {
      print "The passed boot time diff: $boot_time_diff\n";
      print "The passed uptime epoch:   $uptime_epoch\n";
      }
   
    ##
    ## If the reboot time difference is greater than zero:
    ##  check to see that the time difference isn't so great as to be a false message
    ##  and check to see sufficient time has passed for the vpo agent to be up and running
    ##  properly.
    ##
    if ($boot_time_diff gt 0) {
    
      if      ($uptime_epoch >= $HIGH_THRESHOLD) {

          if ($debug)                                                 { print "The program thinks the system has rebooted; however, uptime is reported as $uptime_epoch\n"; }
          
          # This is returning true because the reboot.time file should be updated.  The reboot_alert
          #  function will catch the false alarm.
          $reboot_alert = $FALSE;
          $file_update  = $TRUE;
          return $reboot_alert, $file_update;

      } elsif ($uptime_epoch <= $LOW_THRESHOLD)  {

          if ($debug)                                                 { print "The program thinks the system has rebooted; however, it will wait one more cycle to send the alert.\n"; }
          
          # Because there is a chance the various vpo processes might be still starting up,
          #  delay the alert for one pass.
          $reboot_alert = $FALSE;
          $file_update  = $FALSE;
          return $reboot_alert, $file_update;

      } else {
        
          $reboot_alert = $TRUE;
          $file_update  = $TRUE;
          return $reboot_alert, $file_update;
         
      }
      
    } else {
    
      $reboot_alert = $FALSE;
      $file_update  = $FALSE;
      return $reboot_alert, $file_update;
      
    }
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: reboot_alert(epoch)
#  this will send an opcmsg if a reboot has happened
# -------------------------------------------------------------------
sub reboot_alert {
  my $epoch          = $_[0];               # the number of seconds the system has been on-line
  my $reboot_minutes = int($epoch / 60);    # the calculated number of minutes the system has been on-line
  my @status         = "";                  # a placeholder for status
  my $opcmsg         = $OpC_BIN . "opcmsg"; # which opcmsg to use
  my $HIGH_THRESHOLD = 60;                  # don't send a message if the system has been up for more than an hour.

  if ($reboot_minutes gt $HIGH_THRESHOLD) {
    
    if ($debug) { print " It appears the system has been up for $reboot_minutes. Because it has been up for greater than $HIGH_THRESHOLD no alert will be sent.\n"; }
    
  } else {
    
    if ($debug) {
      print "Machine has rebooted $reboot_minutes minutes ago.\n";
      print "Sending alert!\n";
      print "Alert contents: $opcmsg o=$HOSTNAME msg_grp=nodestatus msg_text=\"$HOSTNAME has been rebooted $reboot_minutes minutes ago\" sev=major";
    }
                
    @status = `$opcmsg a=REBOOT o=$HOSTNAME msg_grp=nodestatus msg_text="$HOSTNAME has been rebooted $reboot_minutes minutes ago" sev=major`;
   
    if ($debug) {
      foreach $line (@status) {
        print "opcmsg status: $line\n";
      }
    }
  } 
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_ssm_vars()
#  this function is called to setup all standard variables.
# -------------------------------------------------------------------

$vposend = $SSM_BIN . "vposend";

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
# Start Programming Notes
# ===================================================================
#
# -- 2004 Sep 12-13
# I tried to use who -b for the UNIX uptime, but realised that I didn't know what would happen
# when the year changed.  The output of who -b is not clear on year notation.  It might be that
# I can date warp a system and see what it looks like then, but I want to be sure.
#
# The UNIX uptime output is very painful!  It changes with the situation.
# So, if it just happens to be exactly 1 hour after the boot, you get 1 hr(s) for the output.
#
# -- 2004 Sep 14
#  I've made a decision to use who -b for reboot processing.  I date warped vpo-dev ahead a year
#  and the format of the who -b output didn't change.  I'll have to do calcs if the current month
#  is earlier than the boot month, but that shouldn't be too difficult.
#
#  I think this is a more reliable way to determine reboots and will get the message out faster
#  and with a greater level of authenticity.
#
# ===================================================================
# End Programming Notes
# ===================================================================

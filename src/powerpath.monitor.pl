#!/usr/local/bin/perl
###################################################################
#
#             File: powerpath.monitor.pl
#         Revision: 2.50
#
#           Author: Bill Dooley
#
#    Original Date: 10/04
#
#      Description: This program will check the results of the 
#                   powermt command.
#                   
#           Usage:  powerpath.monitor (use $SSM_ETC/powerpath.dat*)
#
# Revision History:
#
#  Date     Initials  Description of Change
#
#  ??/??      wpd     <Initial Version>
#
#  11-2004   nichj    minor structure updates, changed text of powermgt_fail message,
#                     added chk_running logic for return code.
#                     added test option (but no logic to run test, yet).
#
#  2005-04-06 nichj   2.50: Increased the version to match other ssm programs
#                           added status reporting and check for already running.
#                           restructured to use latest code template
#
#####################################################################

$version             = "$0 version 2.50\n";
$program_description = "power path monitor";

use Getopt::Long;
use File::Basename;

GetOptions( "v", "version",
            "h", "help",
            "d", "debug", "debugextensive",
            "test:n" => \$test
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

$DEBUG_EXTENSIVE_ON  = "$SSM_CONF" . "powerpath.monitor.debugextensive";    # if this file is there then debug extensive is on
$DEBUG_ON            = "$SSM_CONF" . "powerpath.monitor.debug";             # if this file is there then debug is on

check_debug_settings($DEBUG_ON, $DEBUG_EXTENSIVE_ON);

# ===================================================================
# Begining of Main
# ===================================================================
if ($debug)                                                          { print "=== debug output ===\n\n"; }

$status_file        = "$SSM_LOGS" . "powerpath.monitor.status";
status_report("$program_description", "$status_file", "start");

my $TRUE            = 1;
my $FALSE           = 0;
my $adapter_found   = $FALSE;
my $adapter_problem = $FALSE;

$vposend            = $SSM_BIN . "vposend";
$file               = "powermt";
$timefile           = "powermt.times";
#
# Set up local variables
#

$now                                                    = time;
($sec,$min,$hour,$day,$month,$year,$wkday,$julian,$dls) = localtime($now);

if ($debug)                                                          { print "Now = $now\n"; }

if ( "$platform" eq "MSWin32" ) {
   $disp_date = `date/t`;
   chomp($disp_date);
   $disp_time = `time/t`;
   chomp($disp_time);
   $chk_date  = $disp_date;
} else {
   $disp_date = `date`;
   chomp($disp_date);
   $disp_time = "";
   $chk_date  = `date +%Y%m%d`;
   chomp($chk_date);
}

#
# Check to see if another instance of the monitor is running
#

$running_status = chk_running("powerpath.monitor");

@powerpath_display = powerpath_program_output();

if ( $powerpath_display eq "" ) { 
   
  print "\nNo powermt program was found.\n";
  
  $adapter_found = $FALSE;
  
} else {
  
  print "\n powermt program found.\n";
  
  $adapter_found = $TRUE;
  
}


## commenting these next lines as the chk_running function will handle the exit.
##
#if ($running_status eq 1) {
#  print "\nError: power path monitor already running.  Exiting.\n";
#  exit 1;
#}

if ($adapter_found eq $TRUE) {
  
  if ($debug)                                                        { print " Power path output found on this system\n"; }
  #
  # Set up configuration file options
  #
  
  %opts = (
     "I" => { cl => "-I", lf => "issue="           },
     "a" => { cl => "-a", lf => "app=",            },
     "H" => { cl => "-H", lf => "start="           },
     "J" => { cl => "-J", lf => "stop="            },
     "W" => { cl => "-W", lf => "dayofweek="       },
     "Z" => { cl => "-Z", lf => "description="     },
     "A" => { cl => "-A", lf => "action=",         },
     "s" => { cl => "-s", lf => "sev=",            },
     "z" => { cl => "-z", lf => "severity=",       },
     "M" => { cl => "-M", lf => "message_age=",    },
     "E" => { cl => "-E", lf => "error_times="     },
     "S" => { cl => "-S", lf => "service=",        },
     "O" => { cl => "-O", lf => "source_host="     },
  );
  
  ###
  ### Get the list of configuration files.
  ###
  @conf_files   =  get_config_files("powerpath");
  
  $config_found =+ @conf_files;
  
  ## if configuration files are found then process.
  ##
  if ( $config_found > 0 ) { 
  
    $disk_info    = $SSM_LOGS . "disk.info";
    
    open (diskinfo, "$disk_info");
    @diskinfo     = <diskinfo>;
    close (diskinfo);
    
    #
    # Get the statistics
    #
    
    $adapter_found = 0;
    $linechk       = 0;
    
    foreach $powerpath_rec (@powerpath_display) {
      
       chomp($powerpath);
    
       #
       # Check for blank line
       #
       $powerpath_rec =~ s/^\s+//;
       $blank         =  (substr($powerpath_rec, 0, 1));
       if ("$blank" eq "") {next;};
    
       $CHK = substr($powerpath_rec,1,1);
       if ("$CHK" eq "=") {
          $linechk ++;
          next;
       }
       if ($linechk > 1) { 
          $adapter_found ++;
          push(@adapter, $powerpath_rec);
       }
    }
    
    if ($debug)                                                        { print "Found $adapter_found adapters in \n@powerpath_display\n\nThey are \n@adapter\n\n";}
    
    @optimal       =  grep(/optimal/,@adapter);
    $optimal_found =+ @optimal;
    
    if ($debug)                                                        { print "Found $optimal_found records\n";}
    
    if ($optimal_found == 2) {
      print "\nEverything is ok.\n\n";
      if ( -e "$SSM_HOLD$file" ) {
         unlink "$SSM_HOLD$file";
      }
  
      $adapter_problem  = $FALSE;
       
    } else {
      
       $running_err     = "N";
       $adapter_problem = $TRUE;
       
       if      ($adapter_found == 1) {
        
          $errmsg      = "It appears that the san interface is not redundant on $HOSTNAME. Power path is showing only one san interface present.";
          $running_err = "r";
          
       } elsif ($adapter_found <  1) {
        
          $errmsg      = "It appears the san interface is not working on $HOSTNAME. Power path is showing no san interfaces present.";
          $running_err = "r";
          
       } elsif ($adapter_found != $optimal_found) {
        
          $errmsg      = "Power path is reporting a degraded san interface on $HOSTNAME.";
          $running_err = "d";
          
       } else {
        
          $errmsg      = "There were problems running the power path management program on $HOSTNAME";
          $running_err = "f";
          
       }  
    }
    
    if ($debug) {print "\n$errmsg\n\n";}

  } else {

    print "No configuration files found.\n";

  }
  
}

###
### If there is a problem discovered in the output of the program
###
if ($adapter_problem eq $TRUE) {
  #
  # Process the Error
  #
  
  foreach $config_file (@conf_files) {
    
     chomp($config_file);
  
     if ($debug) { print "\n\nv*v*v START $config_file v*v*v\n"; }
  
     open (powerpathinfo, "$config_file");
     @powerpathinfo = <powerpathinfo>;
     close(powerpathinfo);
     
     foreach $line (@powerpathinfo) {
        chomp($line);
        if ($debug) {print "Processing LINE - $line\n";}
  
        #
        # Check for blank line
        #
        $line  =~ s/^\s+//;
        $blank =  (substr($line, 0, 1));
        
        if ("$blank" eq "") {next;};
  
        # 
        # Skip the line if it is a comment
        #
        $comment = (substr($line, 0, 1));
        if ("$comment" eq "#" ) { next; }
        if ("$comment" eq "\n") { next; }
  
        @fargs           =  $line;
        
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
        $Error_Times = $DESC = $issue = $appl = $age = $action = $severity = $ITO_AGE = $Service = $start = $stop = $dayofweek = $source_host = "";
        
        foreach $a (@PARMS) { 
           #
           # Strip leading AND trailing spaces per field ...arrrg
           #
           $a =~ s/^\s*(.*?)\s*$/$1/; 
           
           if ( $arg_cnt == 1 ) {
              #
              # Set the variables used for processing
              # 
              if ($debug) { print "Processing arg $vposend_arg value = $a\n"; }
              
              if ( "$vposend_arg" eq "-I" ) { $issue       = "$a";               }
              if ( "$vposend_arg" eq "-a" ) { $appl        = lc($a);             }
              if ( "$vposend_arg" eq "-H" ) { $start       = "$a";               }
              if ( "$vposend_arg" eq "-J" ) { $stop        = "$a";               }
              if ( "$vposend_arg" eq "-W" ) { $dayofweek   = lc($a);             }
              if ( "$vposend_arg" eq "-Z" ) { $DESC        = "$a";               }
              if ( "$vposend_arg" eq "-A" ) { $action      = "action=" . lc($a); }
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
        }
  
        chomp ($source_host);
        $source_host = trim($source_host);
  
        # Source Host Check - if source_host_check returns 1 the source_host option matches
        if (source_host_check($source_host)) {
           if ($debug_extensive)                                     { print " match on source host: $source_host\n"; }
        } else {
           if ($debug_extensive)                                     { print " no match on source host: $source_host\n"; }
           next;
        }
  
        chomp($severity);
        if ( "$severity"     eq "" ) {
           $severity    = "critical";
        }
  
        if (     "$severity" ne "critical" 
              && "$severity" ne "major" 
              && "$severity" ne "minor" 
              && "$severity" ne "warning"
              && "$severity" ne "normal" ) {
          
           $severity    = "major";
           
        }
  
        if ("$start"         eq "") {
           $start       = "00";
        }
  
        if ("$stop"          eq "") {
           $stop        = "24";
        }
  
        if ("$dayofweek"     eq "" ||
            "$dayofweek"     eq "all") {
           $dayofweek   = "sun mon tue wed thu fri sat";
        }
  
        if ($debug)                                                  { print "Start = $start  Stop = $stop\n"; }
  
        chomp($ITO_AGE);
        if ( "$ITO_AGE"      eq "" ) {
           $ITO_AGE     = 60;
        }
  
        chomp($Error_Times);
        if ( "$Error_Times"  eq "" ) {
           $Error_Times = "0";
        }
  
        chomp($Service);
        if ( "$Service"      eq "" ) {
           $Service     = "os";
        }
  
        if ($debug)                                                  { print "Checking $running_err - $line\n"; }
  
        if      ("$issue"    eq "optimal") {
           if ("$running_err" eq "d") {
              if ($debug)                                            { print "Processing $errmsg\n";}
              &process_error;
           } else {
              next;
           }
        } elsif ("$issue"    eq "redundacy") {
           if ("$running_err" eq "r") {
              if ($debug)                                            { print "Processing $errmsg\n";}
              &process_error;
           } else {
              next;
           }
        } elsif ("$issue"    eq "powermt_fail") {
           if ("$running_err" eq "f") {
              if ($debug)                                            { print "Processing $errmsg\n";}
              &process_error;
           } else {
              next;
           }
        }
  
        if ($debug)                                                  { print "\n\n^*^*^  END  $config_file ^*^*^\n"; }
     }
  
  }

}

status_report("$program_description", "$status_file", "end_pass");
   
print "\n$program_description completed successfully\n";
exit 0;

# ===================================================================
# End Main
# ===================================================================

# ===================================================================
# Start Functions
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
Run powerpower.monitor to see if there are problems with the SAN interface.

Notes:
- This program will exit when the power path management program (powermgt)
  doesn't exist.  The program will check in the standard UNIX location on UNIX hosts.
  It will check all local Windows drives in the program files directory.

- Check out the powerpath.dat.template file for the alert configuration options.

Runtime options include:
-h(elp)         - display this screen.
-d(ebug)        - run in debug mode.
-debugextensive - run in extensive debug mode.
-v(ersion)      - display the version of the program.
\n
";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: powerpath_program_output()
# This function looks for the powerpath program and:
#  - if found, returns the output in an array
#  - if not found, returns ""
# -------------------------------------------------------------------
sub powerpath_program_output {
  my $retval  = "";
  my $display = "";
  
  my $powerpath_pgm = "/etc/powermt";
  my $power_found   = N;
  
  #
  # Find the PowerPath Program (powermt)
  #
  if ( "$platform" eq "MSWin32" ) {
    
     foreach $drive_rec (@diskinfo) {
      
        ($drive, $dummy, $dummy1) = split(/ /,$drive_rec);

        $chk_program = $drive . "/Program Files/EMC/PowerPath/powermt.exe";
        
        if ($debug)                                                  { print "Checking for $chk_program\n"; }
        
        if (-e "$chk_program") {
           
           $power_found   = "Y";
           @display       = `"$chk_program" display`;
           if ($debug)                                               { print "\nFound $chk_program \n";}
           if ($debug)                                               { print "\nOUTPUT\n\n@display \n";}
           last;
        }
        
     }
     
  } else {
    
     if ($debug)                                                     { print "\nFinding $powerpath_pgm \n";}
     
     if (-e "$powerpath_pgm") {
        if ($debug)                                                  { print "\nFound $powerpath_pgm \n";}
        @display     = `$powerpath_pgm display`;
        if ($debug)                                                  { print "\nOUTPUT\n\n@powerpath_display \n";}
        $power_found = "Y";
     }
     
  }
  
  return @display;

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
# End Functions
# ===================================================================

# ===================================================================
# Start Subroutines
# ===================================================================

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
sub process_error {

   if ($debug_extensive)                                                  { print "subroutine process_error *** start *** v\n"; }
   print "In error routine for $errmsg\n";

   #
   # Check if within start and stop monitor times
   #
   # If stop time is < than start time then add 24 hours to stop
   # time and to the hour to handle next day processing.
   #
   if ($stop < $start) {
		 
      $stop = $stop + 24;
      if ($hour < $start) { $hour = $hour + 24; }
      
   }

   #
   # Check the day of week
   #

   ($sec,$min,$hour,$day,$month,$year,$wkday,$julian,$dls) = localtime($now);

   if ( $wkday      == 0 ) {
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

   $dayofweek =~ s/,/ /g;
   $dayofweek =  lc($dayofweek);

   @dayofweek = "";
   push(@dayofweek, "$dayofweek");

   $dw_found = grep(/$wkday/, @dayofweek);

   if ($debug_extensive) { print "Checking for $wkday in @dayofweek start=$start stop=$stop hour=$hour\n"; }

   if (($hour >= $start) && ($hour < $stop) && ($dw_found > 0)) {

      &check_times;
      &chk_error;
      
   } else {
      
      $errmsg      = "No check.  Out of time range.  Hour = $hour $start-$stop on days $dayofweek for server $HOSTNAME";
      print "$errmsg\n";
      next;
      
   }

   if ($debug_extensive) { print "subroutine chk_file ***  end  *** ^\n"; }

}
# end of process_error subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
sub check_times {

   if ($debug_extensive) { print "subroutine chk_times *** start *** v\n"; }

   #
   # This subroutine will check how many times the error has been reported today
   #

   #
   # Add a date record for this error
   #
   if ($debug_extensive) { print "Check 3 check_times for $timefile\n"; }

   system "echo $chk_date >> \"$timefile\"";
   open  (time_file, "$timefile");
   @time_file = <time_file>;
   close (time_file);

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

   close (new_file);
   open  (new_file, "$newfile");
   @new_file = <new_file>;
   close (new_file);

   #
   # Count the number of times error occurred today
   #

   $no_errors  = 0;
   $no_errors += @new_file;
   
   if ( $no_errors > $Error_Times && $Error_Times > 0 ) {
      #
      # Put Number of times error to ITO
      #
      $cmd         =~ s/"//g;
      $MATCH_KEY   =  $appl . ":" . $ito_obj . ":times:" . $severity;
      $errmsg_text =  "powerpath errors have occurred $no_errors times for $errmsg_text";

      $message = "Message from powerpath monitoring via $config_file $disp_date $disp_time vposend_options: app=$appl sev=$severity message=$errmsg_text $cmd";

      process_vposend($message);
      
   }

   #
   # Reset the count hold file
   #
   unlink "$timefile";

   if ( "$platform" eq "MSWin32" ) {
      `move "$newfile" "$timefile"`;
   } else {
      `mv "$newfile" "$timefile"`;
   }

   if ($debug_extensive)                                             { print "subroutine chk_times ***  end  *** ^\n"; }

}
# End of check_times
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
sub chk_error {
   #
   # Check if error should be reported to VPO
   #

   if ($debug_extensive) { print "subroutine chk_error *** start *** v\n"; }

   $chk_file =  $SSM_HOLD . $file;
   $timefile =  $SSM_HOLD . $timefile;
   
   if ($debug_extensive) {
                                                                       print " chk_file: $chk_file\n";
                                                                       print " timefile: $timefile\n";
                                                                       print "\n\n";
   }

   if ($debug_extensive) { print "Processing error for $errmsg_text\n"; }

   #
   # Get the previous error level
   #

   if (-e "$SSM_HOLD$file") {
      #
      # Stat the ITO Error Age file
      #
      $mtime = (stat ("$SSM_HOLD$file"))[9];

      #
      # Check how old the file is in minutes
      #
      $diff         = $now - $mtime;
      $ageInMinutes = int($diff / 60);

      #
      if ($debug_extensive)                                          { print " mtime: $mtime\n\n"; }
      if ($debug_extensive)                                          { print " Checking AGE of $SSM_HOLD$file ageInMinutes $ageInMinutes ITO_AGE $ITO_AGE\n"; }

      if ( $ageInMinutes > $ITO_AGE ) {
        
         if ($debug_extensive) { print "$errmsg_text\n"; }
         $action  =~ s/"//g;
         $SUP_KEY =  $appl . ":" . $fname . ":" . $severity;
            
         $message = "Message from powerpath monitoring via $config_file $disp_date $disp_time vposend_options: app=$appl sev=$severity message=$errmsg $action";

         process_vposend($message);            
            
         `echo $severity >> \"$SSM_HOLD$file\"`;
           
      } else {
        
         print "Problem was already reported $ageInMinutes minutes ago\n\n";
         
      }

   } else {
         
      $action  =~ s/"//g;
      $SUP_KEY = $appl . ":" . $fname . ":" . $severity;
      #if ($action ne "") { $action = "action=$action"; }
         
      $message = "Message from powerpath monitoring via $config_file $disp_date $disp_time vposend_options: app=$appl sev=$severity message=$errmsg $action";
         
      process_vposend($message);
         
      `echo $severity> \"$SSM_HOLD$file\"`;
         
   }


   if ($debug_extensive)                                             { print "subroutine chk_error ***  end  *** ^\n"; }

}
# end of chk_error subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ===================================================================
# Developer's Comments
# ===================================================================
#

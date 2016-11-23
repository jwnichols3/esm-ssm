#!/usr/local/bin/perl
###################################################################
#
#             File: fileage.pl
#         Revision: 2.50
#
#           Author: Bill Dooley
#
#    Original Date: 12/01
#
#      Description: This program will check the age of a file and 
#                   report errors base on $age that is passed to 
#                   this program.
#                   
#           Usage:  fileage (use $SSM_ETC/fileage.dat*)
#                           (must run in $SSM_BIN)
#
# Revision History:
#
#  Date     Initials  Description of Change
#
#  12/01      wpd     <Initial Version>
#  08/02      wpd     Changed the configuration files to be 
#                     SSM like arguments.  Use vposend instead
#                     of opcmsg.
#
#  Jun 2004   jwn     changed PWC to SSM
#                     added debug options
#
#  Jun 2004   wpd     Added @ multifile processing option
#
#  Aug 2004   jwn     2.11: made all $DESC uppercase. The mixed case was
#                      causing issue on Windows Advaned Servers.
#
#  Aug 2004 wpd/jwn   2.20: Added the ability to check a Windows share
#
#  Aug 2004   jwn     2.21: removed error reporting on absence of file (Windows)
#                           enhanced logging slightly
#
#  Sep 2004   wpd     2.30: Add ability to check for new source_host
#                           variable.
#            nichj          Added -d / -debug cli option
#                           changed onhostname to source_host
#                           functionalized the source_host processing
#                           added inclusion of ssm_common.pm
#                           added -h / -help usage option
#                           changed to getopt::long
#                           changed from using ssm.log to vposend
#
#  Mar 2005  nichj    2.31: converted to latest standard header
#
#  2005-03-30 nichj   2.50: Added status reporting options
#                           Converted to get_config_files function
#
#
#####################################################################

$version             = "$0 version 2.50\n";
$program_description = "fileage monitor";                            

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;
use File::Basename;

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

$DEBUG_EXTENSIVE_ON  = "$SSM_CONF" . "fileage.debugextensive";    # if this file is there then debug extensive is on
$DEBUG_ON            = "$SSM_CONF" . "fileage.debug";             # if this file is there then debug is on

check_debug_settings($DEBUG_ON, $DEBUG_EXTENSIVE_ON);

# ===================================================================
# Begining of Main
# ===================================================================

if ($debug) { print "=== debug output ===\n\n"; }

$status_file = "$SSM_LOGS" . "fileage.status";
status_report("$program_description", "$status_file", "start");

$vposend = $SSM_BIN . "vposend";

#
# Set up local variables
#

$now                                                    = time;
($sec,$min,$hour,$day,$month,$year,$wkday,$julian,$dls) = localtime($now);

if ($debug) { print "Now = $now\n"; }

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

$running_status = chk_running("fileage");

$fileage        = "$SSM_ETC" . "fileage.dat";
$init_file      = $SSM_BIN   . "fileage.dat";

if ( -e "$init_file" ) {
  
   print "Installing $fileage\n";
   `$CP $init_file $SSM_ETC`;
   
}

%opts = (
   "D" => { cl => "-D", lf => "dir="             },
   "F" => { cl => "-F", lf => "file="            },
   "a" => { cl => "-a", lf => "app=",            },
   "T" => { cl => "-T", lf => "age_threshold=",  },
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

#
# Get the files in $SSM_ETC/ssm_pointers
#

if ( -e "$SSM_ETC/ssm_pointers" ) {
   print "Processing pointers\n";
   
   open (ssm_pointers, "$SSM_ETC/ssm_pointers");
   @pointers         = <ssm_pointers>;
   @fileage_pointers = grep(/fileage/, @pointers);
   close(ssm_pointers);
   
   foreach $pointer (@fileage_pointers) {
      chomp($pointer);
      push (@appl_files, "$pointer\n");
   }
}

#
# Get the fileage.dat* files to process
#

$get_files  = $fileage . "\*";
@conf_files = `$LL $get_files`;
chomp(@conf_files);

foreach $conf_file (@conf_files) {
   if ( "$platform" eq "MSWin32" ) {
      $config_file = $SSM_ETC . $conf_file;
   } else {
      $config_file = $conf_file;
   }
   push (@appl_files, "$config_file\n");
}

#
# Get files from the .ssm directories for a mountpoint
#
@appl_files = get_config_files("fileage");

##
## Replacing the following commented code with above function.
##  nichj 2005-03-30
##
#$MountInfo   = $SSM_LOGS . "mount.info";
#open (mountpoint, "$MountInfo");
#@mountpoints = <mountpoint>;
#close(mountpoint);
#
#foreach $mount (@mountpoints) {
#   chomp($mount);
#   if ( "$platform" eq "MSWin32" ) {
#		 
#      $app_config_file  = $mount . "\\ssm\\fileage.dat.*";
#      @app_files        = `$LL $app_config_file`;
#      chomp(@app_files);
#      $app_files_found += @app_files;
#      
#      if ($debug) { print "Checking for .ssm using $LL $app_config_file\n"; }
#      
#      if ( $app_files_found > 0 ) {
#         foreach $app_file (@app_files) {
#            push (@appl_files, "$mount\\ssm\\$app_file\n");
#         }
#      }
#      
#   } else {
#      
#      $app_config_file  = $mount . "/.ssm/fileage.dat.*";
#      @app_files        = `$LL $app_config_file 2>/dev/null`;
#      chomp(@app_files);
#      $app_files_found += @app_files;
#      
#      if ($debug) { print "Checking for .ssm in $mount\n"; }
#      
#      if ( $app_files_found > 0 ) {
#         foreach $app_file (@app_files) {
#            push (@appl_files, "$app_file\n");
#         }
#      }
#   }
#}
###

foreach $config_file (@appl_files) {

   chomp($config_file);
   if ($debug) { print "\n\nv*v*v START $config_file v*v*v\n"; }
   print "\nProcessing files in $config_file \n";

   open (fileageinfo, "$config_file");
   @fileageinfo = <fileageinfo>;
   close(fileageinfo);
   
   foreach $line (@fileageinfo) {
      chomp($line);

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
      if ("$comment" eq "#" ) {next;}
      if ("$comment" eq "\n") {next;}

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
      $Error_Times = $DESC = $dir = $file = $appl = $age = $action = $severity = $ITO_AGE = $Service = $start = $stop = $dayofweek = $source_host = "";
      
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
            
            if ( "$vposend_arg" eq "-D" ) { $dir         = "$a";               }
            if ( "$vposend_arg" eq "-F" ) { $file        = "$a";               }
            if ( "$vposend_arg" eq "-a" ) { $appl        = lc($a);             }
            if ( "$vposend_arg" eq "-T" ) { $age         = $a;                 }
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
         if ($debug_extensive) { print " match on source host: $source_host\n"; }
      } else {
         if ($debug_extensive) { print " no match on source host: $source_host\n"; }
         next;
      }

      chomp($dir);
      if ( "$platform" eq "MSWin32" ) {
         $share_name = "$dir";

         $dir = $dir . "\\";

         $share_chk = substr($share_name,0,2);

         if ( "$share_chk" eq "\\\\" ) {
            print "Using mount_share with share name: $share_name\n";
            
            $status = mount_share($share_name);
            
            if ($debug_extensive) { print "  mount_share status: $status\n"; }
            
         }

      } else {
         $dir = $dir . "/";
      }

      chomp($severity);
      if ( "$severity" eq "" ) {
         $severity    = "critical";
      }

      if (     "$severity" ne "critical" 
            && "$severity" ne "major" 
            && "$severity" ne "minor" 
            && "$severity" ne "warning"
            && "$severity" ne "normal" ) {
         $severity    = "major";
      }

      if ("$start" eq "") {
         $start       = "00";
      }

      if ("$stop" eq "") {
         $stop        = "24";
      }

      if ("$dayofweek" eq "" || "$dayofweek" eq "all") {
         $dayofweek   = "sun mon tue wed thu fri sat";
      }

      if ($debug) { print "Start = $start  Stop = $stop\n"; }

      chomp($ITO_AGE);
      if ( "$ITO_AGE" eq "" ) {
         $ITO_AGE     = 60;
      }

      chomp($Error_Times);
      if ( "$Error_Times" eq "" ) {
         $Error_Times = "0";
      }

      chomp($Service);
      if ( "$Service" eq "" ) {
         $Service     = "os";
      }
   
      print "\n\n";
      $file_range_found =  0;
      @file_range       =  grep(/\@/,$file);
      $file_range_found =+ @file_range;
      
      if ( "$file" eq "\@" ) {
         
         print "Check if any file in the directory is < $age minutes old\n\n";
         $file    = "*";
         $any     = "Y";
         $found   = "N";
         
      } elsif ( "$file" eq "\*" ) {
         
         print "Checking all files in the directory if they are > $age minutes old\n\n";
         $any     = "M";
         
      } elsif ( $file_range_found > 0 ) {
         
         $file       =~ s/\@/\*/g;         
         $file_range = $file;
         print "Check if any file in the file range $file_range is < $age minutes old\n\n";
         $any        = "A";
         $found      = "N";
         
      } elsif ( $age < 0 ) {
         
         $age1    = $age * -1;
         print "Checking if the age of $file is < $age1 minutes old\n";
         $any     = "N";
         chomp($DESC);
         if ( "$DESC" eq "" ) {
            $DESC = "$file";
         }
         
      } else {
         
         print "Checking if the age of $file is > $age minutes old\n";
         $any     = "N";
         chomp($DESC);
         if ( "$DESC" eq "" ) {
            $DESC = "$file";
         }
         
      }
      
      chomp($file);
      
      if ( "$platform" eq "MSWin32" ) {
         
         @files = `$LL "$dir$file"`;
         if ( $? > 0 ) {
            # $errmsg_text = "$DESC is not found.  Check processing on server $HOSTNAME.";
            # if ($debug_extensive) { print "$errmsg_text\n\n"; }
            # $running_err = "Y";
            # &chk_error;
         }
         
      } else {
         
         if ($debug) { print "Processing $LL $dir$file\n"; }
         
         @files = `$LL $dir$file`;
         
      }   

      foreach $file (@files) {
         
         chomp($file);
         $file = basename($file);
         $file = $dir . $file;
         
         &chk_file;
         
      }
      
      if ( "$any" eq "Y" || "$any" eq "A" ) {
         
         $fname = $dir;
         
         if ( "$any" eq "A" ) {
            $fname = $file_range;
         }
         
         if ( "$DESC" eq "" ) {
            $DESC = $fname;
         }
         
         if ($debug_extensive) { 
            print "fname       = $fname $file_range\n";
            print "DESC        = $DESC\n";
            print "found       = $found\n";
            print "running_err = $running_err\n";
         }
         
         if ( "$found" ne "Y" ) {
            #
            # If older than $age minutes then report error. 
            #
            $errmsg_text = "All files in $DESC are too old.  Check processing on server $HOSTNAME.";
            if ( "$running_err" ne "O" ) {
               $running_err = "Y";
            }
            
         } else {
            
            $errmsg_text = "Found a file in $DESC less than $age minutes old on server $HOSTNAME.";
            $running_err = "N";
            print "$errmsg_text\n\n";
            
         }
         
         if ( "$running_err" ne "O" ) {
            &chk_error;
         }
         
      }
   }

   if ($debug) { print "\n\n^*^*^  END  $config_file ^*^*^\n"; }
   
}

status_report("$program_description", "$status_file", "end_pass");
   
print "\n$program_description completed successfully\n";
exit 0;

####################################
#  End of foreach files
####################################

# ===================================================================
# End of Main
# ===================================================================


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
# Function: chk_file()
#  
# -------------------------------------------------------------------
sub chk_file {

   if ($debug_extensive) { print "subroutine chk_file *** start *** v\n"; }

   if ($debug_extensive) { print "subroutine chk_file:  Checking $file\n"; }

   #
   # Check if within start and stop monitor times
   #
   # If stop time is < than start time then add 24 hours to stop
   # time and to the hour to handle next day processing.
   #
   if ($stop < $start) {
		 
      $stop = $stop + 24;
      if ($hour < $start) {
         $hour = $hour + 24;
      }
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

      $fname = $file;

      if ( "$any" eq "Y" ) {
         
         if ( "$DESC" eq "" ) {
            
            $DESC = $file;
            if ( "$any" eq "M" ) {
               $DESC = $DESC . "(" . $file . ")";
            }
            
         }
      }

      #
      # Stat the file
      #
      $mtime    = (stat ("$file"))[9];
      @fileinfo = stat("$file");
      
      if ($debug_extensive) { print "Fileinfo = @fileinfo\n"; }
   
      #
      # Check how old the file is
      #
      $diff         = $now - $mtime;
      $ageInMinutes = int($diff / 60);

      print "Age of file $file is $ageInMinutes vs $age - any = $any.\n";
      if ($debug_extensive) { print "now   = $now\n"; }
      if ($debug_extensive) { print "mtime = $mtime\n\n"; }

      #
      # if age threshold < 0 then check to see if a newer file exists
      # if age threshold > 0 then check to see if a older file exists
      #
      $age_err = "N";
   
      if ( $age > 0 ) {

         if ( $ageInMinutes > $age ) { 
            $age_err     = "Y";
            $errmsg_text = "$file is too old.  Check processing on server $HOSTNAME.";
         }

      } else {

         if ( $ageInMinutes < $age1 ) {
            $age_err     = "Y";
            $errmsg_text = "A newer version of $file has been created on server $HOSTNAME.";
            print "$errmsg_text\n";
         }

      }

      if ( "$age_err" eq "Y" ) {

         if ( "$any" ne "Y" && "$any" ne "A" ) {
            #
            # If older than $age minutes then report error. 
            #
            if ( $age > 0 ) {
               $errmsg_text = "$DESC is too old.  Check processing on server $HOSTNAME.";
            }

            if ($debug_extensive) { print "$errmsg_text\n\n"; }

            $running_err = "Y";

            &chk_error;
         }

      } else {
				
         if ( "$any" eq "Y" || "$any" eq "A" ) {
            
            $found = "Y";
            
         } else {
            
            $errmsg_text = "$file age is now ok on server $HOSTNAME.";
            $running_err = "N";
            
            &chk_error
            
         }
      }
      
   } else {
      
      $errmsg      = "No check for $DESC.  Out of time range.  Hour = $hour $start-$stop on days $dayofweek for server $HOSTNAME";
      print "$errmsg\n";
      $running_err = "O";
      
   }

   if ($debug_extensive) { print "subroutine chk_file ***  end  *** ^\n"; }

}
# end of chk_file subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: check_times()
#  
# -------------------------------------------------------------------
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
      $cmd =~ s/"//g;
      $MATCH_KEY   = $appl . ":" . $ito_obj . ":times:" . $severity;
      $errmsg_text = "Fileage errors have occurred $no_errors times for $errmsg_text";

      #if ($cmd ne "") { $cmd = "action=$cmd"; }

      $message = "Message from fileage monitoring via $config_file $disp_date $disp_time vposend_options: app=$appl sev=$severity message=$errmsg_text $cmd";

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

   if ($debug_extensive) { print "subroutine chk_times ***  end  *** ^\n"; }

}
# End of check_times
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: chk_error()
#  
# -------------------------------------------------------------------
sub chk_error {
   #
   # Check if error should be reported to VPO
   #

   if ($debug_extensive) { print "subroutine chk_error *** start *** v\n"; }

   $fname    =~ tr/\/\\\:/.._/;
   $file     =  "fileage_" . "$fname";
   $chk_file =  $SSM_HOLD . $file;
   $timefile =  $SSM_HOLD . $file . ".times";
   
   if ($debug_extensive) {
      print " fname:    $fname\n";
      print " file:     $file\n";
      print " chk_file: $chk_file\n";
      print " timefile: $timefile\n";
      print "\n\n";
   }

   if ("$running_err" eq "Y") {

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
         if ($debug_extensive) { print " mtime: $mtime\n\n"; }
         if ($debug_extensive) { print " Checking AGE of $SSM_HOLD$file ageInMinutes $ageInMinutes ITO_AGE $ITO_AGE\n"; }

         if ( $ageInMinutes > $ITO_AGE ) {

            if ($debug_extensive) { print "$errmsg_text\n"; }

            $action  =~ s/"//g;
            $SUP_KEY =  $appl . ":" . $fname . ":" . $severity;
            
            #if ($action ne "") { $action = "action=$action"; }
            
            $message = "Message from fileage monitoring via $config_file $disp_date $disp_time vposend_options: app=$appl sev=$severity message=$errmsg_text $action";

            process_vposend($message);            
            
            `echo $severity >> \"$SSM_HOLD$file\"`;
            
         }
         else {
            print "Problem was already reported $ageInMinutes minutes ago\n\n";
         }

      } else {
         
         &check_times;
         $action  =~ s/"//g;
         $SUP_KEY = $appl . ":" . $fname . ":" . $severity;
         #if ($action ne "") { $action = "action=$action"; }
         
         $message = "Message from fileage monitoring via $config_file $disp_date $disp_time vposend_options: app=$appl sev=$severity message=$errmsg_text $action";
         
         process_vposend($message);
         
         `echo $severity> \"$SSM_HOLD$file\"`;
         
      }

   } else {
      
      if ( -e "$SSM_HOLD$file" ) {
         
         unlink "$SSM_HOLD$file";

         if ($debug_extensive) { print "$errmsg_text\n"; }

         $action  =~ s/"//g;
         $action  =  "";
         $SUP_KEY =  $appl . ":" . $fname . ":normal";
         # open  (vposend, ">>$SSM_LOG");
         # print vposend ("Message from fileage monitoring $disp_date $disp_time __VPO__ app=$appl sev=normal message=$errmsg_text $action\n");
         # close (vposend);
      }
   }

   if ($debug_extensive) { print "subroutine chk_error ***  end  *** ^\n"; }

}
# end of chk_error subroutine
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
USAGE:

fileage --debug | --help | --v

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

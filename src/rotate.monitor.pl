###################################################################
#
#             File: rotate.monitor.pl
#         Revision: 2.50
#
#           Author: 
#
#    Original Date: 02/04
#
#      Description: This program rotate the configured log files.
#                   report errors base on $age that is passed to 
#                   this program.
#                   
#           Usage:  rotate.monitor.pl  
#
# Revision History:
#
#  Date   Initials  Vers  Description of Change
#
#  02/04    wpd     1.00  <Initial Version>
#  03/05    wpd     1.10  Add call to chk_running
#
#  2005-04-07 nichj 2.50: Added status report
#
#
#####################################################################

$version             = "$0 version 2.50\n";
$program_description = "rotate monitor";

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

$DEBUG_EXTENSIVE_ON  = "$SSM_CONF" . "rotate.monitor.debugextensive";
$DEBUG_ON            = "$SSM_CONF" . "rotate.monitor.debug";

check_debug_settings($DEBUG_ON, $DEBUG_EXTENSIVE_ON);

# ===================================================================
# Begining of Main
# ===================================================================
$status_file         = "$SSM_LOGS" . "rotate.monitor.status";
status_report("$program_description", "$status_file", "start");

if ( $opt_t or $opt_test ) {
  $debug = 1;
  $test  = 1;
  print "Running in Test Mode\n";
}

#
# Check to see if another instance of the monitor is running
#

$running_status = chk_running("rotate.monitor");

#
# Set up local variables
#

$now                    = time;
($sec,$min,$hour,$mday) = localtime(time);
# print "Now = $now\n";
if ( "$platform" eq "MSWin32" ) {
   $disp_date = `date/t`;
   chomp($disp_date);
   @date1 = split(/ /,$disp_date);
   @date2 = split(/\//,$date1[1]);
   $disp_time = `time /t`;
   chomp($disp_time);
   $disp_time =~ s/ /0/;
   $chk_date = $date2[2] . $date2[0] . $date2[1] . substr($disp_time,0,2) . substr($disp_time,3,2);;
   # print "chk_date = $chk_date - @date1 - @date2 - $disp_date\n";
   # $chk_date = $disp_date;
} else {
   $disp_date = `date`;
   chomp($disp_date);
   $chk_date = `date +%Y%m%d%H%M`;
   chomp($chk_date);
}

$rotate    = "$PWC_ETC" . "rotate.dat*";
$init_file = $PWC_BIN . "rotate.dat";
$init_chk  = $PWC_ETC . "rotate.dat";

if ( -e "$init_file" ) {
   if ( ! -e "$init_chk" ) {
      print "Installing $rotate\n";
      `$CP $init_file $PWC_ETC`;
   }
}

%opts = (
   "F" => { cl => "-F", lf => "file=" },
   "M" => { cl => "-M", lf => "minute=", },
   "A" => { cl => "-A", lf => "archivedir=",},
   "D" => { cl => "-D", lf => "days=", },
);

#
# Get the files in $PWC_ETC/ssm_pointers
#

if ( -e "$PWC_ETC/ssm_pointers" ) {
   print "Processing pointers\n";
   open (ssm_pointers, "$PWC_ETC/ssm_pointers");
   @pointers = <ssm_pointers>;
   @rotate_pointers = grep(/rotate/, @pointers);
   close(ssm_pointers);
   foreach $pointer (@rotate_pointers) {
      chomp($pointer);
      push (@appl_files, "$pointer\n");
   }
}

#
# Get the rotate.dat* files to process
#
@appl_files = get_config_files("rotate");
##
## 2005-04-07: nichj: commented out next section in favor of the above line.
##
#@conf_files = `$LL $rotate`;
#chomp(@conf_files);
#
#foreach $conf_file (@conf_files) {
#   if ( "$platform" eq "MSWin32" ) {
#      $config_file = $PWC_ETC . $conf_file;
#   } else {
#      $config_file = $conf_file;
#   }
#   push (@appl_files, "$config_file\n");
#}
#
#
# Get files from the .ssm directories for a mountpoint
#
#
#$MountInfo = $PWC_LOGS . "mount.info";
#open (mountpoint, "$MountInfo");
#@mountpoints = <mountpoint>;
#close(mountpoint);
#
#foreach $mount (@mountpoints) {
#   chomp($mount);
#   if ( "$platform" eq "MSWin32" ) {
#      $app_config_file = $mount . "\\ssm\\rotate.dat.*";
#      @app_files = `$LL $app_config_file`;
#      chomp(@app_files);
#      $app_files_found += @app_files;
#      # print "Checking for .ssm using $LL $app_config_file\n";
#      if ( $app_files_found > 0 ) {
#         foreach $app_file (@app_files) {
#            push (@appl_files, "$mount\\ssm\\$app_file\n");
#         }
#      }
#   } else {
#      $app_config_file = $mount . "/.ssm/rotate.dat.*";
#      @app_files = `$LL $app_config_file 2>/dev/null`;
#      chomp(@app_files);
#      $app_files_found += @app_files;
#      # print "Checking for .ssm in $mount\n";
#      if ( $app_files_found > 0 ) {
#         foreach $app_file (@app_files) {
#            push (@appl_files, "$app_file\n");
#         }
#      }
#   }
#}

foreach $config_file (@appl_files) {

   chomp($config_file);
   print "\nProcessing files in $config_file \n";

   @rotateinfo = read_file_contents("$config_file");
   #open (rotateinfo, "$config_file");
   #@rotateinfo = <rotateinfo>;
   #close(rotateinfo);
   
   foreach $line (@rotateinfo) {
    
      chomp($line);

      #
      # Check for blank line
      #
      $line      =~ s/^\s+//;
      $blank     =  (substr($line, 0, 1));
      
      if ("$blank" eq "") {next;};

      # 
      # Skip the line if it is a comment
      #
      $comment   =  (substr($line, 0, 1));
      if ("$comment" eq "#" ) { next; }
      if ("$comment" eq "\n") { next; }

      @fargs     = $line;
      
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
      @PARMS        =  split /\t/,$fargs[$fidx];
    
      #
      # Process the argument array
      #
      $file = $hour = $minute = $archivedir = $days = "";
      
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
            if ( "$vposend_arg" eq "-F" ) { $file       = "$a"; }
            if ( "$vposend_arg" eq "-M" ) { $minute     = "$a"; }
            if ( "$vposend_arg" eq "-A" ) { $archivedir = "$a"; }
            if ( "$vposend_arg" eq "-D" ) { $days       = "$a"; }
            $arg_cnt     = 0;
            
         } else {
          
            $arg_cnt     = 1;
            $vposend_arg = $a;
            
         }
      }

      chomp($file);

      chomp($minute);
      if ("$minute" eq "") {
         $minute = "1440";
      }

      chomp($archivedir);
      if ("$archivedir" eq "") {
        
         if ( "$platform" eq "MSWin32" ) {
            $archivedir = $PWC_ARCH;
         } else {
            $archivedir = "/var/opt/OV/log/archive/";
         }
         
      } else {

         #
         # Check if archive directory exists.  If not create it.
         #

         if (! -d $archivedir) {
            mkdir ("$archivedir",0775);
         }
         
         if ( "$platform" eq "MSWin32" ) {
            $archivedir = $archivedir . "\\";
         } else {
            $archivedir = $archivedir . "/";
         }
      }

      chomp($days);
      if ( "$days" eq "" ) {
         $days = "3";
      }
   
      print "\n\n";
      print "Checking archive files for $file\n\n";
      
      @files   =  `$LL \"$file\"`;
      $in_file =  $file;
      $in_file =~ s/%OVAgentDir%/$ov_dir/;
      
      foreach $file (@files) {
        
         chomp($file);
         &process_file;
         
      }
   }
}
####################################
#  End of foreach files
####################################

status_report("$program_description", "$status_file", "end_pass");
   
print "\n$program_description completed successfully\n";
exit 0;

# ===================================================================
# End of Main
# ===================================================================

# ===================================================================
# Start of SUBROUTINES
# ===================================================================

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
sub process_file {
   
   $new_file      = $archivedir . basename($in_file) . "\." . $chk_date;
   $archivefile   = $archivedir . basename($in_file) . "*";

   # 
   # Get the last archive file
   #

   @archive_files = "";

   print "Checking if any $archivefile exist\n";
   
   if ( "$platform" eq "MSWin32" ) {
    
      @archive_files = `cmd /c dir /O-D /B \"$archivefile\"`;
      $status        = $?;
      
   } else {
    
      @archive_files = `ls -1t $archivefile`;
      $status        = $?;
      
   }
   
   $diff = $ageInMinutes = $mtime = 0;

   if ( $status > 0 ) {
    
      print "The file $in_file has never been archived\n";
      $ageInMinutes  = $minute + 1;
      
   } else {
    
      $stat_file     = $archive_files[0];
      chomp($stat_file);
      
      if ( "$platform" eq "MSWin32" ) {   
         $stat_file  = $archivedir . $stat_file;
      }
      print "Checking if $stat_file is more than $minute minutes old\n";

      #
      # Stat the file
      #

      $mtime         = (stat ("$stat_file"))[9];
   
      #
      # Check how old the file is
      #
   
      $diff          = $now - $mtime;
      $ageInMinutes  = int($diff / 60);

      print "File $in_file was last archived $ageInMinutes minutes ago\n\n";
      # print "now =   $now\n";
      # print "mtime = $mtime\n\n";
   }

   #
   # Archive the file if ageInMinutes > configured minutes
   #

   if ( $ageInMinutes > $minute ) {
    
      print "Archiving $in_file to $new_file\n";
      
      if ( "$platform" eq "MSWin32" ) {
        
         print "Processing copy $in_file $new_file\n";
         `copy \"$in_file\" \"$new_file\"`;
         utime $now, $now, "$new_file";
         open (t1,">$in_file");
         close(t1);
         
      } else {
        
         `cp \"$in_file\" \"$new_file\"`;
         `> \"$in_file\"`;
         
      }
   }

   #
   # Check if any archive files should be removed
   #

   $days_minutes = $days * 1440;

   foreach $file (@archive_files) {
      
      chomp($file);

      if ( "$platform" eq "MSWin32" ) {   
         $file = $archivedir . $file;
      }

      $mtime        = (stat ("$file"))[9];
   
      #
      # Check how old the file is
      #
   
      $diff         = $now - $mtime;
      $ageInMinutes = int($diff / 60);

      print "Checking $file $ageInMinutes >= $days_minutes\n";
      if ($ageInMinutes >= $days_minutes) {
         print "Removing $file\n";
         unlink "$file";
      }
   }

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# end of process_file subroutine

# ===================================================================
# End of SUBROUTINES
# ===================================================================

# ===================================================================
# Start of FUNCTIONS
# ===================================================================
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

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
USAGE\n
";

}
# end of usage

=head1 TITLE

Filesys Monitor

=head1 DESCRIPTION

This program will check the file space used for
a particular file system, the available inodes and
optionally its' growth against the configuration in
$SSM_ETC/filesys.dat* files.

=head1 USAGE

    filesys.monitor [--debug] [--debugextensive] [--help] [--version]

=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.2 $

  ###################################################################
  # Revision History:
  #
  #  Date     Initials  Vers  Description of Change
  #
  #  Mar 2005  nichj    2.31: minor restructure - converted to latest header
  #                           added key to nfs error message
  #                           changed the text of the nfs error to be more descriptive
  #  
  #  2005-03-06 nichj   2.50: Added status reporting
  #
  #                     2.50.1: converted to using get_config_files
  #                     2.50.2: General clean up
  #                     2.50.3: Converted file reads to use read_file_contents($filename)
  #  2005-08-30 nichj   cvs   Converted to use BGI::ESM::Common::INC, Refactored slightly
  #  2005-08-31 nichj   cvs   Updated process_vposend to validate the existance of vposend
  #  2005-08-31 nichj   cvs   Moved process_vposend to ssm_common.pm
  #  2005-09-01 nichj   cvs   Moved to cvs/vpo/SSM/src
  #  2005-09-02 nichj   cvs   Added process_vposend test option
  #  2005-10-03 nichj         Added Carp, Data::Dumper, and File::stat to module list
  #  2005-10-12 nichj   cvs   Fix to include BGI::ESM::Common::Shared qw(os_type);
  #  2005-10-28 nichj   cvs   Converting to encapsulation, converting to process_vposend_lf
  #####################################################################

=cut

our $VERSION             = (qw$Revision: 1.2 $)[-1];
my  $version             = "$0 version $VERSION\n";

my  $program_description = "filesys.monitor";
our $prefix              = "filesys";
our (
        $opt_v, $opt_version,
        $opt_h, $opt_help,
        $opt_d, $opt_debug, $opt_debugextensive,
        $opt_t, $opt_test
   );

# =================================================================================
# Use Modules
# =================================================================================
use Getopt::Long;
#use strict;
use Carp;
use Data::Dumper;
use File::stat;
use File::Basename;

# =================================================================================
##### Point the lib to the CVS source location(s)
# =================================================================================
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;
use BGI::ESM::Common::Shared qw(os_type process_vposend_lf test_output_header test_output_footer move_file
                                write_file_contents);
use BGI::ESM::Common::Debug;
use BGI::ESM::Common::Variables;

# =================================================================================
##### Get the additional include locations from BGI::ESM::Common::INC
# =================================================================================
my $addl_inc = get_include_locations();
push @INC, @{$addl_inc};

# =================================================================================
##### Load common methods and variables
# =================================================================================
require "setvar.pm";
require "ssm_common.pm";

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
# Test check
# ===================================================================
our $test = test_check($opt_t, $opt_test);
if ($test) { test_output_header($prefix); }

# ===================================================================
# Setup variables
# ===================================================================
our $agt_vars    = agent_variables();
our $ssm_vars    = ssm_variables();
our $server_vars = server_variables();
our $commands    = get_command_hash();

# ===================================================================
# Check debug configuration
# ===================================================================

our $DEBUG_EXTENSIVE_ON  = $ssm_vars->{'SSM_CONF'} . "/filesys.monitor.debugextensive"; 
our $DEBUG_ON            = $ssm_vars->{'SSM_CONF'} . "/filesys.monitor.debug";

our ($debug, $debug_extensive) = get_debug($opt_debug, $opt_d, $opt_debugextensive,
                                           $DEBUG_ON, $DEBUG_EXTENSIVE_ON);

# ===================================================================
# Begining of Main
# ===================================================================

if ($debug) { print "\n === debug output ===\n\n"; }

our $status_file    = $ssm_vars->{'SSM_LOGS'} . "/filesys.monitor.status";
status_report("$program_description", "$status_file", "start");

if ($debug)                                                          { print "Checking for NFS issues...\n"; }
our $nfs_error_file = $ssm_vars->{'SSM_LOGS'} . "/vpo_nfs_error.tmp";

## Check for NFS errors.
##  This will call a function that touches a file, runs df, then removes the file
##  the program will return FALSE (1) if the df gets hung up.
##
## To simulate an nfs error, create a file called $SSM_CONF/loop.test
##
if ( nfs_error("$nfs_error_file") ) {
    if ($debug)                                                        { print "Found NFS issues.\n"; }
    status_report("$program_description", "$status_file", "end_fail", "probable NFS error");
    print "Filesys Monitor did not finish properly\n";
    exit 1;
}
else {
    if ($debug)                                                        { print "Clear of NFS issues.\n"; }
}

our %opts = (
   "F" => { cl => "-F", lf => "filesys="      },
   "a" => { cl => "-a", lf => "app=",         },
   "T" => { cl => "-T", lf => "size="         },
   "G" => { cl => "-G", lf => "growth="       },
   "I" => { cl => "-I", lf => "inode="        },
   "H" => { cl => "-H", lf => "start="        },
   "J" => { cl => "-J", lf => "stop="         },
   "W" => { cl => "-W", lf => "dayofweek="    },
   "D" => { cl => "-D", lf => "description="  },
   "A" => { cl => "-A", lf => "action="       },
   "s" => { cl => "-s", lf => "sev="          },
   "z" => { cl => "-z", lf => "severity="     },
   "M" => { cl => "-M", lf => "message_age=", },
   "E" => { cl => "-E", lf => "error_times="  },
   "S" => { cl => "-S", lf => "service=",     },
   "O" => { cl => "-O", lf => "source_host=",  },
);

#
# Set up local variables
#
our $age  = 60;

#
# Get the time
#
our $time = time;

#
# Set Time Variables
#
if ($debug)                                                          { print "\n debug process: Set time variables\n\n"; }

our $now = time;
our ($sec,$min,$hour,$day,$month,$year,$wkday,$julian,$dls) = localtime($time);
our $disp_date = get_display_date();
our $chk_date  = get_display_date();
#if ( os_type() eq 'WINDOWS' ) {
#  
#   $disp_time = `time/t`;
#   chomp($disp_time);
#   $disp_date = `date/t`;
#   chomp($disp_date);
#   $chk_date = $disp_date;
#   $disp_date = $disp_date . $disp_time;
#   
#}
#else {
#  
#   $disp_date = `date`;
#   chomp($disp_date);
#   $chk_date = `date +%Y%m%d`;
#   chomp($chk_date);
#   
#}

#
# Check to see if another instance of the monitor is running
#
our $running_status = chk_running("filesys.monitor");
if ($debug)                                                          { print " Running status for filesys.monitor = $running_status\n"; }



if ($debug)                                                          { print "\n debug process: Check the growth file " . $ssm_vars->{'SSM_LOGS'} . "/growth.info\n\n"; }
our $GrowthInfo = $ssm_vars->{'SSM_LOGS'} . "/growth.info";

if ( ! -e "$GrowthInfo" ) {
   `echo "" > $GrowthInfo`;
}
###

our $DiskInfo   = $ssm_vars->{'SSM_LOGS'} . "/disk.info";
our $DriveInfo  = $ssm_vars->{'SSM_LOGS'} . "/drive.info";
our $MountInfo  = $ssm_vars->{'SSM_LOGS'} . "/mount.info";
our $errchk     = $ssm_vars->{'SSM_LOGS'} . "/filesys_error";

our $FILESYSERR;
open ($FILESYSERR, ">$errchk") or croak "ERROR: Unable to open error check file $errchk: $!";


# list various variables as part of the debugging
if ($debug) {
                                                                     print "\n\n -- file variables --\n";
 
                                                                     print " diskinfo:   $DiskInfo\n";
                                                                     print " growthinfo: $GrowthInfo\n";
                                                                     print " driveinfo:  $DriveInfo\n";
                                                                     print " mountinfo:  $MountInfo\n";
                                                                     print " errchk:     $errchk\n";
   
                                                                     print "\n\n -- other variables --\n";
                                                                     print " disp_date:  $disp_date\n";
                                                                     print " chk_date:   $chk_date\n";
                                                                     print " now:        $now\n";
                                                                     print " platform:   " . os_type() . "\n";
                                                                     print " age:        $age\n";
                                                                     print "\n";
                                                                     print "Options:\n";
                                                                     print Dumper \%opts;
                                                                     print "\n";
   
}
###

if ($debug)                                                        { print "\n debug process: currently processing $DiskInfo $DriveInfo\n\n"; }

# ===================================================================
# End of Setup
# ===================================================================

# ===================================================================
# Start of Main Processing
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
if ($debug)                                                        { print "\n\n --- main section --- vvv starting vvv\n\n"; }

#
# Process old Growth Information
#
our @growthdata = read_file_contents("$GrowthInfo");
#unless (open(growthdata, "$GrowthInfo")) {
#
#   print "cannot open input file $GrowthInfo\n";
#
#}
#else {
#
#   @growthdata = <growthdata>;
#   close(growthdata);
#
#}

#
# Get File System configuration
#
if ($debug)                                                               { print "\n debug processes: Getting drive information " . $commands->{'DF'} . "\n"; }

our (
        @df_rec, @df, $drive,
        $fld_cnt, $fld_chk, $total, $free,
        $percent, @mountpoints, @app_files,
        $app_files_found, $app_config_file,
        @appl_files, @chk_field,
        $FS, @percent, $PER, $Percent, @PER,
        @output, @ipercent, $INODE, @INODE,
        $Inode_Percent, 
    );

our $DF = $commands->{'DF'};
our $LL = $commands->{'LL'};
our $CP = $commands->{'CP'};

if ( os_type() eq 'WINDOWS' ) {

    system "$DF > $DriveInfo";
    @df_rec = read_file_contents("$DriveInfo");
    @df = grep(/FIXED/, @df_rec);
   
}
else {
   
    @df = `$DF`;
   
    #if ( "$os" eq "SunOS" ) {
    #   @output = `df -o i 2>/dev/null`;
    #}
   
}
###

if ($debug)                                                               { print "\n debug processes: Got drive information for " . os_type() . "\n"; }

open (DiskInfo, ">$DiskInfo");

foreach my $filesys (@df) {
   
    if ($debug)                                                            { print " debug process: checking " . os_type() . " for $filesys\n"; }
   
    if ( os_type() eq 'WINDOWS' ) {
        chomp($filesys);
      
        our $chk = (substr($filesys,1,1));
        our @fields = split(/\s+/, $filesys);
    
        if ($debug)                                                         { print " debug process: Processing $filesys\n"; }
    
        if ("$chk" eq ":" ) {
    
            $drive   =  substr($fields[0],0,2);
            $fld_cnt += @fields;
            $fld_chk =  0;
    
            foreach my $fld_rec(@fields) {
     
                if ($debug)                                                   { print " debug process: Processing $fld_rec\n"; }
                
                if ("$fld_rec" eq "FIXED") {
                  
                    $total = $fields[$fld_chk+2];
                    $free  = $fields[$fld_chk+4];
                    if ($debug)                                                { print " debug process: drive=$drive\ntotal=$total\nfree=$free\n"; }
                
                }
                else {
                  
                    $fld_chk ++;
                   
                }
            }
    
           $percent = (($free * 100) / $total);      # percent available
           $percent = 100 - $percent;                # percent used
           $percent = int($percent);
    
           if ($debug)                                                      { print " debug process: Drive=$drive  total= $total   Free=$free Percent=$percent\n"; }
    
           print DiskInfo ("$drive $percent 0\n");
           chomp($drive);
           push (@mountpoints, "$drive\n");
           $app_config_file  = $drive . "\\ssm\\filesys.dat.*";
           @app_files        = `$LL $app_config_file`;
           chomp(@app_files);
           $app_files_found += @app_files;
           print "Checking for .ssm using $LL $app_config_file\n";
           
           if ( $app_files_found > 0 ) {
              foreach my $app_file (@app_files) {
                 push (@appl_files, "$drive\\ssm\\$app_file\n");
              }
           }
      }
      
   }
   else {
    
        #
        # Eliminate the non file system records
        #
        @chk_field = split(/ /, $filesys);
        
        if ("$chk_field[0]" eq "Filesystem") {
           next;
        }
        
        our $fld_count = 0;
        foreach my $fld (@chk_field) {
          
            $fld_count ++;
           
        }
        
        if ($fld_count == 1) {
          
           next;
           
        }
    
        #
        #  Get the mountpoint name
        #
    
        $FS               = $chk_field[$fld_count - 1];
        chomp($FS);
        push (@mountpoints, "$FS\n");
        $app_config_file  = $FS . "/.ssm/filesys.dat.*";
        @app_files        = `$LL $app_config_file 2>/dev/null`;
        chomp(@app_files);
        $app_files_found += @app_files;
        
        if ($debug) {  print " debug process: Checking for .ssm in $FS\n"; }
        
        if ( $app_files_found > 0 ) {
           foreach my $app_file (@app_files) {
              push (@appl_files, "$app_file\n");
           }
        }
    
        #
        #  Get the size percent full
        #
        @percent = split(/% /, $filesys);
        $PER     = $percent[0];
        @PER     = split(/ /, $PER);
        $Percent = pop(@PER);
    
        #
        #  Get the inode percent full
        #
        #if ( "$os" eq "SunOS" ) {
        #
        #   # @output = `df -o i $FS 2>/dev/null`;
        #   @percent_rec = grep(/$FS/, @output);
        #   @ipercent    = split /% /, $percent_rec[0];
        #   $INODE       = @ipercent[0];
        #   @INODE       = split /\s+/, $INODE;
        #   
        #   if (@INODE) {
        #      $Inode_Percent = pop(@INODE);
        #   }
        #   else {
        #      $Inode_Percent = 0;
        #   }
        #   
        #}
        if ( os_type() eq 'LINUX' ) {
           
           @output   = `df -i $FS`;
           @ipercent = split /% /, $output[1];
           $INODE    = $ipercent[0];
           @INODE    = split /\s+/, $INODE;
           
           if (@INODE) {
              $Inode_Percent = pop(@INODE);
           }
           else {
              $Inode_Percent = 0;
           }
           
        }
        else {
           
           $INODE         = $percent[1];
           @INODE         = split(/ /, $INODE);
           $Inode_Percent = pop(@INODE);
           
        }
    
        print DiskInfo ("$FS $Percent $Inode_Percent\n");
     }
     ###
}
###

#close (DiskInfo);
#open  (DiskInfo, "$DiskInfo");
#@DiskInfo = <DiskInfo>;
#close (DiskInfo);
our @DiskInfo = read_file_contents("$DiskInfo");
chomp (@DiskInfo);

#
# Get the bad mount default data
#
&get_badmount_information;

##
## Update mountpoints for use by other programs
##

@mountpoints = read_file_contents("$MountInfo");
#open (mountdata, ">$MountInfo");
#print mountdata (@mountpoints);
#close(mountdata);

#
# Get the files in $SSM_ETC
#
our $config_file = $ssm_vars->{'SSM_ETC'} . "/filesys.dat.*";
@appl_files  = get_config_files("filesys");

#
# Check for system specific configuration files
#
our $init_file    = $ssm_vars->{'SSM_BIN'} . "/filesys.dat";
our $chk_def_file = "filesys.dat";
our $ignore_file  = "filesys.dat.ignore";

our (
        $conf_file, @fsconf, $blank, $comment,
        @fargs, $fargs, $fidx, @PARMS, 
        $Error_Times, $DESC, $dir, $file,
        $appl, $action, $severity,
        $ITO_AGE, $Service, $start, $stop,
        $dayofweek, $source_host, $file_notfound,
        $fname, $cmd, $fs_growth, $fs_inode, $desc,
        $arg_cnt, $vposend_arg, $fsname, $fs_size,
        @configured, 
    );

foreach my $file (@appl_files) {

   chomp($file);
   
   if ( os_type() eq 'WINDOWS' ) {
      $chk_def_file = basename($file);
   }
   else {
      $chk_def_file = $file;
   }
   
   if ($debug)                                                            { print "\n debug process: Checking $file -- $chk_def_file against filesys.dat\n"; }
   
   if ( "$chk_def_file" eq "filesys.dat" ) { 
      next; 
   }

   #
   # Process the configuration records for each file
   #
   print "\n\n*** Processing configuration file $file\n\n";

   $conf_file = $file;

   @fsconf    = read_file_contents("$conf_file");
   #open(fsconf, "$file");
   #@fsconf    = <fsconf>;
   #close(fsconf);

   foreach my $line (@fsconf) {

      chomp($line);
      #
      # Check for blank line
      #
      $line      =~ s/^\s+//;
      $blank     =  (substr($line, 0, 1));
      
      if ("$blank" eq "") { next; }

      $comment   =  (substr($line, 0, 1));
      
      if (($comment ne "#") && ($comment ne " ")) {

         @fargs        =  $line;
         
         foreach my $o ( keys %opts ) {
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
        (
            $Error_Times, $DESC, $dir, $file,
            $appl, $age, $action, $severity,
            $ITO_AGE, $Service, $start, $stop,
            $dayofweek, $source_host, $file_notfound,
            $fname, $cmd, $fs_growth, $fs_inode, $desc,
        ) = "";

         foreach my $a (@PARMS) {
            #
            # Strip leading AND trailing spaces per field ...arrrg
            #
            $a =~ s/^\s*(.*?)\s*$/$1/;
            
            if ( $arg_cnt == 1 ) {
               
               #
               # Set the variables used for processing
               #
               if ( "$vposend_arg" eq "-F" ) { $fsname      = "$a";   }
               if ( "$vposend_arg" eq "-a" ) { $appl        = lc($a); }
               if ( "$vposend_arg" eq "-T" ) { $fs_size     = $a;     }
               if ( "$vposend_arg" eq "-G" ) { $fs_growth   = $a;     }
               if ( "$vposend_arg" eq "-I" ) { $fs_inode    = $a;     }
               if ( "$vposend_arg" eq "-H" ) { $start       = "$a";   }
               if ( "$vposend_arg" eq "-J" ) { $stop        = "$a";   }
               if ( "$vposend_arg" eq "-W" ) { $dayofweek   = lc($a); }
               if ( "$vposend_arg" eq "-D" ) { $desc        = $a;     }
               if ( "$vposend_arg" eq "-A" ) { $cmd         = "$a";   }
               if ( "$vposend_arg" eq "-s" ) { $severity    = lc($a); }
               if ( "$vposend_arg" eq "-z" ) { $severity    = lc($a); }
               if ( "$vposend_arg" eq "-M" ) { $ITO_AGE     = $a;     }
               if ( "$vposend_arg" eq "-E" ) { $Error_Times = $a;     }
               if ( "$vposend_arg" eq "-S" ) { $Service     = $a;     }
               if ( "$vposend_arg" eq "-O" ) { $source_host = $a;     }
               $arg_cnt = 0;

            }
            else {

               $arg_cnt     = 1;
               $vposend_arg = $a;

            }
         }
         ###

         chomp ($source_host);
         #$source_host = trim($source_host);
   
         # Source Host Check - if source_host_check returns 1 the source_host option matches
         if (source_host_check($source_host)) {
            if ($debug)                                                { print " match on source host: $source_host\n"; }
         }
         else {
            if ($debug)                                                { print " no match on source host: $source_host\n"; }
            next;
         }

         if ($debug) {
                                                                         print "\n";
                                                                         print " debug process: ::: Checking for $line";
                                                                         print "\n"; 
                                                                         print "\n";
                                                                         print " debug process:     fsname = $fsname";
                                                                         print "\n";
                                                                         print "                    desc   = $desc";
                                                                         print "\n";
         }

         if ("$start" eq "") {
            $start       = "00";
         }

         if ("$stop" eq "") {
            $stop        = "24";
         }

         if ($desc eq "") {
            $desc        = $fsname ;
         }

         if ( ("$dayofweek" eq "") or ("$dayofweek" eq "all") ) {
            $dayofweek   = "sun mon tue wed thu fri sat";
         }

         # if severity is blank or not equal to a known value set it to major.
         chomp($severity);
         if ( "$severity" eq "" ) {
            $severity    = "major";
         }
         
         if (    "$severity" ne "critical"
              && "$severity" ne "major"
              && "$severity" ne "minor"
              && "$severity" ne "warning"
              && "$severity" ne "normal"
            ) {
               $severity  = "major";
         }
         
         chomp($ITO_AGE);
         if ( "$ITO_AGE" eq "" ) {
            $ITO_AGE      = 60;
         }
         
         chomp($Error_Times);
         if ( "$Error_Times" eq "" ) {
            $Error_Times  = 0;
         }
         
         chomp($Service);
         if ( "$Service" eq "" ) {
            $Service      = "os";
         }

         #
         # Check for 'default' or 'badmount' records
         #
         if ( "$fsname" eq "default" || "$fsname" eq "badmount" ) { next; }

         if ($debug) {
                                                                          print "\n\n --- main processing variables ---\n";
                                                                          print " fsname:      $fsname\n";
                                                                          print " appl:        $appl\n";
                                                                          print " fs_size:     $fs_size\n";
                                                                          print " fs_growth:   $fs_growth\n";
                                                                          print " fs_inode:    $fs_inode\n";
                                                                          print " start:       $start\n";
                                                                          print " stop:        $stop\n";
                                                                          print " dayofweek:   $dayofweek\n";
                                                                          print " desc:        $desc\n";
                                                                          print " cmd:         $cmd\n";
                                                                          print " severity:    $severity\n";
                                                                          print " ITO_AGE:     $ITO_AGE\n";
                                                                          print " Error_Times: $Error_Times\n";
                                                                          print " Service:     $Service\n";
                                                                          print " Source HOst: $source_host\n";
                                                                          print " \n";
         }

         push (@configured, "$fsname\n");
         &chk_data;
         
      }
      ###
   }
   ###
}
###

#
#  Process the default configuration
#
if ($debug)                                                             { print "\n Processing the default config file\n\n"; }
      
$file      = $ssm_vars->{'SSM_ETC'} . "/filesys.dat";
$init_file = $ssm_vars->{'SSM_BIN'} . "/filesys.dat";
our ($DEFAULTFILE);

unless (open ($DEFAULTFILE, "$file")) {
   
    if ( -e "$init_file" ) {
     
        print "Installing $file\n";
        my $ssm_etc_dir = $ssm_vars->{'SSM_ETC'};
       `$CP $init_file $ssm_etc_dir`;
       
    }
    else {
     
       print "\n*** No default configuration file exists\n";
       exit 0;
       
    }
   
}
###

our @Default         =  <$DEFAULTFILE>;
close($DEFAULTFILE) or carp "Error: Unable to close file $file: $!";
our @default_rec     =  grep(/filesys=default/, @Default);
#$default_rec     =  @default_rec[0];
chomp(@default_rec);
@default_rec = strip_comments_from_array(@default_rec);
# 
# process all the default configuration records
#
foreach our $default_rec (@default_rec) {
    &process_default;
}

close ($FILESYSERR);

#
# check number of times error has occurred today
#
our @filesyserr   = read_file_contents("$errchk");
our @filesyserr2  = sort(@filesyserr);
our $holdkey      = "";

print "\n\n*** Check for errors\n\n";

our ($chkkey, $vpomsg, $chkerrkey, $sev, );

foreach my $filesyserr (@filesyserr2) {
  
   ($chkkey, $ITO_AGE, $Error_Times, $vpomsg) = split(/\.\-\./,$filesyserr);
   ($chkerrkey, $sev) = split(/___/,$chkkey);
   # print "Checking if $holdkey equals $chkerrkey\n";
   
   if ( "$holdkey" ne "$chkerrkey" ) {

      $file =  "$chkerrkey";
      $file =~ tr/ /./;

      if ( "$sev" eq "0" ) { $severity = "critical" };
      if ( "$sev" eq "1" ) { $severity = "major"    };
      if ( "$sev" eq "2" ) { $severity = "minor"    };
      if ( "$sev" eq "3" ) { $severity = "warning"  };
      if ( "$sev" eq "4" ) { $severity = "normal"   };

      #print "Processing key $chkerrkey msg $vpomsg\n";
      #print "Processing key $chkerrkey to $SSM_LOG\n";

      chomp($vpomsg);

      if ($debug_extensive)                                  { print "  vpomsg from filesyserr file: $vpomsg\n"; }
      
      &chk_error;
      
   }
   
   $holdkey = $chkerrkey;
   
}
###

#
#  Check for return to normal condition
#
#
#   if ( -e "$SSM_HOLD$file" ) {
#      unlink "$SSM_HOLD$file";
#      $cmd =~ s/"//g;
#      $ito_obj = "$type-$fsname";
#      $severity = "normal";
#      $MATCH_KEY = $appl . ":" . $ito_obj . ":" . $severity;
#      $MATCH_KEY =~ s/ //g;
#      $MATCH_KEY =~ s/"//g;
# 
#      open (vposend, ">>$SSM_LOG");
#      print vposend ("$vpomsg\n");
#      close (vposend);
#   }

if ($debug)                                                  { print "\n --- main section --- ^^^ ending ^^^\n\n";}

status_report("$program_description", "$status_file", "end_pass");

print "\n$program_description completed successfully\n";
if ($test) { test_output_footer($prefix); }

exit 0;

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# ===================================================================
# End of Main Processing
# ===================================================================

# ===================================================================
# Start of SUBROUTINES
# ===================================================================

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub process_default {

   @fargs           = $default_rec;

   foreach my $o ( keys %opts ) {
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
   $dir = $file = $appl = $age = $action = $severity = $ITO_AGE = $Service = $cmd = $fs_growth = $fs_inode = $start = $stop = $desc = $source_host = "";
   
   foreach $a (@PARMS) {
      #
      # Strip leading AND trailing spaces per field ...arrrg
      #
   
      $a =~ s/^\s*(.*?)\s*$/$1/;
      if ( $arg_cnt == 1 ) {
         #
         # Set the variables used for processing
         #
         if ( "$vposend_arg" eq "-F" ) { $fsname      = "$a";   }
         if ( "$vposend_arg" eq "-a" ) { $appl        = lc($a); }
         if ( "$vposend_arg" eq "-T" ) { $fs_size     = $a;     }
         if ( "$vposend_arg" eq "-G" ) { $fs_growth   = $a;     }
         if ( "$vposend_arg" eq "-I" ) { $fs_inode    = $a;     }
         if ( "$vposend_arg" eq "-H" ) { $start       = "$a";   }
         if ( "$vposend_arg" eq "-J" ) { $stop        = "$a";   }
         if ( "$vposend_arg" eq "-W" ) { $dayofweek   = lc($a); }
         if ( "$vposend_arg" eq "-D" ) { $desc        = lc($a); }
         if ( "$vposend_arg" eq "-A" ) { $cmd         = "$a";   }
         if ( "$vposend_arg" eq "-s" ) { $severity    = lc($a); }
         if ( "$vposend_arg" eq "-M" ) { $ITO_AGE     = $a;     }
         if ( "$vposend_arg" eq "-E" ) { $Error_Times = $a;     }
         if ( "$vposend_arg" eq "-S" ) { $Service     = $a;     }
         if ( "$vposend_arg" eq "-O" ) { $source_host  = $a;    }
         $arg_cnt     = 0;
   
      }
      else {
   
         $arg_cnt     = 1;
         $vposend_arg = $a;
   
      }
   }
   
   if ("$start" eq "") {
      $start       = "00";
   }
   
   if ("$stop" eq "") {
      $stop        = "24";
   }
   
   if ("$dayofweek" eq "" || "$dayofweek" eq "all" ) {
      $dayofweek   = "sun mon tue wed thu fri sat";
   }

   #
   # Check the day of week
   #

   ($sec,$min,$hour,$day,$month,$year,$wkday,$julian,$dls) = localtime($time);
   if      ( $wkday == 0 ) {
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
   }
   else {
      $wkday = "sat";
   }

   $dayofweek =~ s/,/ /g;
   $dayofweek =  lc($dayofweek);

   @dayofweek =  "";
   push(@dayofweek, "$dayofweek");

   $dw_found  =  grep(/$wkday/, @dayofweek);

   # print "Checking for $wkday in @dayofweek start=$start stop=$stop hour=$hour\n";
   
   # if severity is blank or not equal to a known value set it to major.
   chomp($severity);
   if ( "$severity" eq "" ) {
      $severity    = "major";
   }
   
   if (    "$severity" ne "critical"
        && "$severity" ne "major"
        && "$severity" ne "minor"
        && "$severity" ne "warning"
        && "$severity" ne "normal"
   ) {
         $severity = "major";
   }

   chomp($ITO_AGE);
   if ( "$ITO_AGE" eq "" ) {
      $ITO_AGE     = 60;
   }
   
   chomp($Error_Times);
   if ( "$Error_Times" eq "" ) {
      $Error_Times = 0;
   }
   
   chomp($Service);
   if ( "$Service" eq "" ) {
      $Service     = "os";
   }
   
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
   
   print "\n*** Checking all other File Systems against the Default\n\n";
   
   foreach $rec (@DiskInfo) {
      
      ($fsname, $disk_info, $inode_info) = split(/ /, $rec);
      $val = 0;
      
      foreach $ref (@configured) {
       
         chomp($ref);

         ($fname) = split(/,/, $ref);
         
         if ("$fname" eq "$fsname") {
            $val  = 1;
            last;
         }
         
      }
      
      if ($val == 0) {

         $maxtime_err = "N";
         $running_err = "N";
   
         #
         # Check if within start and stop monitor times
         #
   
         if (($hour >= $start) && ($hour < $stop) && ($dw_found > 0)) {
   
            #
            # Check file system space
            #
   
            $desc = $fsname;
            if ( index($fsname, "cdrom") < 0 ) {
               &chk_data;
            }
         }
      }
      ###
   }
}
#--------------------------------------------------------------------
# End of process_default
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub chk_data {
  
   if ($debug_extensive) { print "\n  debug process: chk_data sub *** start *** v\n"; }
   
   $maxtime_err = "N";

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

   #
   # Check the day of week
   #

   ($sec,$min,$hour,$day,$month,$year,$wkday,$julian,$dls) = localtime($time);
   if      ( $wkday == 0 ) {
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
   }
   else {
      $wkday = "sat";
   }

   $dayofweek =~ s/,/ /g;
   $dayofweek =  lc($dayofweek);

   @dayofweek =  "";
   push(@dayofweek, "$dayofweek");

   $dw_found  =  grep(/$wkday/, @dayofweek);

   # print "Checking for $wkday in @dayofweek start=$start stop=$stop hour=$hour\n";

   if (($hour >= $start) && ($hour < $stop) && ($dw_found > 0)) {

      #
      # Check file system space
      #

      $found = 0;
      
      foreach $ref (@DiskInfo) {
        
         ($fname, $disk_info, $inode_info) = split(/ /, $ref);
        
         if ("$fname" eq "$fsname") {
            $found=1;
            last;
        
         }
         else {
        
            $disk_info = $inode_info = 0;
        
         }
         
      }

      #
      # The configured file system is not valid.  Report error.
      #

      if ($found == 0) {
        
         $chk_conf_file = basename($conf_file);
         
         if ("$chk_conf_file" ne "$ignore_file") {
         
            if ( "$platform" ne "MSWin32" ) {
               &chk_badmount;
            }
         
            return;
         
         }
      }

      &chk_growth;
      
      $running_err = "N";
      &chk_size;
      print "$errmsg\n";
      
      if ($fs_inode > 0) {
        
         $running_err = "N";
         &chk_inodes;
         print "$errmsg\n\n";
         
      }

   }
   else {
    
      $errmsg = "No check for $desc.  Out of time range.  $start-$stop on days $dayofweek";
      print "$errmsg\n";

   }
   ###

   open(growthdata, ">$GrowthInfo");
   print growthdata (@growth_new);
   close(growthdata);
   
  if ($debug_extensive) { print "\n  debug process: chk_data sub ***  end  *** ^\n\n"; }

}
###
#--------------------------------------------------------------------
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub capture_error {
   if ($debug_extensive) { print "\n  debug process: capture_error sub *** start *** v\n"; }
   if ($debug_extensive) { print "\n  debug process: $errmsg\n\n"; }
   if ( "$running_err" eq "Y" ) {
      #
      # Write error to error capture file
      #
      $fsname    =~ tr/\/\\:/.. /;
      $applname  =  $appl;
      $applname  =~ tr/\/\\:\"/.. ./;
      $file      =  "$type" . "$fsname" . "." . "$applname";
      $timefile  =  $SSM_HOLD . $file . ".times";
      
      if ( "$severity" eq "critical" ) { $errsev = "0"; }
      if ( "$severity" eq "major" )    { $errsev = "1"; }
      if ( "$severity" eq "minor" )    { $errsev = "2"; }
      if ( "$severity" eq "warning" )  { $errsev = "3"; }
      if ( "$severity" eq "normal" )   { $errsev = "4"; }
      
      $errkey    =  $type . $fsname . $applname;
      chomp($errkey);
      $errkey    =~ tr/\./ /;

      $errkey    =  "$errkey" . "___" . "$errsev";

      $cmd       =~ s/"//g;
      $ito_obj   =  "$type-$fsname";
      $MATCH_KEY =  $appl . ":" . $ito_obj . ":" . $severity;
      $MATCH_KEY =~ s/ //g;
      $MATCH_KEY =~ s/"//g;

      if ($cmd ne "") { $cmd = "action=$cmd"; }
      
      print filesyserr ("$errkey.-.$ITO_AGE.-.$Error_Times.-.Message from file space monitoring via $conf_file $disp_date (capture_error) vposend_options: app=$appl sev=$severity $cmd message=$errmsg\n");
      
   }
   
   # debug the variables
   if ($debug_extensive) {
      print "  -- capture_error variables --\n";
      print "  running_err: $running_err\n";
      print "  fsname:      $fsname\n";
      print "  applname:    $applname\n";
      print "  file:        $file\n";
      print "  timefile:    $timefile\n";
      print "  severity:    $severity\n";
      print "  errsev:      $errsev\n";
      print "  type:        $type\n";
      print "  errkey:      $errkey\n";
      print "  cmd:         $cmd\n";
      print "  MATCH_KEY:   $MATCH_KEY\n";
      print " \n";
   }

   if ($debug_extensive) { print "\n  debug process: capture_error sub ***  end  *** ^\n\n"; }
}
#--------------------------------------------------------------------
# end of capture_error subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub chk_error {
   if ($debug_extensive) { print "\n  debug process: chk_error sub *** start *** v\n"; }
   
   #
   # Check if error should be reported to vpo
   #
   ($dummy1, $msg1) = split(/message=/, $vpomsg);
   # ($msg2, $dummy2) = split(/ key=/, $msg1);

   #
   # Get the previous error level
   #
   if (-e "$SSM_HOLD$file") {
      open(hold_file, "$SSM_HOLD$file");
      @old_sev = <hold_file>;
      ($old_severity, $dummy) = split(/ /, $old_sev[0]);
      chomp($old_severity);
      close(hold_file);
   }
   
   if (-e "$SSM_HOLD$file" && "$old_severity" eq "$severity") {
      if ($debug_extensive) { print "\n  debug process: 1. Checking for $SSM_HOLD$file and $severity old .$old_severity. age $ITO_AGE\n\n"; }
      #
      # Stat the ITO Error Age file
      #
      $mtime        = (stat ("$SSM_HOLD$file"))[9];

      #
      # Check how old the file is in minutes
      #
      $diff         = $now - $mtime;
      $ageInMinutes = int($diff / 60);

      #
      if ( $ageInMinutes > $ITO_AGE ) {
         process_vposend_lf($vpomsg, $test, $prefix);
         `echo $severity > $SSM_HOLD$file`;
         
         &check_times;

      }
      else {

         print "This message was reported $ageInMinutes minutes ago: $msg1\n\n";

      }

   }
   else {

      if ($debug_extensive) { print "\n  debug process: 2. Checking for $SSM_HOLD$file and $severity old .$old_severity. age $ITO_AGE\n\n"; }
      process_vposend_lf($vpomsg, $test, $prefix);

      `echo $severity > $SSM_HOLD$file`;
      &check_times;
      
   }
   
   # list variables
   if ($debug_extensive) {
      print "  --- chk_error variables ---\n";
      print "  old_severity: $old_severity\n";
      print "  ageInMinutes: $ageInMinutes\n";
      print "  mtime:        $mtime\n";
      print "  diff:         $diff\n";
      print "  dummy1:       $dummy1\n";
      print "  msg:          $msg\n";
      print "  vpomsg:       $vpomsg\n";
      print "  \n";
   }

   if ($debug_extensive) { print "\n  debug process: chk_error sub ***  end  *** ^\n\n"; }
   
}
#--------------------------------------------------------------------
# end of chk_error subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub check_times {
  if ($debug_extensive) { print "\n  debug process: check_times sub *** start *** v\n"; }

  # 
  # This subroutine will check how many times the error has been reported today
  #
   #
   # Add a date record for this error
   #
   $timefile  =  $SSM_HOLD . $file . "times";
   $timefile  =~ s/ //g;
   
   system "echo $chk_date >> $timefile";
   @time_file =  read_file_contents("$timefile");
   #open (time_file, "$timefile");
   #@time_file =  <time_file>;
   #close(time_file);
   chomp(@time);

   $newfile   =  $timefile . "new";
   
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
   
   # print "Checking times:  $no_errors --> $Error_Times\n";
   if ( $no_errors > $Error_Times && $Error_Times > 0 ) {
      #
      # Put Number of times error to ITO
      #
      # ($dummy1, $msg1) = split(/message=/, $vpomsg);
      # ($msg2, $dummy2) = split(/ key=/, $msg1);
      # ($msg3, $dummy2) = split(/ action=/, $dummy2);
      # $newmsg = $dummy1 . "message=" . $msg2 . " has occurred $no_errors times today. key=times:" . $msg3;
      $newmsg = $vpomsg . " has occurred $no_errors times today.";
      
      process_vposend_lf($newmsg, $test, $prefix);
      
   } 
   
   #
   # Reset the count hold file
   #
   unlink "$timefile";
   $newfile  =~ s/ //g;
   $timefile =~ s/ //g;
   
   `$MV $newfile $timefile`;

   #debug variable output
   if ($debug_extensive) {
      print "  --- check_times variables ---\n";
      print "  timefile:  $timefile\n";
      print "  newfile:   $newfile\n";
      print "  date_rec:  $date_rec\n";
      print "  chk_date:  $chk_date\n";
      print "  no_errors: $no_errors\n";
      print "  newmsg:    $newmsg\n";
      print "  \n";
   }
   
   if ($debug_extensive) { print "\n  debug process: check_times sub ***  end  *** ^\n\n"; }
}
#--------------------------------------------------------------------
# End of check_times
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub chk_growth {
   if ($debug_extensive) { print "\n  debug process: chk_growth sub *** start *** v\n"; }
   #
   # Save info for growth check
   #

   $growth_new = "$fsname,$disk_info";
   push (@growth_new, "$growth_new\n");

   #
   # Calculate Growth
   #

   if ("$fs_growth" ne "") {
    
      @Sizerec = grep(/$fsname/, @growthdata);
      foreach $growth_rec (@growthdata) {
         ($SizeFs,$Old_Size) = split(/,/, $growth_rec);
         if ("$SizeFs" eq "$fsname") {
            last;
         }
      }
      
      chomp($Old_Size);

      $Growth = int($disk_info - $Old_Size);
      
      if ($Old_Size > $disk_info) {
         $Growth = 0;
      }
      
      if ("$Old_Size" ne "") {
        
         if ($Growth > $fs_growth) {
          
            print "Growth on $desc $Growth% is greater than $fs_growth%.\n";
            $fsname      =~ tr/\/\\/../;
            $cmd         =~ s/"//g;
            $ito_obj     =  "growth-$fsname";
            $MATCH_KEY   =  $appl . ":" . $ito_obj . ":growth:" . $severity;
            $MATCH_KEY   =~ s/ //g;
            $MATCH_KEY   =~ s/"//g;
            $errmsg_text =  "Diskspace utilization on $desc grew $Growth% which is greater than the threshold of $fs_growth% on server $HOSTNAME.";
          
            if ($cmd ne "") { $cmd = "action=$cmd"; } 
          
            $message = "Message from file space monitoring via $conf_file $disp_date (chk_growth) vposend_options: app=$appl sev=$severity $cmd message=errmsg_text";
          
            process_vposend_lf($message, $test, $prefix);
            
         }
      }
   }
   
   # variable output
   if ($debug_extensive) {
      print "  --- chk_growth variables ---\n";
      print "  growth_new:  $growth_new\n";
      print "  fs_growth:   $fs_growth\n";
      print "  old_size:    $old_size\n";
      print "  fsname:      $fsname\n";
      print "  cmd:         $cmd\n";
      print "  ito_obj:     $ito_obj\n";
      print "  MATCH_KEY:   $MATCH_KEY\n";
      print "  errmsg_text: $errmsg_text\n";
      print "  \n";
      
   }
   
   if ($debug_extensive) { print "\n  debug process: chk_growth sub ***  end  *** ^\n\n"; }

}
#--------------------------------------------------------------------
# end of chk_growth subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub chk_size {
   if ($debug_extensive) { print "\n  debug process: chk_size sub *** start *** v\n"; }

   #
   # Check if space > configured threshold
   #

   # print "Checking size for $desc $disk_info vs $fs_size\n";
  
   $errmsg = "Disk utilization for $desc is currently $disk_info% full.  The threshold is $fs_size% on server $HOSTNAME";
   if ($disk_info > $fs_size) {
      $running_err = "Y";
      $errmsg = "Disk utilization for $desc is currently $disk_info% full which is greater than the threshold of $fs_size% on server $HOSTNAME.";
   }
   $type="diskspace";
   &capture_error;

   if ($debug_extensive) {
      print "  --- chk_size variables ---\n";
      print "  errmsg:      $errmsg\n";
      print "  disk_info:   $disk_info\n";
      print "  running_err: $running_err\n";
      print "  type:        $type\n";
      print "  \n";
   }
   
   if ($debug_extensive) { print "\n  debug process: chk_size sub ***  end  *** ^\n\n"; }
}
# end of chk_size subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub chk_inodes {
   if ($debug_extensive) { print "\n  debug process: chk_inodes sub *** start *** v\n"; }
   #
   # Check if inodes > configured threshold
   #

   $errmsg = "Inodes utilization for $desc is currently $inode_info%.  The threshold is $fs_inode% on server $HOSTNAME";
   if ($inode_info > $fs_inode) {
      $running_err = "Y";
      $errmsg      = "Inodes utilization for $desc is currently $inode_info% which is greater than the threshold of $fs_inode% on server $HOSTNAME.";
   }
   $type="inode";
   
   &capture_error;

   if ($debug_extensive) { print "\n  debug process: chk_inodes sub ***  end  *** ^\n"; }
}
#--------------------------------------------------------------------
# end of chk_inodes subroutine
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub get_badmount_information {
   
   if ($debug_extensive) { print "\n  debug process: get_badmount_information sub *** start *** v\n"; }

   print "\n*** Getting bad mount information ***\n";

   #
   #  Process the default configuration
   #
   $file      = $SSM_ETC . "filesys.dat";
   $init_file = $SSM_BIN . "filesys.dat";

   unless (open (defaultfile, "$file")) {

      if ( -e "$init_file" ) {
         print "Installing $file\n";
         `$CP $init_file $SSM_ETC`;
      }
      else {
         print "\nNo default configuration file exists\n";
         exit 0;
      }

   }

   @Badmount_rec = <defaultfile>;
   close(defaultfile);
   @badmount_rec = grep(/filesys=badmount/, @Badmount_rec);
   $badmount_rec = @badmount_rec[0];
   chomp($badmount_rec);

   @fargs = $badmount_rec;

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

   foreach $a (@PARMS) {
      #
      # Strip leading AND trailing spaces per field ...arrrg
      #
      $a =~ s/^\s*(.*?)\s*$/$1/;
      if ( $arg_cnt == 1 ) {
        
         print "\nProcessing $vposend_arg --> $a\n";
         #
         # Set the variables used for processing
         #
         # print "Processing arg $vposend_arg value = $a\n";
         if ( "$vposend_arg" eq "-F" ) { $badmount_fsname      = "$a";   }
         if ( "$vposend_arg" eq "-a" ) { $badmount_appl        = lc($a); }
         if ( "$vposend_arg" eq "-T" ) { $badmount_fs_size     = $a;     }
         if ( "$vposend_arg" eq "-G" ) { $badmount_fs_growth   = $a;     }
         if ( "$vposend_arg" eq "-I" ) { $badmount_fs_inode    = $a;     }
         if ( "$vposend_arg" eq "-H" ) { $badmount_start       = "$a";   }
         if ( "$vposend_arg" eq "-J" ) { $badmount_stop        = "$a";   }
         if ( "$vposend_arg" eq "-W" ) { $dayofweek            = lc($a); }
         if ( "$vposend_arg" eq "-D" ) { $badmount_desc        = lc($a); }
         if ( "$vposend_arg" eq "-A" ) { $badmount_cmd         = "$a";   }
         if ( "$vposend_arg" eq "-s" ) { $badmount_severity    = lc($a); }
         if ( "$vposend_arg" eq "-M" ) { $badmount_ITO_AGE     = $a;     }
         if ( "$vposend_arg" eq "-E" ) { $badmount_Error_Times = $a;     }
         if ( "$vposend_arg" eq "-S" ) { $badmount_Service     = $a;     }
         if ( "$vposend_arg" eq "-O" ) { $source_host          = $a;     }
         
         $arg_cnt     = 0;
         
      }
      else {
        
         $arg_cnt     = 1;
         $vposend_arg = $a;
         
      }
   }

   chomp ($source_host);

   # Source Host Check - if source_host_check returns 1 the source_host option matches
   if (source_host_check($source_host)) {
      if ($debug_extensive) { print "  match on source host: $source_host\n"; }
   }
   else {
      if ($debug_extensive) { print "  no match on source host: $source_host\n"; }
   }

   if ("$badmount_start" eq "") {
      $badmount_start     = "00";
   }
      
   if ("$badmount_stop" eq "") {
      $badmount_stop      = "24";
   }
   
   if ("$dayofweek" eq "" || "$dayofweek" eq "all" ) {
      $dayofweek          = "sun mon tue wed thu fri sat";
   }
   
   chomp($badmount_severity);

   if ( "$badmount_severity" eq "" ) {
      $badmount_severity   = "major";
   }

   if (    "$badmount_severity" ne "critical"
        && "$badmount_severity" ne "major"
        && "$badmount_severity" ne "minor"
        && "$badmount_severity" ne "warning" ) {
      $badmount_severity   = "major";
   }

   chomp($badmount_ITO_AGE);
   
   if ( "$badmount_ITO_AGE" eq "" ) {
      $badmount_ITO_AGE    = 60;
   }

   chomp($badmount_Error_Times);
   
   if ( "$badmount_Error_Times" eq "" ) {
      $badmount_Error_Times = 0;
   }
   
   chomp($badmount_Service);
   if ( "$badmount_Service" eq "" ) {
      $badmount_Service     = "os";
   }

   # debug variable output
   if ($debug_extensive) {
      print "  --- get_badmount_information variables ---\n";
      print "  badmount_start:       $badmount_start\n";
      print "  badmount_stop:        $badmount_stop\n";
      print "  badmount_severity:    $badmount_severity\n";
      print "  badmount_ITO_AGE:     $badmount_ITO_AGE\n";
      print "  badmount_Error_Times: $badmount_Error_Times\n";
      print "  badmount_Service:     $badmount_Service\n";
      print "  arg_cnt:              $arg_cnt\n";
      print "  vposend_arg:          $vposend_arg\n";
      print "  file:                 $file\n";
      print "  init_file:            $init_file\n";
      print "  \n";
   }
   
   if ($debug_extensive) { print "\n  debug process: get_badmount_information sub ***  end  *** ^\n\n"; }
   
}
# end of get_badmount_information
#--------------------------------------------------------------------
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#--------------------------------------------------------------------
sub chk_badmount {
  
   if ($debug_extensive) { print "\n  debug process: chk_badmount sub *** start *** v\n"; }

   $errmsg_text  =  "Mount point $desc is invalid. Found in $conf_file on server $HOSTNAME";
   $fsname       =~ tr/\/\\/../;
   
   print "The configured file system $fsname in $conf_file is invalid\n";
   
   # print "ignore file is $ignore_file...processing $chk_conf_file\n";
   $badmount_cmd =~ s/"//g;
   $ito_obj      =  "invalid-$fsname";
   $badfile      =  "badmount" . "$fsname" . "." . $appl;
   $chk_badmnt   =  $SSM_HOLD . $badfile;
   # print "Checking for $chk_badmnt\n";

   if ( -e "$chk_badmnt" ) {
      #
      # Stat the ITO Error Age file
      #

      $mtime        = (stat ("$chk_badmnt"))[9];

      #
      # Check how old the file is in minutes
      #

      $diff         = $now - $mtime;
      $ageInMinutes = int($diff / 60);

      #
      # print "3. Checking for $chk_badmnt age $ageInMinutes vs $badmount_ITO_AGE\n";
      if ( $ageInMinutes > $badmount_ITO_AGE ) {
        
         if ($badmount_cmd ne "") { $badmount_cmd = "action=$badmount_cmd"; }
         $message = "Message from file space monitoring via $conf_file $disp_date vposend_options: app=$appl sev=$severity $badmount_cmd message=$errmsg_text";
        
         process_vposend_lf($message, $test, $prefix);

         `echo warning > $SSM_HOLD$badfile`;
         
      }
      else {
         
         print "The invalid mountpoint message for $fsname was reported $ageInMinutes minutes ago. ITO_AGE = $badmount_ITO_AGE.\n";
         
      }
      
   }
   else {
      
      if ($badmount_cmd ne "") { $badmount_cmd = "action=$badmount_cmd"; }
      $message = "Message from file space monitoring via $conf_file $disp_date vposend_options: app=$appl sev=$severity $badmount_cmd message=$errmsg_text";
      
      process_vposend_lf($message, $test, $prefix);

      `echo warning > $SSM_HOLD$badfile`;
   }

      # debug variable output
   if ($debug_extensive) {
      print "\n  --- chk_badmount variables ---\n";
      print "  errmsg_text:   $errmsg_text\n";
      print "  fsname:        $fsname\n";
      print "  badmount_cmd:  $badmount_cmd\n";
      print "  ito_obj:       $ito_obj\n";
      print "  badfile:       $badfile\n";
      print "  chk_badmnt:    $chk_badmnt\n";
      print "  mtime:         $mtime\n";
      print "  diff:          $diff\n";
      print "  ageInMinutes:  $ageInMinutes\n";
      print "  init_file:     $init_file\n";
      print "  \n";
   }

   if ($debug_extensive) { print "\n  debug process: chk_badmount sub ***  end  *** ^\n\n"; }
}
# end of chk_badmount
#--------------------------------------------------------------------
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ===================================================================
# End of SUBROUTINES
# ===================================================================

# ===================================================================
# Start of FUNCTIONS
# ===================================================================

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
USAGE

filesys.monitor [--debug] [--debugextensive] [--help] [--version]

";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


__END__
=head2 DEVELOPER'S COMMENTS

=cut
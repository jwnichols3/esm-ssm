###################################################################
#
#             File: svcenter_chk.pl
#         Revision: 1.0
#
#           Author: Bill Dooley
#          Company: Barclays Global Investors
#
#    Original Date: 06/03
#
#      Description: This program will validate that the SC Hotback
#                   operatates in the right sequence.
#                   
#                   
#           Usage:  svcenter_chk  
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  06/03      wpd           <Initial Version>
#  11/07      jwn           changed pointer to config file to e:\ssm\svcenter.dat
#
#
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
$vposend = $PWC_BIN . "vposend";

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

%opts = (
   "L" => { cl => "-F", lf => "dir=" },
   "a" => { cl => "-a", lf => "app=", },
   "T" => { cl => "-T", lf => "minutes=" },
   "H" => { cl => "-H", lf => "start=" },
   "J" => { cl => "-J", lf => "stop=" },
   "D" => { cl => "-D", lf => "description=" },
   "A" => { cl => "-A", lf => "action=" },
   "s" => { cl => "-s", lf => "sev=" },
   "z" => { cl => "-z", lf => "severity=" },
   "M" => { cl => "-M", lf => "message_age=", },
   "E" => { cl => "-E", lf => "error_times=" },
   "S" => { cl => "-S", lf => "service=", },
);

#
# Set up local variables
#

$age = 60;

#
# Get the time
#

$time = time;

#
# Set Time Variables
#
# print "set time variables\n";

$now = time;
($sec,$min,$hour,$mday) = localtime(time);
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

$svc_cfg = "e:\\ssm\\svcenter.dat";

open (svcenter_cfg, "$svc_cfg");
@svcenter_cfg = <svcenter_cfg>;
close (svcenter_cfg);

foreach $line (@svcenter_cfg) {
   chomp($line);
   #
   # Check for blank line
   #
   $line =~ s/^\s+//;
   $blank = (substr($line, 0, 1));
   if ("$blank" eq "") {next;};

   $comment   = (substr($line, 0, 1));
   if (($comment ne "#") && ($comment ne " ")) {

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
      $dir = $file = $appl = $minutes = $action = $severity = $ITO_AGE = $Service = "";
      foreach $a (@PARMS) {
         #
         # Strip leading AND trailing spaces per field ...arrrg
         #
         $a =~ s/^\s*(.*?)\s*$/$1/;
         $desc = "";
         if ( $arg_cnt == 1 ) {
            #
            # Set the variables used for processing
            #
            # print "Processing arg $vposend_arg value = $a\n";
            if ( "$vposend_arg" eq "-F" ) { $dir = "$a"; }
            if ( "$vposend_arg" eq "-a" ) { $appl = lc($a); }
            if ( "$vposend_arg" eq "-T" ) { $minutes = $a; }
            if ( "$vposend_arg" eq "-H" ) { $start = "$a"; }
            if ( "$vposend_arg" eq "-J" ) { $stop = "$a"; }
            if ( "$vposend_arg" eq "-D" ) { $desc = $a; }
            if ( "$vposend_arg" eq "-A" ) { $cmd = "$a"; }
            if ( "$vposend_arg" eq "-s" ) { $severity = lc($a); }
            if ( "$vposend_arg" eq "-z" ) { $severity = lc($a); }
            if ( "$vposend_arg" eq "-M" ) { $ITO_AGE = $a; }
            if ( "$vposend_arg" eq "-E" ) { $Error_Times = $a; }
            if ( "$vposend_arg" eq "-S" ) { $Service = $a; }
            $arg_cnt = 0;
         } else {
            $arg_cnt = 1;
            $vposend_arg = $a;
         }
      }
   }
}
if ("$appl" eq "") {
   $appl = "test_service_center";
}
if ("$minutes" eq "") {
   $minutes = "5";
}
if ("$start" eq "") {
   $start = "00";
}
if ("$stop" eq "") {
   $stop = "24";
}
if ($desc eq "") {
   $desc = "ServiceCenter Hot Backup" ;
}
chomp($severity);
if ( "$severity" eq "" ) {
   $severity = "major";
}
if ( "$severity" ne "critical" && "$severity" ne "major" && "$severity" ne "minor" && "$severity" ne "warning") {
   $severity = "critical";
}
chomp($ITO_AGE);
if ( "$ITO_AGE" eq "" ) {
   $ITO_AGE = 60;
}
chomp($Error_Times);
if ( "$Error_Times" eq "" ) {
   $Error_Times = 0;
}
chomp($Service);
if ( "$Service" eq "" ) {
   $Service = "os";
}

&watch_log;

exit 0;

sub watch_log {
   $checking = 0;
   $svc_log = "c:\\usr\\ov\\log\\svcenter.log";
   while ($checking < $minutes) {
      open (svc_log, "$svc_log");
      @svc_rec = <svc_log>;
      close(svc_log);

      foreach $svc_rec(@svc_rec) {
         chomp($svc_rec);
         ($id, $msg) = split(/ ~ /, $svc_rec);
         $id =~ s/^\s*(.*?)\s*$/$1/;
         print "Processing id $id   message $msg\n";
         if ( "$id" eq "ERROR" ) {
            $checking = $minutes;
            `$vposend -a $appl -s $severity -m "Error occured during Service Center Hot Backup $msg"`;
            exit 1;
         } elsif ( "$id" eq "BCKI0016" ) {
            $bck16_17_18 = "Y";
            next;
         } elsif ( "$id" eq "BCKI0017" ) {
            if ( "$bck16_17_18" eq "Y" ) {
               $bck16_17_18 = "YY";
               next;
            } else {
               $msg = "BCKI0016,17,18 out of sequence";
               print "$msg\n";
               `$vposend -a $appl -s $severity -m "Error occured during Service Center Hot Backup - $msg"`;
               exit 1;
            }
         } elsif ( "$id" eq "BCKI0018" ) {
            if ( "$bck16_17_18" eq "YY" ) {
               $bck16_17_18 = "YYY";
               next;
            } else {
               $msg = "BCKI0016,17,18 out of sequence";
               print "$msg\n";
               `$vposend -a $appl -s $severity -m "Error occured during Service Center Hot Backup - $msg"`;
               exit 1;
            }
         } elsif ( "$id" eq "24X7Start" ) {
            $start_log = "Y";
            next;
         } elsif ( "$id" eq "24X7Stop" ) {
            $end_log = "Y";
            next;
         } elsif ( "$id" eq "LOGGING" ) {
            if ( "$bck16_17_18" ne "YYY" ) {
               $msg = "BCKI0016,17,18 out of sequence";
               print "$msg\n";
               `$vposend -a $appl -s $severity -m "Error occured during Service Center Hot Backup - $msg"`;
               exit 1;
            }
            if ( "$start_log" ne "Y" || $end_log ne "Y" ) {
               $msg = "Missing Start, End or LOGGING message";
               print "$msg\n";
               `$vposend -a $appl -s $severity -m "Error occured during Service Center Hot Backup - $msg"`;
               exit 1;
            } else {
               exit 0;
            }
         }
         print "s_e_l = $start_end_log\n";
      }

      sleep 56;
      $checking++;
   }

   $msg = "Process is taking too long";
   print "$msg\n";
   `$vposend -a $appl -s $severity -m "Error occured during Service Center Hot Backup - $msg"`;
   exit 1;
}

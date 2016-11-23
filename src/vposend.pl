#!/tools/perl/bin/perl
use Getopt::Std;
###############################################################
## vposend:
##   created:  07/16/02 Rick Langsford, Pepperweed Consulting
##   changes:
##
##    2004-05 nichj - added comfort message option,
##            changed debug settings and determination
##            changed $PWC variables to $SSM
##
##   purpose: Wrapper for VPO opcmsg command
##
##   version: 1.8
###############################################################

#getopts('v');
if ( "$ARGV[0]" eq "-v" ) {
   $version = "$0 version 1.8\n";
   #if ( $opt_v ) { die $version }
   print "\n\n$version\n\n";
   exit 0;
}

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

## DEBUG variables
## When the file vposend.debug is present, then send detailed output to <STDOUT>
## The -D option also turns debug on.
$DEBUG_ON = "$SSM_CONF/vposend.debug";    # if this file is there then debug is on

if ( -e $DEBUG_ON ) {  
    $debug=1;
    print "Debug on\n";
  } else {
    $debug=0;
}
## end of debug determiniation

if ($debug) { print "ARGV = $ARGV[0] - $ARGV[1]\n"; }
#exit 0;

## Force lowercase on msg_grp, type and object
$forcelc       = 1;
## Fix case to be sensitive for Getopt::Std
$ignorecase    = 0;
## Defaults for req'd opcmsg options
$opcMsg_object = "SSM-no-obj-def";
$opcMsg_appl   = "SSM-no-app-def";
$keyDelim      = "++k++";

# 
# Rearrange args to combine actions so that getopts will work properly.
#

if ($debug) { print "\n1. args = @ARGV \n"; }

$first     = 0;
$act_found = 0;

if ( "$ARGV[0]" eq "-f" || "$ARGV[1]" eq "-f" ) {  # if the first agrument is -f then it is coming from
                                                   # a logfile
   if ($debug) { print "from a log file\n"; }

   @args = @ARGV;

} else {                                           # else it is being run from the command line

   if ($debug) { print "from the command line\n"; }
   
   $action = "";

   foreach $arg(@ARGV) {                           # loop through all arguments

      if ($debug) { print "$act_found. $arg\n"; }

      if ( "$arg" eq "-A" || $act_found == 1 ) {   # the the arg = "-A" then its an action

         if ( $act_found == 0 ) {                  # if its the first action then set act_found = 1.
            $act_found = 1;
            next;
        }

         if ($debug) { print "$arg\n"; }
         
         $arg_help = lc("$arg");                   

         if ( "$arg_help" eq "help" ) {            # if the parm is -A help the print the vposend action help file.
            print "Processing Action Help\n";
            $action_help = $SSM_CONF . "vposend_action_help";
            open (action_help, "$action_help");
            @ACTION = <action_help>;
            close (action_help);

            print STDERR "\n @ACTION \n";

            exit (1);
         }

         $act_found = 0;
         if ( $first == 0 ) {
            $action = $arg;
            $first = 1;

         } else {
            $action = $action . "._" . $arg;
         }
      } else {

         $chk = substr($arg,0,1);
         push (@args, "$arg");

      }

   }
   if ( "$action" ne "" ) {
      push (@args, "-A");
      push (@args, "$action");
   }
}

if ($debug) {print "\n\nargs = @args \n";}

@ARGV = @args;

## This is the only static piece of code that should be changed
## as needed.
##
## Flags to opcmsg flag correlation (no way to do dynamically)

## The Args we expect to See:
$vposendArgs = "a:s:m:g:k:A:i:d:t:n:fD";
## Global Hash for all subs:
  %reqopts = (
      "a" => { cl => "-a", lf => "app=", opcflag     => " msg_grp=",  },
      "s" => { cl => "-s", lf => "sev=",opcflag      => " sev=",      },
      "m" => { cl => "-m", lf => "message=",opcflag  => " msg_text=", },
      );
  %opts = (
      "a" => { cl => "-a", lf => "app=", opcflag     => " msg_grp=",                             },
      "s" => { cl => "-s", lf => "sev=",opcflag      => " sev=",                                 },
      "m" => { cl => "-m", lf => "message=",opcflag  => " msg_text=",                            },
      "k" => { cl => "-k", lf => "key=",opcflag      => "",                                      },
      "n" => { cl => "-n", lf => "node=",opcflag     => " node=",                                },
      "A" => { cl => "-A", lf => "action=",opcflag   => " -opt action=", opcflagalt => " appl=", },
      "i" => { cl => "-i", lf => "instance=",opcflag => " -opt instance=",                       },
      "t" => { cl => "-t", lf => "type=",opcflag     => " -opt type=", opcflagalt => " obj=",    },
      "D" => { cl => "-D", lf => "debug=",opcflag    => "",                                      },
      );

##
## Figure out how we are being called (for log parsing or generic CLI)
##

if ($args[0] =~ /^\-D/) {  
   ## Put in Debug
   $debug = 1;
}
if ($args[0] =~ /^\-f/) {  
   ## it's a log record
   $fidx = 1;
   if ($debug) {print "Processing log file\n";}
   logParse(@args);
}
if ($args[1] =~ /^\-f/) {  
   ## it's a log record and Debug on
   $fidx = 2;
   if ($debug) { print "Processing log file\n"; }
   logParse(@args);
}
#print "4. opcflag = $opcflag\n";
if ($args[0] =~ /^\-h/) {  
   ## they just need help
   &useage;
}
else                   {  
   ## it's is a generic CLI 
   if ($debug) { print "Processing command line\n"; }
   cliParse(@args);
}
#print "5. opcflag = $opcflag\n";

#################################
sub cliParse {
#################################
   my @args       = @_;
   ## build options...
   useage unless (getopts($vposendArgs, \%option));
   $opcMsg_object = $opcMsg_object."-CLI";  # just to let us know how vposend was invoked
   $opcMsg_where  = "CLI-";
   buildRun(%option, %opts, %reqopts);
}  ## END cliParse

#################################
sub logParse {
#################################
  @fargs = @args;
  
  if ($debug) { printf "\nOrig file rec: $fargs[$fidx] \n"; }
                                
  foreach $o ( keys %opts ) {
     $fargs[$fidx] =~ s/$opts{$o}{lf}/\t$opts{$o}{cl}\t/i;
  }
                                if ($debug) { printf "\nNew file rec: $fargs[$fidx] \n"; }
  ## Strip leading spaces
  $fargs[$fidx] =~ s/^\s*//;
  ## Fake the Args
  @ARGV = split /\t/,$fargs[$fidx];
  ## Strip leading AND trailing spaces per field ...arrrg
  foreach $a (@ARGV) { $a =~ s/^\s*(.*?)\s*$/$1/; }
  ## build options...
    useage unless (getopts($vposendArgs, \%option));
  $opcMsg_object = $opcMsg_object."-Logfile";  # just to let us know how vposend was invoked
  $opcMsg_where = "Logfile-";
  buildRun(%option, %opts, %reqopts);
}  ## END logParse
 
#################################
sub buildRun {
#################################
 
    $comb_action = "";
    $comb_detail = "";
    $comb_cnt    = 0;
    $opcMsg      = $OpC_BIN . "opcmsg";
    
    if ($debug) { print "OS is $^O and opcMsg is $opcMsg \n"; }

    #
    # Set emailfyi flag.  If Actions are configured then this flag will be reset.
    # This is set to 1 here to prevent thinking it is only an emailfyi if no actions
    #   are configured.
    #
    $fyi_cnt     = 1;

    #
    # Initialize Command 
    #
    $cmdStr      = $opcMsg;
    
    #
    # check for required flags 
    #
    foreach $o ( keys %reqopts ) {
       if ($debug) { printf " flag -$o is: $option{$o} \t opcflag is: $opts{$o}{opcflag}\n";  }
       
       if ( ! $option{$o}) { &useage; }
    }

    #
    # Build the command string
    #
    foreach $o ( keys %opts ) {
       ## do any of the flags have a dash in them  
       if ($debug) { printf " flag -$o is: $option{$o} \t opcflag is: $opts{$o}{opcflag}\n";  }

       if ( ($option{$o}) =~ /^\-/)  { &useage; }

       if ( ! ($option{$o}))  {
          $opts{$o}{opcflag} = ""; 
       } else {

          ## Special case for Suppression Key
          if ( ($o =~ /^m/) && ($option{k}) ) { $option{$o} .= $keyDelim.$option{k}; $option{k} = ""; }

          if ( ($o =~ /^a|^t|^A/ ) && ($forcelc) ) { $option{$o} = "\L$option{$o}"; }

          if ( "$o" ne "D" && "$o" ne "k" ) {
             if ( "$o" eq "m" ) {
                $option{$o} = $opcMsg_where . $option{$o};
             }
             
             if ( "$o" eq "A" ) {                                # processing the pre-canned actions
                @NEW_ACTION = split(/ action=/, $option{$o});

                if ($debug) {print "Original option = $option{$o}\n";}

                $act_found =+ @NEW_ACTION;

                if ( $act_found > 0 ) {
                   $first = 0;

                   foreach $new_action(@NEW_ACTION) {
                      # print "Processing new_action $new_action\n";
                      if ( $first == 0 ) {
                         $New_ACTION = $new_action;
                         $first = 1;
                      } else {
                         $New_ACTION = $New_ACTION . "._" . $new_action;
                      }
                   }
                   
                   @ACTIONS = split(/\.\_/,$New_ACTION);
                } else {
                  
                   @ACTIONS = split(/\.\_/,$option{$o});
                   
                }
                
                # the fyi_cnt variable is for those actions that don't open tickets
                $fyi_cnt = 0;

                foreach $ACTION(@ACTIONS) {
                   ($new_action,$new_detail,$new_subject) = split(/,/,$ACTION);

                   if ( ("$new_action" eq "email") || ("$new_action" eq "emailfyi") || ("$new_action" eq "comfort") ) {
                      @new_detail = split(/\;/,$new_detail);
                      $z = "0";
                      foreach $action_rec(@new_detail) {
                         if ( "$z" eq "0" ) {
                            $new_detail = $action_rec;
                            $z = 1;
                         } else {
                            $new_detail = $new_detail . "," . $action_rec;
                         }
                      }
                      if ( "$new_subject" ne "" ) {
                         $new_detail = $new_detail . ";" . $new_subject;
                      } else {
                         $new_detail = $new_detail . ";Important Notification from OpenView";
                      }

                   } # end of foreach
                   
                   #
                   # Check for action other than emailfyi or comfort
                   #
                   if ( ("$new_action" ne "emailfyi") && ("$new_action" ne "comfort") ) {
                      
                      $fyi_cnt++;
                      
                      if ($debug) { print "action not emailfyi or comfort\n"; }
                   }

                   if ($debug) {
                     print "fyi_cnt: $fyi_cnt\n";
                     print "new action: $new_action\n";
                   }

                   if ($comb_cnt == 1) {
                      $comb_action = $comb_action . "._" . $new_action;
                      $comb_detail = $comb_detail . "._" . $new_detail;
                   } else {
                      $comb_action = $new_action;
                      $comb_detail = $new_detail;
                      $comb_cnt = 1;
                   }
                }
                $option{$o} = $comb_action . "\" -opt detail=\"" . $comb_detail;
             }
             if ($debug) {print "Checking $option{$o}\n";}
             if ( "$o" ne "m" ) {
                $cmdStr .= $opts{$o}{opcflag}."\"".$option{$o}."\"";
             }
          }
          
          if ( "$o" eq "A" ) {
             $option{$o} = "Canned";
          }

          if ($opts{$o}{opcflagalt}) {  $cmdStr .= $opts{$o}{opcflagalt}."\"".$option{$o}."\""; }
       }
    }

    ## Force the req'd VPO options if not already provided
    if ( ! ($option{A}))  { $opts{A}{opcflag} = " a="; $option{A} = $opcMsg_appl; $cmdStr .= $opts{A}{opcflag}.$option{A}; } 
    if ( ! ($option{t}))  { $opts{t}{opcflag} = " o="; $option{t} = $opcMsg_object; $cmdStr .= $opts{t}{opcflag}.$option{t}; }

    #
    # If the only action is emailfyi or comfort then flag so ticket isn't generated
    #
    if ($debug) {print "Checking fyi count $fyi_cnt\n";}
    
    $o = "m";
    if ( $fyi_cnt == 0 ) {
       $option{$o} = $option{$o} . " - FYIONLY";
    }

    $cmdStr .= $opts{$o}{opcflag}."\"".$option{$o}."\"";

    #
    # Send event to OVO using opcmsg 
    #
    if ($debug) { print "command line is: $cmdStr \n"; }
    
    if (! (exec $cmdStr)) {
        print STDERR "opcmsg ERROR!! Could not run opcmsg: \n"; 
    } else { 
        exit (0); 
    }

}  ## END buildRun


#################################
sub useage {
#################################
  my @args     = @_;
  $useage_help = $SSM_CONF . "vposend_help";
  open (useage, "$useage_help");
  @USAGE       = <useage>;
  close (useage);

  print STDERR "\n @USAGE \n";

  exit (1);
  
}  ## END useage

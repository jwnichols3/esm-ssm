#!/opt/gentools/perl5.6/bin/perl 

## $Id: mq-original.pl,v 1.1 2005/08/30 17:18:39 nichj Exp $

use MQClient::MQSeries;
use Date::Manip;
use Getopt::Long;
use Sys::Syslog;

require "/apps/misc/home/mqm/local/lib/mq-bgi-constants.pl";

## declares

my($todo);
my(@todo);
my($error_file);
my($count);
my($error_msg_txt);
my($alert_flg);
my($alert_sent_cnt);
my($prior_error_flg);
my($diff);
my($msg_length);
my($max_msg_length);
my($total_queues_with_errors);
my(@stat);
my(@errors);
my(%opt);

my($handle);
my($options_bitmask);
my($object_desc_ref);
my($comp);
my($reason);
my($data);

my($qmgr);
my(%qmgrconn);

local(*F);

##

&GetOptions(\%opt,
	    "config=s",
	    "errordir=s",
	    "blankfile",
	    "help",
	    "version",
	    "debug"
	    );

if ( $opt{blankfile} ) {
    generate_blank_config_file();
    exit;
}

if ( $opt{help} ) {
    &show_help();
    exit;
}

if ( $opt{version} ) {
    &show_version();
    exit;
}

if ( $opt{config} eq "" || $opt{errordir} eq "" ) {
    print "Both --config and --errordir are required arguments.  For help,\n";
    print "try $0 --help.\n";
    exit(1);
}

@results=`ps -ef | grep mq_monitor_message_age.pl | grep -v grep`;
if ( scalar(@results) > 1 ) {
    # This program is already running - so exit.
    foreach $line ( @results ) {
	log_message("mqadmin","debug","PS output : $line");
    }
    log_message("mqadmin","debug","PS count = ".scalar(@results));
    log_message("mqadmin","debug","Program instance already running - exiting.");
    log_message("mqadmin","debug","Program exiting.");
    exit(1);
}

## main()

log_message("mqadmin","debug","Starting run");

@todo=&read_config_file($opt{config});

$total_queues_with_errors=0;
$alert_sent_cnt=0;

foreach $todo ( @todo ) {
    
    %todo=%$todo;
    
    $qmgr=$todo{QMgr};

    log_message("mqadmin","debug","Checking $qmgr $todo{Q}");
    
    $error_file="$opt{errordir}/$qmgr:$todo{Q}:$todo{Who}";

    $alert_flg=1;
    $prior_error_flg=0;

    ## First we check if an error file exists for this queue.
    ## If it does, we check the mtime of the file and compare this to the current time.
    ## If the difference is less than the realert threshold (in minutes) we turn off
    ## alert notification for the remainder of the check.  Otherwise we turn it on.

    if ( -f $error_file ) {
	log_message("mqadmin","debug","Error file exists for queue $todo{Q}");
	$prior_error_flg=1;
	@stat=stat($error_file);
	$diff=int((time() - $stat[9]) / 60);  # Get this in minutes
	if ( $diff >=  $todo{Realert} ) {
	    log_message("mqadmin","debug",
			"Passed re-alert threshold ($diff vs $todo{Realert}) for queue $todo{Q} - checking again");
	    $alert_flg=1;
	} else {
	    log_message("mqadmin","debug",
			"Realert threshold not passed ($diff vs $todo{Realert}) for queue $todo{Q} - skipping check");
	    $alert_flg=0;
	}
    }
	
    ## See if we have a valid connection to the qmgr for this queue.  If not, acquire it.
    if ( ! defined $qmgrconn{$qmgr} ) {
	log_message("mqadmin","debug",
		    "No valid handle to qmgr $qmgr - attempting to connect");
	$qmgrconn{$qmgr}=&get_qmgr_conn($qmgr);
    }

    ## If the above attempt failed, skip this check.  Something must be wrong with the 
    ## queue manager.  This script's job is NOT to notify on those kinds of problems.
    if ( ! defined $qmgrconn{$qmgr} ) {
	log_message("mqadmin","debug",
		    "Could not establish connection to qmgr $qmgr - skipping this check.");
	next;
    } else {
	log_message("mqadmin","debug",
		    "Connection to qmgr $qmgr exists");
    }
	

    ## Prepare to open the queue in question.
    $options_bitmask = MQOO_INQUIRE | MQOO_INPUT_AS_Q_DEF | MQOO_OUTPUT | MQOO_SET | MQOO_BROWSE;
    $obj_desc_ref    = {
	ObjectType     => MQOT_Q,
	ObjectName     => $todo{Q},
	ObjectQMgrName => ""
	};

    ## Open the queue
    $handle=MQOPEN($qmgrconn{$qmgr},$obj_desc_ref,$options_bitmask,$comp,$reason);
    if ( $comp != MQCC_OK ) {
	&log_mq_error($reason,"minor");
	next;
    }


    $count=0;
    @errors=();

    $mqgmo_ref = {
	Options => MQGMO_FAIL_IF_QUIESCING | MQGMO_BROWSE_NEXT | MQGMO_ACCEPT_TRUNCATED_MSG
	};
    
    $msg_desc_ref={
	Version => MQMD_VERSION_2
	};
    
    ## We don't care about the message body, so set buffer length to 1
    $msg_length=1;
    $data=MQGET($qmgrconn{$qmgr},$handle,$msg_desc_ref,$mqgmo_ref,$msg_length,$comp,$reason);
    if ( $comp != MQCC_OK ) {
	if ( $reason == 2033 ) {
	    # No more messages on the queue - end checking this queue gracefully.
	    $data="no message";
	} elsif ( $reason == 2079 ) {
	    # Message truncated - who cares?  Continue as if nothing happened
	    # We only need the MQMD for the message anyway.
	    $data="message";
	} else {
	    &log_mq_error($reason,"minor");
	    $data="no message";
	}
    }
    
    if ( $data eq "message" ) {
	($id,$user,$app,$age)=get_scan_info($msg_desc_ref);

	if ( $age >= $todo{Alert} ) {
	    $count++;
	    push(@errors,"$id\t$user\t$app\t$age\t$msg_desc_ref->{BackoutCount}");
	}
    }
	
    if ( $count > 0 ) {

	$total_queues_with_errors++;
	$error_msg_txt="";

	if ( $prior_error_flg ) {
	    $error_msg_txt.="Re alert - ";
	}

	if ( $alert_flg ) {

	    $error_msg_txt.="queue $todo{Q} on queue manager $qmgr has one or more messages older than $todo{Alert} minutes";
	    log_message($todo{Who},$todo{Severity},$error_msg_txt);

	    $alert_sent_cnt++;

	    if ( ! open(F,">$error_file") ) {
		log_message("mqadmin","minor",
			    "Could not open error file for message aging scan program - $error_file: $!");
		next;
	    }
	    print F "# QMgr $qmgr Queue $todo{Q} @ ".localtime()."\n";
	    print F "# Message ID <tab> Put User Name <tab> Put App Name <tab> Message Age in Minutes <tab> Backout Count\n";
	    foreach $line ( @errors ) {
		print F "$line\n";
	    }
	    print F "# End of file\n";
	    close(F);
	    
	}
    } else {
	
	if ( -f $error_file ) {
	    log_message("mqadmin","debug","Error condition cleared up for queue $todo{Q}");
	    unlink $error_file;
	}
    }
    
    MQCLOSE($qmgrconn{$qmgr},$handle,MQCO_NONE,$comp,$reason);
    if ( $comp != MQCC_OK ) {
	&log_mq_error($reason,"debug");
    }
    
}

foreach my $conn ( keys %qmgrconn ) {
    MQDISC($qmgrconn{$conn},$comp,$reason);
    if ( $comp != MQCC_OK ) {
	# No point error checking here really.
    }
}

# This is here to prevent "last message repeated x times" consolidation by the syslog daemon
# which would prevent VPO from picking up the new alert message.

if ( $alert_sent_cnt ) {
    if ( $total_queues_with_errors > 0 ) {
	$error_msg_txt="There were $total_queues_with_errors queue(s) with errors this check @ ".localtime();
	log_message("mqadmin","debug",$error_msg_txt);
    }
} else {
    log_message("mqadmin","debug","No alerts sent this check");
}
 
log_message("mqadmin","debug","Completing run");
    
exit;

## 

sub get_qmgr_conn {
    my($qmgr)=@_;
    my($conn,$channel,$machine,$result_code,$reason_code,$reason_text,$reason_macro);

    ($channel,$machine)=&get_qmgr_info($qmgr);

    $conn = MQCONNX($qmgr, 
		    { 
			'ClientConn' => {
			    'Version'        => MQCD_CURRENT_VERSION,
			    'ChannelName'    => $channel,
			    'TransportType'  => 'TCP',
			    'ConnectionName' => $machine,
			    'MaxMsgLength'   => 104857600,
			},
			'StrucId' => MQCNO_STRUC_ID,
			'Version' => MQCNO_CURRENT_VERSION,
			'Options' => MQCNO_STANDARD_BINDING,
		    },
		    $result_code, 
		    $reason_code);
    
    if ( $result_code != MQCC_OK ) {
	($reason_text,$reason_macro)=MQReasonToStrings($reason_code);
	log_message("mqadmin","minor","Failed to establish connection to qmgr $qmgr \@ $channel/TCP/$machine : $reason_code ($reason_text)");
    }
    
    return($conn);
}


sub log_message {
    my($who,$priority,$message,$key)=@_;
    my($string);

    if ( $priority eq "debug" ) {
	if ( ! $opt{debug} ) {
	    return;
	}
    }

    $string="__VPO__ app=$who sev=$priority";
    if ( $key ne "" ) {
	$string.=" key=$key";
    }
    $string.=" message=$message";

    openlog("mq_monitor_message_age",LOG_PID,LOG_USER);
    syslog(LOG_ERR,$string);
    closelog();

}

sub log_mq_error {
    my($reason_code,$severity)=@_;
    my($text,$macro);

    ($text,$macro)=MQReasonToStrings($reason_code);
    log_message("mqadmin","$severity","MQ-Series error during message aging scan - ErrNo=$reason_code Text=$text");

}

sub get_scan_info {
    my($msg_desc_ref)=@_;
    my($year,$month,$day);
    my($hour,$min,$sec);
    my($msg_date,$now_date,$delta,$err);
    my(@delta);
    my($id,$user,$app,$age);

    if ( $msg_desc_ref->{PutDate}=~/^(\d\d\d\d)(\d\d)(\d\d)$/ ) {
	$year=$1; $month=$2; $day=$3;
    } else {
	# err
    }
    if ( $msg_desc_ref->{PutTime}=~/^(\d\d)(\d\d)(\d\d)(\d\d)$/ ) {
	$hour=$1; $min=$2; $sec=$3;
    } else {
	# err
    }

    $id   = unpack("H*",$msg_desc_ref->{MsgId});
    $user = $msg_desc_ref->{UserIdentifier};
    $app  = $msg_desc_ref->{PutApplName};

    $user =~s/\s+$//g;   # Remove trailing blanks
    $app  =~s/\s+$//g;   # Remove trailing blanks

    # Messages on Queue Managers have a put time in GMT, hence
    # the need to get the current time in GMT for a comparison
    $now_date=get_now_date();

    $msg_date=ParseDate("$month/$day/$year $hour:$min:$sec");

    $delta=DateCalc($msg_date,$now_date,\$err,0);
    @delta=split(/\:/,$delta);

    # Age in minutes
    $age=$delta[5] + $delta[4] * 60 + $delta[3] * 3600;

    return($id,$user,$app,$age);

}

sub get_now_date {
    my(@date);

    @date=gmtime();

    $date[5]=$date[5]+1900;   # years since 1900, so add 1900 to get year
    $date[4]++;               # Month is zero-based

    # if these aren't zero padded, ParseDate() screws up
    if ( $date[1] < 10 ) {
	$date[1]="0$date[1]";
    }
    if ( $date[0] < 10 ) {
	$date[0]="0$date[0]";
    }

    return(ParseDate("$date[4]/$date[3]/$date[5] $date[2]:$date[1]:$date[0]"));
    
}

sub read_config_file {
    my($cfgfile)=@_;
    my($line,$element,$key,$value,$hash_ref,@elements,@results);
    local(*F);
    
    @results=();

    if ( ! open(F,$cfgfile) ) {
	log_message("mqadmin","major","Could not open config file - $cfgfile: $!","configfile");
	exit(1);
    }
    while ( chop($line=<F>) ) {
	$line=~s/\#.*$//g;
	$line=~s/\s+/ /g;
	if ( $line eq "" ) {
	    next;
	}
	@elements=split(/\s/,$line);
	$hash_ref={};
	foreach $element ( @elements ) {
	    ($key,$value)=split(/\=/,$element);
	    $hash_ref->{$key}=$value;
	}
	push(@results,$hash_ref);
    }
    close(F);

    return(@results);
}

sub generate_blank_config_file {

print <<EOF
##
## Skeleton configuration file 
##
## Whitespace lines and comment characters ('#') are ignored in 
## this file.
##
## There is one line in the file per queue to monitor, with the
## format of the file being:
##
## QMgr=X  Q=Q.X  Alert=N  Realert=M Who=group Severity=code
##
## Each of the above elements are separated by any amount of whitespace
## (except newline). The key names are case sensitive (e.g. you
## must specify 'QMgr' not 'qmgr').  The key=value pairs may occur in
## any order on the line.  The queue manager and queue names should
## exist (obviously).  The alert value N is how old a message can be
## in minutes before there is an error condition.  The realert value
## M is how long an error condition can persist before sending another
## alert.  The 'group' is who the alert should go to.  This CANNOT 
## be an arbitrary group name.  The group must exist within VPO.
## Alerts are written to the syslog on the machine, with the facility 
## name being the group name given here, and VPO scans this log file.
## Alerts found will be routed to the group at the specified severity
## level.  Severity levels include normal, minor, major, critical.
## Please keep in mind critical is considered a very severe, global IT
## kind of event.  Do not use it unless you really know what you're
## getting into.
##
## Finally, please note all items, both keys and values, are case
## SENSITIVE!
##
QMgr=QM.UK.P.01  Q=Q.TEST   Alert=5    Realert=60  Who=mqadmin Severity=minor
##
EOF

}

sub get_qmgr_info {
    my($qmgr)=@_;

    my($channel,$proto,$machine)=split(/\//,$QMGR{$qmgr});
    
    return($channel,$machine);
}

sub show_help {

    show_version();

    print <<EOF

Usage: $0 [arguments]

This program checks for messages on queues older than a specified
threshold.  If found, the program sends an alert to the syslog,
naming the group that should be notified.  VPO (the BGI enterprise
monitoring software) must be configured to detect and page the
appropriate group.  Which queues should be monitored, how old
a message can be before it is an error, and who to notify are all
specified in a config file used by this program.

Arguments:

--config <config file>
--errordir  <dir name>
--blankfile 
--help
--version

For normal operations, specify --config and --errordir.  The --config
option names the configuration file to use for the given run of
the program.  The --errordir is a directory for exclusive use by this
program for storing information needed between runs to detect when an
error condition has persisted past the realert threshold.

For information on the format of a config file and to generate a
skeleton config file to stdout, run the script with just the --blankfile
option.

The --help and --version options are self-explanatory.

The option --debug is useful only when modifying this program, and prints
considerably more information to the syslog.  It's not meant for normal
operation.

EOF

}

sub show_version {

    print '$Id: mq-original.pl,v 1.1 2005/08/30 17:18:39 nichj Exp $'."\n";

}


__END__


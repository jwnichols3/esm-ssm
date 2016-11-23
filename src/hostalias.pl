###################################################################
#
#             File: hostalias
#         Revision: 1.01
#
#           Author: Eric Mehlhaff
#
#    Original Date: unkown
#
#      Description: 
#        Test to see if argument supplied host alias matches any of the
#         ip addresses associated configured on interfaces on the system
#         the script is run on.
#                   
#           Usage:  hostalias <hostname> | <ip addr>
#
# Revision History:
#
#  Date     Initials        Description of Change
#  09-2004   unkown         <original version>
#
#  09-2004   nichj          updated to return TRUE or FALSE as the first word
#

# nice of BGI to actually have sys:Hostname installed...
use Sys::Hostname ;

$hostname = hostname();

#DEBUG#print " This machine is: \"$hostname\"\n";

sub needhelp ( ){
	print <<"EOD"
Usage:  $0  [-q]  hostname
    Tests if 'hostname' resolves to any of the interface addresses on this 
    host.  
    exit code 0 if true, exit code 1 if not, exit code 2 on error.
    -q 	Quiet option suppresses text output.
    -h 	Print this help message.

EOD
;
exit 2;
}

# option for a -q argument
$debug = 1;  # default is non-quiet
$dbg = 0;


# arg parsing code taken from Programming perl book...
while ( $_= $ARGV[0] , /^-/){
	shift;  # essentiall pulls an arg off of the argument list.
	last if /^--$/;  # terminate argument parsing...
	if ( /^-D(.*)/) { $dbg = $1 ; $dbg>0&& print "Debug set to $dbg\n";}
	if ( /^-v/){ $debug++;$dbg>0 && print "debug set to $debug\n";}
	if ( /^-q/){ $debug--;$dbg>0 && print "debug set to $debug\n";}
	if ( /^-h/){ needhelp(); }
}

if ( $#ARGV < 0 ){
	print "$0:  Required argument missing!  $ARGV[0]\n";
	needhelp ();
} 

$queryhost = $ARGV[0];

# we're going to use the scalar result of gethostbyname
# and assume we only get 1 ip back from the host argument...
$queryip = gethostbyname $queryhost;
($a,$b,$c,$d) = unpack ( 'C4', $queryip );
$queryip = "$a.$b.$c.$d";

#DEBUG#print " Am I this host: \"$queryhost\"($queryip)\n";


open (FD, "/sbin/ifconfig -a 2>&1 |") && (@tmp= <FD>) && close FD;

foreach $i ( @tmp) {
     # loop through each of the lines of stored output from
     #DEBUG#print $i;
     if ( $_= $i , /inet / ){
	@fields = split ( '\s', $i);
	$ifip = $fields[2];
	#DEBUG#print "ifip:  \"$ifip\"\n";

	last if ( $ifip eq $queryip );
     }
}

if ( $ifip eq $queryip ){
    $debug && print "TRUE, I am $queryhost($queryip)\n";
    exit 0
} else {
    $debug && print "FALSE, I am not $queryhost($queryip)\n";
    exit 1
}


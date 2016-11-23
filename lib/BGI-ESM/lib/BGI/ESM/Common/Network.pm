
=head1 NAME

BGI ESM Common Shared Network Methods

=head1 SYNOPSIS

This library is used in BGI ESM programs when Network functionality is needed.

=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.4 $

  #####################################################################
  #
  # Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-09-07   nichj   Converted to new module 
  #  
  #####################################################################

=cut

#################################################################################
### Package Name ################################################################
package BGI::ESM::Common::Network;
#################################################################################

#################################################################################
### Module Use Section ##########################################################
use 5.008000;
use strict;
use warnings;
use Sys::Hostname;
use Net::Nslookup;
use Net::Ping;
use Time::HiRes;
use File::stat;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared qw(os_type perlpass_get);
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::Common);
#################################################################################

#################################################################################
### Public Exports ##############################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	source_host_check
	strip_domain
	add_domain
	add_domain_name
	nslookup_ip
	nslookup_name
	base_node_name
	mount_share
    ping_system
);
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.4 $)[-1];
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################


=head2  source_host_check($source_host)

 # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v 
 # Function: source_host_check($source_host)
 #  If the $host_name is not blank and the hostname is
 #   not the same then return 0,
 #   else return 1 (match = true, no source_host specified, or Windows)
 #  Note: this only works on UNIX at this time
 #  Requires hostalias executable
 # -------------------------------------------------------------------

=cut

  #################################################
  ## TODO: Test this on UNIX, Refactor as needed ##
  #################################################

sub source_host_check {
  my $queryhost = shift;
  my ($queryip, $a, $b, $c, $d, $line, @tmp, @fields, $ifip);
  
  # Don't run this on Windows...
  if (os_type() eq "WINDOWS") {
    return 0;
  }

  # we're going to use the scalar result of gethostbyname
  # and assume we only get 1 ip back from the host argument...
  $queryip = gethostbyname $queryhost;
  ($a,$b,$c,$d) = unpack ( 'C4', $queryip );
  $queryip = "$a.$b.$c.$d";
  
  print " Am I this host: \"$queryhost\"($queryip)\n";
  
  
  @tmp = `/sbin/ifconfig -a`;
  #open (FD, "/sbin/ifconfig -a 2>&1 |") && (@tmp= <FD>) && close FD;
  
  foreach $line ( @tmp) {
       # loop through each of the lines of stored output from
       #DEBUG#print $i;
       if ( $_= $line , /inet / ) {
          @fields = split ( '\s', $line);
          $ifip   = $fields[2];
          #DEBUG#print "ifip:  \"$ifip\"\n";
        
          last if ( $ifip eq $queryip );
       }
  }
  
  if ( $ifip eq $queryip ){
      #$debug && print "TRUE, I am $queryhost($queryip)\n";
      return 1;
  } else {
      #$debug && print "FALSE, I am not $queryhost($queryip)\n";
      return 0;
  }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  mount_share($share_name)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     mount_share($share_name)
	# Description:  use this function mount a share name
	# Returns:      1 (TRUE) if successful, 0 (FALSE) if not
	# Requires:     Windows
  # -------------------------------------------------------------------

=cut

sub mount_share {
	##########################
	## TODO: Test, Refactor ##
	##########################
	my $share_name     = shift;
	my $retval         = 0;
	my $share_name_len = length ($share_name);
	my ($user, $pass, @net_use, $sh_cmd, $line);

	## The calling program should check the OS before using this, but just in case...
	if (os_type() eq "UNIX") {
		return 1;
	}

	#if ($debug)                                                      { print "=== mount_share debug output ===\n\n"; }

	 # search and remove trailing \ if present.
	 #
	my $search_str = "\\";
	my $where      = rindex($share_name, $search_str);
	
	#if ($debug_extensive)                                            { print "  mount_share: searching for $search_str in $share_name returns $where\n"; }
	
	if ($where eq ($share_name_len - 1)) { chop($share_name); }
	
	#if ($debug_extensive)                                            { print "  share = $share_name\n"; }
	
	$user = perlpass_get('fileageuser');
	$pass = perlpass_get('fileagepass');
	
	chomp($user);
	chomp($pass);
	
	$sh_cmd = "net use " . $share_name . " \/USER:insidelive\\" . $user . " " . $pass;
	
	#if ($debug_extensive)                                            { print "  share command = net use $share_name\n"; }
	
	@net_use = `$sh_cmd`;
	
	 # look at the results of the net use command for the word "success"
	foreach $line (@net_use) {
			
			if (index($line, "success") ge 0) { $retval = 1; }
			
			#if ($debug_extensive)                                        { print "  net use output: $line\n"; }
	}
	
	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 strip_domain($host)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function:     strip_domain($host)
	#
	# Description:  strips any trailing domain name from the host
	#
	# Returns:      the host name without a domain
	#
	# Requires:     n/a
	#
	# -------------------------------------------------------------------
	
=cut

sub strip_domain ($) {

	my $host = shift;
	
	my @retval = split /\./, $host, 2;
	
	return $retval[0];
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 add_domain ($host)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     add_domain($host, [$domain])
	# Description:  adds the domain name (if $doamin isn't specified then insidelive.net is default)
	# Returns:      server with domain name
	# Requires:     n/a
	# -------------------------------------------------------------------
	
=cut

sub add_domain_name ($$) {
	my $host   = shift;
	my $domain = shift;
	my $retval;
	
	if (not $domain) { $domain = "insidelive.net"; }
	
	$host = strip_domain($host);
	
	return "$host.$domain";
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 add_domain ($host)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     add_domain($host)
	# Description:  adds the insidelive.net domain name
	# Returns:      server with domain name
	# Requires:     n/a
	# -------------------------------------------------------------------
	
=cut

sub add_domain ($) {
 return add_domain_name(shift, "insidelive.net");	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 nslookup_ip($node_name)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:    nslookup_ip($node_name)
	# Description: performs a nslookup on $node_name.
	# Returns:     IP Address of $node_name or 0 (usable with not) if not found.
	# Requires:
	#  ######################################
	#  #### Requires Net::Nslookup       ####
	#  ######################################
	#  Enhancements to do:
	#   - Is there a better return value setting?
	#   - Validate that $retval is 0 (usable with not) if not found...
	#
	# -------------------------------------------------------------------
	
=cut

sub nslookup_ip ($) {
	my $host_name = shift;
	
	return nslookup(host => "$host_name", type => "A");
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 nslookup_name($ip_address)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:    nslookup_name($ip_address)
	# Description: looks up a node based on ip address
	# Returns:     returns the PTR record associated with $ip_address or blank if not found.
	# Requires:
	#  ######################################
	#  #### Requires Net::Nslookup       ####
	#  ######################################
	#  Enhancements to do:
	#   - 
	# -------------------------------------------------------------------

=cut

sub nslookup_name ($) {
	my $ipaddr = shift;
	
	#return nslookup(host => "$ipaddr", type => "PTR");
	return nslookup('host' => "$ipaddr",
                  'type' => "PTR");
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 base_node_name($node_name)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:    base_node_name($node_name)
	# Description: looks up the IP address for node name then looks up the PTR record which should
	#              return the base node name.
	# Returns:     returns the PTR record value associated with $node_name or 0 if not valid.
	# Requires:
	#  ######################################
	#  #### Requires Net::Nslookup       ####
	#  ######################################
	#  Enhancements to do:
	#   - 
	# -------------------------------------------------------------------

=cut

sub base_node_name ($) {
	my $node   = shift;
	my ($retval, $ip);
	
  $ip        = nslookup_ip($node);
  
  if (not $ip)          {

    $retval = 0;

  } else {

    $retval  = nslookup_name($ip);

    if (not $retval)        {

			$retval = 0;
			
    }
		
  }
	
	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################


=head2  ping_system(hostname)

 # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
 # Function: ping_system(hostname)
 #  pings a host and returns the response time in milliseconds.
 #
 #  If unavailable, returns 0 (or FALSE)
 #
 # Requires Net::Ping and Time::HiRes to work properly.
 #
 #  
 # -------------------------------------------------------------------

=cut

sub ping_system {
   #use Net::Ping;
   #use Time::HiRes;
  
  my $host = shift;
  my ($retval, $ret, $duration, $ip, $ping, $timeout, $factor, $pong);
  
  $timeout = 3;

  if (os_type() eq 'WINDOWS') {
    $pong   = Net::Ping->new();
    $factor = 10;                      # used to calculate specific time settings
  } else {
    $pong = Net::Ping->new("icmp");
    $factor = 10000;                   # used to calculate specific time settings
  }

  (defined $pong)
      or die "Couldn't create Net::Ping object: $!\n";

  $pong->hires();
  ($ret, $duration, $ip) = $pong->ping($host, $timeout);
  
  if ($ret) {
    
    $retval = sprintf "%2d", ($factor * $duration);
    
  } else {
    
    $retval = 0;
    
  }
  
  $pong->close();
  
  return $retval;

}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES


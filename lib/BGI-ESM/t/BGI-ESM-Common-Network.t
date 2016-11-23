
=head1 NAME

Test module for BGI ESM Common Network Methods

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::Network

=head1 REVISIONS

CVS Revision: $Revision: 1.2 $

  #####################################################################
  # Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-09-07   nichj   Split from Shared to create standalone
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:
	: mount_share
	
=cut

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BGI-ESM-Common-Shared.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
#use Net::Nslookup;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared qw(os_type);

my @subs = qw(
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

BEGIN { use_ok('BGI::ESM::Common::Network', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'source_host_check'  );
can_ok( __PACKAGE__, 'strip_domain'       );
can_ok( __PACKAGE__, 'add_domain'         );
can_ok( __PACKAGE__, 'add_domain_name'    );
can_ok( __PACKAGE__, 'nslookup_ip'        );
can_ok( __PACKAGE__, 'nslookup_name'      );
can_ok( __PACKAGE__, 'base_node_name'     );
can_ok( __PACKAGE__, 'mount_share'        );
can_ok( __PACKAGE__, 'ping_system'       );


## source_host_check #########################
my $source_host_status;

if (os_type() eq "WINDOWS") {
	$source_host_status = source_host_check('vpo');
	is ($source_host_status, 0, 'source_host_check( ) returns 1 or 0 if the specified host is the source host');
} else {
	$source_host_status = source_host_check('vpo-dev');
	is ($source_host_status, 1, 'source_host_check( ) returns 1 or 0 if the specified host is the source host');
}

#############################################################
### These tests are intermingled ###########################

## strip_domain #######################
my $host_with    = "calntesm001.insidelive.net";
my $host_without = "calntesm001";

my $no_dom_host  = strip_domain($host_with);

is($no_dom_host, $host_without, 'strip_domain( ) should return the host name without the domain');

## add_domain #######################

my $dom_host = add_domain($host_without);
is( $dom_host, $host_with, 'add_domain( ) should return the host name with insidelive.net');

## add_domain_name #######################

my $alt_domain  = "other.net";
my $alt_host     = $host_without . "." . $alt_domain;
my $alt_dom_host = add_domain_name($host_without, $alt_domain);

is( $alt_dom_host, $alt_host, 'add_domain_name( ) should return the host name with the specified domain name');

## nslookup_ip #######################

my $nslookup_host    = $host_with;
my $nslookup_ip_addr = "69.52.104.46";

my $host_ip = nslookup_ip($nslookup_host);

is( $nslookup_ip_addr, $host_ip, 'nslookup_ip() should return the ip address of a host' );

## nslookup_name #######################

my $nslookup_host_name = nslookup_name($host_ip);

is ($nslookup_host_name, $nslookup_host, 'nslookup_host() should return the associated name of an ip address');

### end of intermingled tests ###############################
#############################################################

## base_node_name #######################

my $cname_name = "esm";

my $base_name  = base_node_name($cname_name);

is ($base_name, "calntesm001.insidelive.net", 'base_node_name( ) should return the base node name of a cname');


## ping_system #######################

my $response_time = ping_system($nslookup_host);
print "\nresponse time for pinging $nslookup_host: " . $response_time . "\n";

#####################################
## post-processing clean up #########
#####################################




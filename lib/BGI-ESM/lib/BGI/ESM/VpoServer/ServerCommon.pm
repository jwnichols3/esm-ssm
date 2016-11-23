=head1 TITLE



=head1 DESCRIPTION



=head1 USAGE



=head1 TODO




=head1 REVISIONS

CVS Revision: $Revision: 1.9 $

  #####################################################################
  #  2005-10-05 - nichj - Migrated to Perl Module
  #####################################################################
 
=cut

##############################################################################
### Package Name #############################################################
package BGI::ESM::VpoServer::ServerCommon;
##############################################################################

##############################################################################
### Module Use Section #######################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os);
use BGI::ESM::Common::Network;
##############################################################################

##############################################################################
### Require Section ##########################################################
require Exporter;
##############################################################################

##############################################################################
### Who is this ##############################################################
our @ISA = qw(Exporter BGI::ESM::VpoServer);
##############################################################################

##############################################################################
### Public Exports ###########################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    vpo_server_type
);
##############################################################################

##############################################################################
### VERSION ##################################################################
our $VERSION = (qw$Revision: 1.9 $)[-1];
##############################################################################

##############################################################################
# Public Variables
##############################################################################

##############################################################################
# Public Methods / Functions
##############################################################################


=head2 vpo_server_type($HOSTNAME)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#                 $HOSTNAME is the current server hostname
	#
	# Description:  This analyzes $HOSTNAME against the various vpo cnames and
	#                returns the type (prod, bcp, qa, dev) and role (primary or backup) in
	#                a hash array reference
	#
	# Returns:      Hash array reference true with the following values:
	#                  vpo_server_type{'TYPE' => "<type>"}
	#                  vpo_server_type{'ROLE' => "<role>"}
	#
	#                   <type> = prod, bcp, qa, dev
	#                   <role> = primary or backup
	#
	#                  If there are any problems, it will return FALSE (0)
	#
	# Requires:     ********* Net::Nslookup *********
	#
	# Example:
	#               $vpo_server  = vpo_server_type($HOSTNAME);
	#               %vpo_server  = %$vpo_server;
	#
	#               if ( $vpo_server->{'type'} = "prod" ) { print "This is the vpo production  server\n"; }
	#               if ( $vpo_server->{'type'} = "dev"  ) { print "This is the vpo development server\n"; }
	#               if ( $vpo_server->{'type'} = "bcp"  ) { print "This is the vpo BCP         server\n"; }
	#               if ( $vpo_server->{'type'} = "qa"   ) { print "This is the vpo QA          server\n"; }
	#
	#               if ( $vpo_server->{'role'}  = "primary" ) { print "This is a primary vpo server\n"; }
	#               if ( $vpo_server->{'role'}  = "backup"  ) { print "This is a backup  vpo server\n"; }
 	#
	# Updates / Enhancements:
	#               This will require updating when we get the two QA servers in place.
	#
	# -------------------------------------------------------------------
	
=cut

sub vpo_server_type {
	my $incoming_hostname = shift;
	   $incoming_hostname = lc $incoming_hostname;
	my ($return_hash, $test_host, $host_to_check, %vpo_server_list, $vpo_server_list);
	
	if (not $incoming_hostname) {
		warn "Invalid hostname in vpo_server_type().\n";
		return 0;
	}
	
	#print "\tIncoming hostname: $incoming_hostname\n";
	
	$vpo_server_list = {
												 'vpo'             => "rdcuxsrv054.insidelive.net",
												 'vpo-bcp'         => "ldnuxsrv003.insidelive.net",
												 'vpo-qa'          => "",
												 #'vpo-qa-backup'   => "",    # commented out until new servers arrive
												 'vpo-dev'         => "rdcuxsrv005.insidelive.net",
												 #'vpo-dev-backup'  => ""     # commented out until new servers arrive
										 };
										
	foreach my $test_host (sort keys %{$vpo_server_list}) {
		
		#print "\thost_name = $test_host\n";
		
		$host_to_check = lc strip_domain(base_node_name($test_host));
		
		#print "\thost_to_check = $host_to_check\n";
		
		if ($host_to_check) {

			$vpo_server_list->{$test_host} = $host_to_check;

		} else {

			next;

		}

	}
	
	#print_hash_formatted(\%vpo_server_list);

	#
	# Hash array of %vpo_server_list has keys of cnames and values of base node names
	# 
	if      ($incoming_hostname eq $vpo_server_list->{'vpo'}              ) {
		
			$return_hash = {'type' => "prod",  'role' => "primary"   };
			
	} elsif ($incoming_hostname eq $vpo_server_list->{'vpo-bcp'}          ) {

			$return_hash = {'type' => "bcp",   'role' => "primary"   };

	} elsif ($incoming_hostname eq $vpo_server_list->{'vpo-qa'}           ) {

			$return_hash = {'type' => "qa",    'role' => "primary"   };

	} elsif ($incoming_hostname eq $vpo_server_list->{'vpo-qa-backup'}    ) {

			$return_hash = {'type' => "qa",    'role' => "backup"    };

	} elsif ($incoming_hostname eq $vpo_server_list->{'vpo-dev'}          ) {

			$return_hash = {'type' => "dev",   'role' => "primary"   };

	} elsif ($incoming_hostname eq $vpo_server_list->{'vpo-dev-backup'}   ) {

			$return_hash = {'type' => "dev",   'role' => "backup"    };

	} else                                                                  {

			$return_hash = {'type' => "unknown",     'role' => "unknown" };

	}
  
  #print "type: " . $return_hash->{'type'} . "\n";
  #print "role: " . $return_hash->{'role'} . "\n";
	
	return $return_hash;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__


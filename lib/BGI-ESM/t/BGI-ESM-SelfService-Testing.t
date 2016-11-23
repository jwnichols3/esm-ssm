
=head1 NAME

Test module for BGI ESM SelfService Testing module

=head1 SYNOPSIS

This is test suite for BGI::ESM::SelfService::Testing

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.7 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-mm-dd   nichj   Developing release 1
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:
	
=cut

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BGI-ESM-Common-Shared.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
use Test::More tests => 15;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared;

my @subs = qw(
	get_ssm_config_list
  create_config_file
	get_config_file_location
	get_default_config_hash
  get_blank_config_hash
  get_run_number
 );

BEGIN { use_ok('BGI::ESM::SelfService::SsmTesting', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'get_ssm_config_list'                  );
can_ok( __PACKAGE__, 'create_config_file'                   );
can_ok( __PACKAGE__, 'get_config_file_location'             );
can_ok( __PACKAGE__, 'get_default_config_hash'              );
can_ok( __PACKAGE__, 'get_run_number'                       );
can_ok( __PACKAGE__, 'get_blank_config_hash'                );

#####################################
## pre-processing set up ############
#####################################

my $os = os_type();

my $agent_vars = agent_variables();
my $ssm_vars   = ssm_variables();
my $ssm_config_list = get_ssm_config_list();
my @ssm_config_list = @{$ssm_config_list};

#####################################
## The Tests ########################
#####################################

### Get SSM Config List ##############
my @expected_ssm_config_list = @ssm_config_list;

my $new_ssm_config_list = get_ssm_config_list();

is (@{$new_ssm_config_list}, @expected_ssm_config_list, 'get_ssm_config_list( ) should return a list of valid ssm config prefixes');

### Get Config File Location #########

my $config_file_location = get_config_file_location();

print "\tReturned config file location: $config_file_location\n";

### get_default_config_hash ##############
my $expected_default_hash =
									{
										'app'     => "",
										'sev'     => "",
									};

my $retrieved_default_hash = get_default_config_hash();

is_deeply ($retrieved_default_hash, $expected_default_hash, 'get_default_config_hash( ) should return a default hash for all config files.');


### get_run_number #######################

my $run_number = get_run_number();

is ($run_number, $run_number, 'get_run_number( ) returns the epoch time: ' . $run_number);


##########################################
### get_blank_config_hash(es) ############

foreach my $config_item (@ssm_config_list) {
	print "Config hash for $config_item:\n";
	my $config_hash = ();
	$config_hash  = get_blank_config_hash($config_item);
	print Dumper (\$config_hash);
	
}
### End of get_blank_config_hash(es) ######
###########################################

###########################################
### Config File Creation ##################

for my $location_item (@ssm_config_list) {
	my $expected_config_file = $config_file_location . "/" . $location_item . ".dat." . $run_number;
	my $config_file = create_config_file($location_item, $run_number);
	print "$location_item config file: $config_file\n";
	is ($config_file, $expected_config_file, 'create_config_file($prefix, $run_number) should return the filename.');
}

oc:
#####################################
## post-processing clean up #########
#####################################



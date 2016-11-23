
=head1 NAME

Test module for BGI ESM Self Service ParseAlertConfig

=head1 SYNOPSIS

This is test suite for BGI::ESM::SelfService::ParseAlertConfig

=head1 MAJOR REVISIONS

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-11-02   nichj   Initial release
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:
	: 
	
=cut

#########################################

use warnings;
use strict;
use Data::Dumper;
use Carp;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;

my @subs = qw(
    alert_config_array_of_hashes
    parse_alert_config
);

BEGIN { use_ok('BGI::ESM::SelfService::AlertConfig', @subs); };

#########################################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'alert_config_array_of_hashes');
can_ok( __PACKAGE__, 'parse_alert_config');

#########################################
##### Load common methods and variables
#########################################

my @monitor_list = qw(fileage filesys process rotate powerpath filesize);

PARSE_ALERT_CONFIG:

print "\n\nParse Alert Config\n";

my $app_parm   = "app=esm";
my $sev_parm   = "sev=Major";
my $desc_parm  = "description=This is the description parameter";
my $act_parm   = "action=comfort, 6099, sms action=emailfyi, nichj\@bgi; jn\@b2.com, subject";
my $unknown    = "other_parm=this is a different parm";

my $alert_config_record = "$app_parm $sev_parm $desc_parm $act_parm $unknown";


my $parsed_config = parse_alert_config($alert_config_record);

print Dumper $parsed_config;

is_deeply($parsed_config, $parsed_config, 'parse_alert_config( ) should return parsed alert config.');

ALERT_CONFIG_ARRAY:

print "\n\nAlert Config Array\n";
foreach my $monitor (@monitor_list) {
    
    my $alert_array = alert_config_array_of_hashes($monitor);
    
    print "\nProcessing monitor $monitor\n";
    print Dumper $alert_array;
	
	is_deeply($alert_array, $alert_array, 'alert_config_array_of_hashes(' . $monitor . ') should return an array of hashes.');
}


#####################################
## post-processing clean up #########
#####################################



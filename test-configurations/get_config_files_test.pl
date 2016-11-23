#!/usr/bin/perl -w
use strict;
use Data::Dumper;
#use Test::More tests => 3;
###############################################################################
##### Point the lib to the CVS source location(s)
###############################################################################
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::INC;

###############################################################################
##### Get the additional include locations from BGI::ESM::Common::INC
###############################################################################
my $addl_inc = get_include_locations();
push @INC, @{$addl_inc};

###############################################################################
##### Load common methods and variables
###############################################################################
require "setvar.pm";
require "ssm_common.pm";

###############################################################################
##### Testing Follows
###############################################################################

my @config_list = ("process", "fileage", "filesys", "powerpath", "ssm_logfiles");

foreach my $config_list_item (@config_list) {
	my @config_files = get_config_files($config_list_item);
	print "\n\nGetting Config Entries for $config_list_item\n";
	print Dumper (@config_files);
	print "Done with $config_list_item\n";
}

print "\n\nINC values\n";
print Dumper (@INC);
#!/usr/bin/perl -w
use strict;
use Test::More tests => 3;

###############################################################################
##### Setup Include Environment
###############################################################################
my @inc_cvs_windows  = (
		"c:/code/vpo/SSM/src/shared/setvar", "c:/code/vpo/SSM/src/shared/modules",
		"c:/code/vpo/global libraries", "/apps/esm/vpo/global libraries"
		);

my @inc_cvs_unix     = (
		"/apps/esm/vpo/SSM/src/shared/setvar", "/apps/esm/vpo/SSM/src/shared/modules"
		);

my @inc_server_lib   = ("/apps/esm/lib");

my @inc_vpo_agt_unix = ("/var/opt/OV/bin/instrumentation", "/var/opt/OV/bin/OpC/cmds");

### To prevent uninitialized vairables from being used...
	my @inc_env_ov_dir = ();
	if ($ENV{'OvAgentDir'}) {
		@inc_env_ov_dir = (
				$ENV{'OvAgentDir'} . "/bin/OpC/cmds",
				$ENV{'OvAgentDir'} . "/bin/HP OpenView/data/bin/instrumentation", 
			);
	}
	
my @inc_vpo_agt_win  = (
		@inc_env_ov_dir,
		"c:/usr/OV/bin/OpC/cmds", "c:/usr/OV/bin/HP OpenView/data/bin/instrumentation",
		"e:/usr/OV/bin/OpC/cmds", "e:/usr/OV/bin/HP OpenView/data/bin/instrumentation"
		);


my @add_inc = (
	@inc_cvs_windows, @inc_cvs_unix, @inc_server_lib, @inc_vpo_agt_unix, @inc_vpo_agt_win,
	"."
	);

push @INC, @add_inc;

###############################################################################
##### Load common methods and variables
###############################################################################
require "setvar.pm";
require "ssm_common.pm";

###############################################################################
##### Testing Follows
###############################################################################


#!/opt/OV/activeperl-5.8/bin/perl
#!/perl/bin/perl

=head1 NAME

Test module for BGI ESM Common Variables modules

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::Variables

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.14 $
    Date:     $Date: 2009/03/20 20:24:15 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-08-26   nichj   Developing release 1
  #  2005-10-27   nichj   Adding Linux Logic
  #  2009-03-20   nichj   Seeking a resolution to the Windows directory with spaces issue
  #
  #####################################################################

=head1 TODO

- Write tests for the following:
	
=cut


#########################

use warnings;
use strict;
use Data::Dumper;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm

my @subs = qw(
    agent_variables
    server_variables
    ssm_variables
    get_agent_version
    get_server_version
    get_agent_dirs
    get_agent_comm_type
    get_command_hash
    print_agent_variables
    print_server_variables
    print_ssm_variables
 );

BEGIN { use_ok('BGI::ESM::Common::Variables', @subs); };

#########################

can_ok( __PACKAGE__, 'agent_variables'        );
can_ok( __PACKAGE__, 'server_variables'       );
can_ok( __PACKAGE__, 'ssm_variables'          );
can_ok( __PACKAGE__, 'get_agent_version'      );
can_ok( __PACKAGE__, 'get_server_version'     );
can_ok( __PACKAGE__, 'get_agent_dirs'         );
can_ok( __PACKAGE__, 'get_agent_comm_type'    );
can_ok( __PACKAGE__, 'get_command_hash'       );
can_ok( __PACKAGE__, 'print_agent_variables'  );
can_ok( __PACKAGE__, 'print_server_variables' );
can_ok( __PACKAGE__, 'print_ssm_variables'    );

### Global Setup ###################################################################################################
####################################################################################################################
#### functions for testing purposes ################################################################################
sub _os_type {

    my $retval   = "";    
    my $platform = "$^O";
    chomp ($platform);

    if ( "$platform" eq "MSWin32" ) {
      $retval = 'WINDOWS';
    }
    elsif ( lc "$platform" eq "linux" ) {
        $retval = 'LINUX';
    }
    else {
      $retval = 'UNIX';
    }

    return $retval;
}  

sub _read_file_contents {
    my $file_name    = shift;
    my @return_array = "";
    open  CONFIG_FILE_TO_READ, "< $file_name";
    @return_array    = <CONFIG_FILE_TO_READ>;
    close CONFIG_FILE_TO_READ;
    return \@return_array;
}
#### variables used in testing purposes #######################################
my $os = _os_type();
###############################################################################

###############################################################################
##################################### Individual Class Testing Begins Here  ###
###############################################################################

## print_agent_variables() #################################################
print "--agent variables--\n";
my $status = print_agent_variables();
is ($status, 1,
    'print_agent_variables( ) should print the agent variables');

## print_server_variables() #################################################
print "--server variables--\n";
   $status = print_server_variables();
is ($status, 1,
    'print_server_variables( ) should print the server variables');

## print_ssm_variables() #################################################
print "--ssm variables--\n";
   $status = print_ssm_variables();
is ($status, 1,
    'print_ssm_variables( ) should print the ssm variables');

## get_agent_version() #################################################
my $set_agent_version;
my ($contents, $opcinfo_file, $opcagt_cmd, $opcagt_param, @agt_version, @agt_ver);

if ($os eq 'WINDOWS') {
    $opcinfo_file = "c:/usr/OV/bin/OpC/install/opcinfo";
    if (not -e $opcinfo_file) {
      $opcinfo_file = "";
    }
    $opcagt_cmd   = "opcagt";
    $opcagt_param = "-version";
}
else {
    $opcinfo_file = "/opt/OV/bin/OpC/install/opcinfo";
    $opcagt_cmd   = "/opt/OV/bin/OpC/opcagt";
    $opcagt_param = "-version";
}

if (-e $opcinfo_file) {
    $contents = _read_file_contents($opcinfo_file);
		@agt_version = grep { /OPC_INSTALLED_VERSION/ } @{$contents};
		
		@agt_ver = split / /, $agt_version[0];
		
		$set_agent_version = $agt_ver[1];
} else {    
    $set_agent_version = `$opcagt_cmd $opcagt_param`;
}

chomp ($set_agent_version);
my $agent_version     = get_agent_version();
is ($agent_version, $set_agent_version,
    'get_agent_version( ) should return the current agent version: ' . $agent_version);

#is ($agent_version, $BGI::ESM::Common::Variables::agent_version,
#    'get_agent_version( ) should return the current agent version in module: ' . $BGI::ESM::Common::Variables::agent_version);

## get_server_version() #################################################
my $set_server_version = '0.00';
my $server_version     = get_server_version();
is ($set_server_version, $server_version, 'get_server_version( ) should return the current server version: ' . $server_version);

## get_agent_comm_type() #################################################
my ($comm_type_cmd, $comm_type_param, $set_agent_comm_type);

if ($os eq 'WINDOWS') {
    $comm_type_cmd = "opcagt";
    $comm_type_param = "-type";
} else {
    $comm_type_cmd = "opcagt";
    $comm_type_param = "-type";
}
$set_agent_comm_type = `$comm_type_cmd $comm_type_param`;
chomp($set_agent_comm_type);

my $agent_comm_type     = get_agent_comm_type();
is ($agent_comm_type, $set_agent_comm_type,
    'get_agent_comm_type( ) should return the agent communication type: ' . $agent_comm_type);

#is ($agent_comm_type, $BGI::ESM::Common::Variables::agent_comm_type,
#    'get_agent_comm_type( ) agent communication type in module ' . $BGI::ESM::Common::Variables::agent_comm_type );

print "\n\nGet Command Hash\n\n";

my $command_hash = get_command_hash();

cmp_ok($command_hash, "gt", 1, 'get_command_hash( ) should return a hash of commands: ');
print Dumper $command_hash;

print "\n\nOutput from each command in the command hash\n\n";

foreach my $command (keys %{$command_hash}) {
    print "\nRunning $command\n\n";
    my $cmd = $command_hash->{$command};
    my @output = `$cmd`;
    print "@output\n";
}

#!/opt/OV/activeperl-5.8/bin/perl
use strict;
use warnings;

use lib "/code/vpo/BGI-ESM/lib";
use lib "/apps/esm/vpo/BGI-ESM/lib";

use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared;

my $vpo_version = get_agent_version();

print "Agent version is returning " . $vpo_version . "\n";

my $nslookup_host = "esm";

my $host_ip = nslookup_ip($nslookup_host);

my $nslookup_host_name = nslookup_name($host_ip);

print "host $nslookup_host ip address: " . $host_ip . "\n";
print "      resolved name: " . $nslookup_host_name . "\n";
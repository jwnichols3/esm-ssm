#!/opt/OV/activeperl-5.8/bin/perl

=head1 NAME

Test module for BGI ESM Common Shared Methods specific to Alerting

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::Shared methods specific to alerting.

=head1 REVISIONS

CVS Revsion: $Revision: 1.1 $
    Date:    $Date: 2006/03/17 18:34:49 $
    
    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2006-03-17   nichj   Created.  Added sms_alert_send test
    #####################################################################

=head1 TODO

    Move all alerting methods to this test library.
	
=cut

#########################

use warnings;
use strict;
use Data::Dumper;
use Carp;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;

my @subs = qw(
    sms_alert_send
);

BEGIN { use_ok('BGI::ESM::Common::Shared', @subs); };

#########################

can_ok( __PACKAGE__, 'sms_alert_send'               ); # done

#####################################
#####################################
## Start-processing         #########
#####################################
#####################################

SMS_ALERT_SEND:
{

    my @esmSMSNotifyList    = ("+447766364831", "+19256980520");  # John & Kris's SMS
    
    my $str                 = "Testing at " . time . " - This is only a test.";
    
    foreach my $sms_notify (@esmSMSNotifyList) {
      sms_alert_send("$sms_notify", "$str");
    }

}

#####################################
#####################################
## post-processing clean up #########
#####################################
#####################################



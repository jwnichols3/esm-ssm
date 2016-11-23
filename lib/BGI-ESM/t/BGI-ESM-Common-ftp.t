
=head1 NAME

Test module for BGI ESM Common ftp

=head1 SYNOPSIS

This is test suite for BGI::ESM::Common::ftp methods

=head1 REVISIONS

CVS Revsion: $Revision: 1.1 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2009-03-06   nichj   Developing 
  #  
  #####################################################################

=head1 TODO

- Write tests for the following:
	
=cut

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
use Carp;
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
#use BGI::ESM::Common::Variables;

my @subs = qw(
    ftp_file
 );

BEGIN { use_ok('BGI::ESM::Common::ftp', @subs); };

#########################

can_ok( __PACKAGE__, 'ftp_file');

FTP_FILE:
{
    # create file
    my ($redir, $FH, $fn);

    $fn = "ftp_test_" . time . ".txt";

    if (not (open ($FH, "> $fn") ) ) {
        warn "Unable to open $fn: $!";
        return 1;
    }
    
    print $FH "Testing ftp functionality\n";
    
    close $FH;
    
    my %ftp_hash = (
        from_file       => $fn,
        to_server       => "esm",
        to_dir          => "/data/temp",
        to_file         => $fn,
        user            => "esm_ftp",
        password        => "HYPertext01",
    );
    
    my $result = ftp_file(\%ftp_hash);
    
    is ($result, 1, "ftp_file should return 1 if successful: $result\n");
    # ftp file
    # check results
}


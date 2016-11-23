
=head1 NAME

Test module for BGI ESM SelfService Performance module

=head1 SYNOPSIS

This is test suite for BGI::ESM::SelfService::Performance

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.4 $

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


#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use warnings;
use strict;
use Data::Dumper;
use MLDBM qw(DB_File Storable);
use Fcntl;                     
use Test::More 'no_plan';
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared;

my @subs = qw(
    get_performance_stats
    split_perf_record
    retrieve_perf_record_key
    retrieve_all_perf_record_keys
    open_perf_file
    add_perf_record
    close_perf_file
    create_perf_record
    retrieve_perf_record
	query_perf_data
	get_perf_metric_list
 );

BEGIN { use_ok('BGI::ESM::SelfService::Performance', @subs); };

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok( __PACKAGE__, 'get_performance_stats'         );
can_ok( __PACKAGE__, 'create_perf_record'            );
can_ok( __PACKAGE__, 'split_perf_record'             );
can_ok( __PACKAGE__, 'retrieve_perf_record_key'      );
can_ok( __PACKAGE__, 'retrieve_all_perf_record_keys' );
can_ok( __PACKAGE__, 'open_perf_file'                );
can_ok( __PACKAGE__, 'add_perf_record'               );
can_ok( __PACKAGE__, 'retrieve_perf_record'          );
can_ok( __PACKAGE__, 'close_perf_file'               );
can_ok( __PACKAGE__, 'query_perf_data'               );
can_ok( __PACKAGE__, 'get_perf_metric_list'          );


#####################################
## pre-processing set up ############
#####################################

PREPROCESS:
{
    my $retval;
}

#####################################
#####################################
PERF_FILE_OPERATIONS:
{
    my $FILE_HANDLE = open_perf_file();
    
    is ($FILE_HANDLE, $FILE_HANDLE, 'open_perf_file( ) should return the file handle: ' . $FILE_HANDLE);
    #is_deeply ($dbhandle, $dbhandle, 'open_perf_db_file( ) should return a db handle if successful:' . Dumper ($dbhandle) . "\n");
 
    my $retval = close_perf_file($FILE_HANDLE);
    
    is ($retval, 1, 'close_perf_file( $FILE_HANDLE ) should return 1 if successful.');

}

#####################################
#####################################
PERFORMANCE_RECORD_OPS:
{
    print "\n\nGet Performance Record\n\n";
    #  get record 
    my ($perf_to_add)      = get_performance_stats();
    
    my $performance_record = create_perf_record($perf_to_add);
    
    print Dumper ($perf_to_add);
    
    # Add record
    print "\n\nAdd Performance Record\n\n";
    my $status = add_perf_record($perf_to_add);
    
    is ($status, 1, 'add_perf_record( $stat_key, $perf_to_add ) should return 1 if successful.');
    
    my $split_record   = split_perf_record($performance_record);
    
    is_deeply($split_record, $perf_to_add, 'split_perf_record( $performance_record ) should return a reference to an array with the performance record');

    my $record_key_got = retrieve_perf_record_key($perf_to_add);
    
    my $record_got     = retrieve_perf_record($record_key_got);
    
    print "\nPerformance Record for $record_key_got\n";
    print "$record_got\n";

}

#####################################
#####################################
PERFORMANCE_RECORDS:
{
    my $performance_keys = retrieve_all_perf_record_keys();
    
    print Dumper ($performance_keys);
    
    
}
    
#####################################
#####################################
GET_PERF_METRIC_LIST:
{
	print "\n\nGet Perf Metric List\n\n";
	
	print Dumper get_perf_metric_list();
	
	
	
}
#####################################
#####################################
QUERY_PERF_DATA:
{
	
	my $metric_list = get_perf_metric_list();
	
	foreach my $metric (@{$metric_list}) {
		
		print Dumper query_perf_data($metric);
		
	}
	
	
}
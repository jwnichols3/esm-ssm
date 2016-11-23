=head1 NAME

BGI ESM SelfService Performance

=head1 SYNOPSIS

Library Synopsis

=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.9 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-09-19   nichj   Starting
  #  2005-09-20   nichj   Moving away from using DB_File towards simple text file
  #  2005-10-10   nichj   Adding methods for process.monitor
  #  
  #####################################################################

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::SelfService::Performance;

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use Carp;
use Fcntl;                     
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared qw(trim read_file_contents unique_list_elements os_type);
###############################################################################

###############################################################################
### Require Section ###########################################################
require Exporter;
###############################################################################

###############################################################################
### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::SelfService);
###############################################################################

###############################################################################
### Public Exports ############################################################
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    add_perf_record
    close_perf_file
    create_perf_record
    get_perf_metric_list
    get_performance_stats
    open_perf_file
    query_perf_data
    retrieve_all_perf_record_keys
    retrieve_perf_record
    retrieve_perf_record_key
    split_perf_record
);
###############################################################################

###############################################################################
### VERSION ###################################################################
my $VERSION = (qw$Revision: 1.9 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################

###############################################################################
# Public Methods / Functions
###############################################################################

=head2 get_performance_stats()
    returns reference to a hash with performance data
=cut

sub get_performance_stats {
    my ($performance, $codautil_cmd);
    
    if (os_type() eq 'WINDOWS') {
        $codautil_cmd = "codautil -support";
    }
    else {
        if (-e "/opt/OV/bin/codautil") {
            $codautil_cmd = "/opt/OV/bin/codautil -support";
        }
        else {
            $codautil_cmd = "/opt/OV/bin/ovcodautil -support";
        }
    }

    my @codadata = `$codautil_cmd`;
    chomp(@codadata);
    my @perfdata = grep / : /, @codadata;
    
    # Split the coda data into fields and put the values into a hash
    foreach my $item (@perfdata) {
        my ($metric, $value) = split / : /, $item;
        $metric = trim($metric);
        $value  = trim($value);

        $performance->{$metric} = $value;

    }
    
    return ($performance);

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 retrieve_perf_record_key($performance_hash)
    returns the stat time as the key
=cut

sub retrieve_perf_record_key {
    my $performance = shift;
    my $record_key = $performance->{'GBL_STATTIME'};
    return $record_key;
}


=head2 add_perf_record($stat_time, $perf_hash)
    return 1 if successful, 0 if not
=cut

sub add_perf_record {
    my ($perf_hash) = @_;
    my $STAT_FILE   = open_perf_file();
    my $retval      = 1;
    
    my $perf_record = create_perf_record($perf_hash);
    
    print $STAT_FILE "$perf_record\n";
    
    my $status = close_perf_file($STAT_FILE);
    
    return $retval;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 create_perf_record($stat_time, $perf_hash)
    returns performance record scalar
=cut

sub create_perf_record {
    my ($perf_hash) = @_;
    my $delimiter   = ";;";
    my $record_key  = retrieve_perf_record_key($perf_hash);
    my $perf_record = "";
    
    foreach my $key (sort keys %{$perf_hash}) {
        $perf_record = $perf_record . "$key = \"" . $perf_hash->{$key} . "\" $delimiter ";
    }

    return $perf_record;    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 split_perf_record($performance_record)

=cut

sub split_perf_record {
    my $perf_record = shift;
    my $return_record;
    
    # split amongst the
    my @perf_stats = split / ;; /, $perf_record;
    
    chomp(@perf_stats);
    
    foreach my $stat (@perf_stats) {
        my ($key, $value) = split / = /, $stat;
        if ( $key ) {
            $value =~ s/^\"//;
            $value =~ s/\"$//;
            $return_record->{$key} = $value;
        }
    }

    return $return_record;
        
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 open_perf_file()

=cut

sub open_perf_file {
    my $retval = 0;
    my $perf_file = get_perf_file_name();
    my $PERF_FILE;
    
    if (not -e $perf_file) {
        open $PERF_FILE, ">",  $perf_file or croak "Unable to open $perf_file: $!\n";
    }
    else {
        open $PERF_FILE, ">>", $perf_file or croak "Unable to open $perf_file: $!\n";
    }
    
    return $PERF_FILE;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 close_perf_file()
=cut

sub close_perf_file {
    my $PERF_FILE = shift;
    
    close $PERF_FILE or croak "Unable to close file: $!\n";
    
    return 1;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_perf_file_name()
    returns scalar with the performance file name
=cut

sub get_perf_file_name {
    return _get_perf_file_name();
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 retrieve_perf_record(record_key)
    returns scalar with performance data for the corresponding record
=cut

sub retrieve_perf_record {
    my $record_to_find = shift;
    my $perf_file  = get_perf_file_name();
    my (@records, $return_record);
    
    my @perf_data  = read_file_contents($perf_file);
    
    foreach my $perf_record (@perf_data) {
        my $record_hash = split_perf_record($perf_record);
        my $record_key  = retrieve_perf_record_key($record_hash);

        if ($record_key eq $record_to_find) {
            $return_record = $perf_record;
            last;
        }

    }
    
    #if (@perf_data) {
    #    @records = grep /$record_key/, @perf_data;
    #}
    
    return $return_record;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 retrieve_all_perf_record_keys()
    returns a reference to a hash with all performance record keys
=cut

sub retrieve_all_perf_record_keys {
    my $perf_file = get_perf_file_name();
    my (@perf_keys);
    my @perf_data = read_file_contents($perf_file);
    
    if (@perf_data) {
        
        foreach my $record (@perf_data) {
            
            my $record_hash = split_perf_record($record);
            my $record_key  = retrieve_perf_record_key($record_hash);
            if ($record_key) {
                push @perf_keys, $record_key;
            }
            
        }
        
    }
    
    @perf_keys = unique_list_elements(@perf_keys);
    return \@perf_keys;
    
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 query_perf_data($metric, $duration)
    returns a reference to an array with the metric values for the duration
     specified.
    If the metric or the duration are invalid, then a blank array is returned.
=cut

sub query_perf_data {
    my ($metric, $duration) = @_;
    my (@metrics);
    
    
    return \@metrics;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_perf_metric_list()
    returns a reference to an array with the list of valid metrics
=cut

sub get_perf_metric_list {
    my (@metric_list);
    
    my $perf_record = get_performance_stats();
    
    @metric_list = keys %{$perf_record};
    
    return \@metric_list;
    
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

###############################################################################
### End of Public Methods / Functions #########################################
###############################################################################


###############################################################################
### Private Methods / Functions ###############################################
###############################################################################

sub _get_perf_file_name {
    my $perf_file = "perf_stats.db";
    my $ssm_vars  = ssm_variables();
  
    $perf_file    = $ssm_vars->{'SSM_LOGS'} . "/" . $perf_file;

    return $perf_file;    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


###############################################################################
### End of Private Methods / Functions ########################################
###############################################################################

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES

=cut
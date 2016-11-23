=head1 NAME

BGI ESM SelfService Diskspace Class

=head1 SYNOPSIS

This library is something used when needing Diskspace information

=head1 REQUIREMENTS NOTE

This module requires Class::Std to be part of the Perl distribution.

This is currently only available via CPAN.

=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.5 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-12-07   nichj   Initial Version
  #
  #####################################################################

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::SelfService::Diskspace;

###############################################################################
### Public Exports ############################################################
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	get_filesystem_list
	get_filesystem_type
	get_filesystem_types_list
	get_filesystem_size
	get_filesystem_free
	get_filesystem_full
	get_filesystem_free_percent
	get_filesystem_full_percent
);

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use Carp;
use Filesys::DiskFree;
use Win32::DriveInfo;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw( os_type unique_list_elements );


################################################################################
#### Require Section ###########################################################
require Exporter;
################################################################################
#
################################################################################
#### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::SelfService);
################################################################################

###############################################################################
# Public Variables
###############################################################################

our $BLANK = '';

###############################################################################
# Public Methods / Functions
###############################################################################

sub get_filesystem_list {
    
	if (os_type() eq 'WINDOWS') {
		return _get_win_filesystem_list(@_);
	}
	else {
		return _get_unix_filesystem_list(@_);
	}
    
}

sub get_filesystem_type {
    
	if (os_type() eq 'WINDOWS') {
		return _get_win_filesystem_type(@_);
	}
	else {
		return _get_unix_filesystem_type(@_);
	}
    
}

sub get_filesystem_types_list {
    
	if (os_type() eq 'WINDOWS') {
		return _get_win_filesystem_types_list(@_);
	}
	else {
		return _get_unix_filesystem_types(@_);
	}
    
}

sub get_filesystem_size {
	
	if (os_type() eq 'WINDOWS') {
		return _get_win_filesystem_size(@_);
	}
	else {
		return _get_unix_filesystem_size(@_);
	}

}

sub get_filesystem_free {

	if (os_type() eq 'WINDOWS') {
		return _get_win_filesystem_free(@_);
	}
	else {
		return _get_unix_filesystem_free(@_);
	}
    
}

sub get_filesystem_free_percent {

	if (os_type() eq 'WINDOWS') {
		return _get_win_filesystem_free_percent(@_);
	}
	else {
		return _get_unix_filesystem_free_percent(@_);
	}

}

sub get_filesystem_full {

	if (os_type() eq 'WINDOWS') {
		return _get_win_filesystem_full(@_);
	}
	else {
		return _get_unix_filesystem_full(@_);
	}
    
}

sub get_filesystem_full_percent {

	if (os_type() eq 'WINDOWS') {
		return _get_win_filesystem_full_percent(@_);
	}
	else {
		return _get_unix_filesystem_full_percent(@_);
	}

}


###############################################################################
### End of Public Methods / Functions #########################################
###############################################################################


###############################################################################
### Private Methods / Functions ###############################################
###############################################################################


sub _get_win_filesystem_list {
    my ($arg_ref) = @_;

    my $type = lc $arg_ref->{'type'};
	
	my $drive_types = _get_win_filesystem_types();
	
	my @drives = Win32::DriveInfo::DrivesInUse();
	
	my (@unknown, @removable, @local, @remote, @ram);
	
	foreach my $drive (@drives) {
		my $drive_type = _get_win_filesystem_type({ filesystem=>$drive });
	
		#print "\nDrive $drive is $drive_type, hash ref: " . $drive_types->{$drive_type} . "\n";
	
		if    ($drive_type eq 'unknown' ) {
			push @unknown, $drive;
		}
		elsif ($drive_type eq 'removable' ) {
			push @removable, $drive;
		}
		elsif ($drive_type eq 'local' ) {
			push @local, $drive;
		}
		elsif ($drive_type eq 'remote' ) {
			push @remote, $drive;
		}
		elsif ($drive_type eq 'ram' ) {
			push @ram, $drive;
		}
		else {
			push @unknown, $drive;
		}
	
	}
	
	if ($type eq 'unknown') {
		return \@unknown;
	}
	elsif ($type eq 'removable') {
		return \@removable;
	}
	elsif ($type eq 'local') {
		return \@local;
	}
	elsif ($type eq 'remote') {
		return \@remote;
	}
	elsif ($type eq 'ram') {
		return \@ram;
	}
	else {
		return \@drives;
	}
	
}


sub _get_unix_filesystem_list {
    my ($arg_ref) = @_;

    my $type = $arg_ref->{'type'};
	
}

sub _get_win_filesystem_size {
    my ($arg_ref) = @_;

    my $filesystem = _no_blanks_allowed($arg_ref->{'filesystem'});
	
	my $filesys_info = _get_win_filesystem_info({ filesystem=>$filesystem, want_hash=>1 });
	
	if ($filesys_info) {
		return $filesys_info->{'total_number_of_bytes'};
	}
	else {
		return $BLANK;
	}
	
}

sub _get_unix_filesystem_size {
    my ($arg_ref) = @_;

    my $filesystem = _no_blanks_allowed($arg_ref->{'filesystem'});
	
}

sub _get_win_filesystem_free {
    my ($arg_ref)    = @_;

    my $filesystem   = _no_blanks_allowed($arg_ref->{'filesystem'});
	
	my $filesys_info = _get_win_filesystem_info({ filesystem=>$filesystem, want_hash=>1 });
	
	if ($filesys_info) {
		return $filesys_info->{'total_number_of_free_bytes'};
	}
	else {
		return $BLANK;
	}
}

sub _get_win_filesystem_full {
    my ($arg_ref)    = @_;

    my $filesystem   = _no_blanks_allowed($arg_ref->{'filesystem'});
	
	my $filesys_info = _get_win_filesystem_info({ filesystem=>$filesystem, want_hash=>1 });
	
	if ($filesys_info) {
		return $filesys_info->{'total_number_of_full_bytes'};
	}
	else {
		return $BLANK;
	}
}


sub _get_win_filesystem_full_percent {
    my ($arg_ref)    = @_;

    my $filesystem   = _no_blanks_allowed($arg_ref->{'filesystem'});
	
	my $filesys_info = _get_win_filesystem_info({ filesystem=>$filesystem, want_hash=>1 });
	
	if ($filesys_info) {
		return $filesys_info->{'percentage_full'};
		}
	else {
		return $BLANK;
	}

}

sub _get_unix_filesystem_free {
    my ($arg_ref)  = @_;

    my $filesystem = _no_blanks_allowed($arg_ref->{'filesystem'});
	
}

sub _get_win_filesystem_free_percent {
    my ($arg_ref)    = @_;

    my $filesystem   = _no_blanks_allowed($arg_ref->{'filesystem'});
	
	my $filesys_info = _get_win_filesystem_info({ filesystem=>$filesystem, want_hash=>1 });
	
	if ($filesys_info) {
		return $filesys_info->{'percentage_free'};
	}
	else {
		return $BLANK;
	}

}

sub _get_unix_filesystem_free_percent {
    my ($arg_ref)  = @_;

    my $filesystem = _no_blanks_allowed($arg_ref->{'filesystem'});
	
}


sub _get_unix_filesystem_full {
    my ($arg_ref) = @_;

    my $filesystem = _no_blanks_allowed($arg_ref->{'filesystem'});
	
}

sub _get_win_filesystem_types_list {
	my $types_ref = _get_win_filesystem_types();
	
	my @type_list = sort values %{$types_ref};
	
	return unique_list_elements(@type_list);

}


sub _get_win_filesystem_types {
	my $drive_types = {

        '0' => "unknown",     # - the drive type cannot be determined.
        '1' => "unknown",     #  - the root directory does not exist.
        '2' => "removable",   #  - the drive can be removed from the drive (removable).
        '3' => "local",       #  - the disk cannot be removed from the drive (fixed).
        '4' => "remote",      #  - the drive is a remote (network) drive.
        '5' => "removable",   #  - the drive is a CD-ROM drive.
        '6' => "ram",         #  - the drive is a RAM disk.

    };

	return $drive_types;
	
}

sub _get_unix_filesystem_types {
	my $drive_types = {

		'' => ''
        #'0' => "unknown",     # - the drive type cannot be determined.
        #'1' => "unknown",     #  - the root directory does not exist.
        #'2' => "removable",   #  - the drive can be removed from the drive (removable).
        #'3' => "local",       #  - the disk cannot be removed from the drive (fixed).
        #'4' => "remote",      #  - the drive is a remote (network) drive.
        #'5' => "removable",   #  - the drive is a CD-ROM drive.
        #'6' => "ram",         #  - the drive is a RAM disk.

    };

	return $drive_types;
	
}


sub _get_win_filesystem_type {
    my ($arg_ref) = @_;

    my $filesystem = lc $arg_ref->{'filesystem'};
	
	my $drive_types = _get_win_filesystem_types();
	
	my $drive_type  = Win32::DriveInfo::DriveType($filesystem);
	
	if ($drive_type) {
		return $drive_types->{$drive_type};
	}
	else {
		return;
	}
}

sub _get_win_filesystem_info {
    my ($arg_ref) = @_;

    my $drive     = _no_blanks_allowed($arg_ref->{'filesystem'});
	my $want_hash = $arg_ref->{'want_hash'};
	
	my $drive_type = _get_win_filesystem_type({ filesystem=>$drive });
		
	if ( (not $drive_type) or ($drive_type eq 'removable') ) {
		return $BLANK;
	}
	
	my @drive_info = Win32::DriveInfo::DriveSpace( $drive );
	
	# Initize the variables.
	my (
			$sectors_per_cluster, $bytes_per_sector,
			$number_of_free_clusters, $total_number_of_clusters,
			$free_bytes_available_to_caller,
			$total_number_of_bytes, $total_number_of_free_bytes,
			$percentage_free, $percentage_full, $total_number_of_full_bytes
		) = $BLANK;
	
		(
			$sectors_per_cluster, $bytes_per_sector,
			$number_of_free_clusters, $total_number_of_clusters,
			$free_bytes_available_to_caller,
			$total_number_of_bytes, $total_number_of_free_bytes
		) = @drive_info;
	
	if ($total_number_of_free_bytes) {
		
		$total_number_of_full_bytes = ($total_number_of_bytes - $total_number_of_free_bytes);
		$percentage_free = ($total_number_of_free_bytes / $total_number_of_bytes);
		$percentage_full = ($total_number_of_full_bytes / $total_number_of_bytes);
		
		$percentage_free = sprintf "%.3f", ($percentage_free * 100);
		$percentage_full = sprintf "%.3f", ($percentage_full * 100);
		
	}
	
	if ($want_hash) {
		my $drive_hash = {
			'sectors_per_cluster'            => "$sectors_per_cluster",
			'bytes_per_sector'               => "$bytes_per_sector",
			'number_of_free_clusters'        => "$number_of_free_clusters",
			'total_number_of_clusters'       => "$total_number_of_clusters",
			'free_bytes_available_to_caller' => "$free_bytes_available_to_caller",
			'total_number_of_bytes'          => "$total_number_of_bytes",
			'total_number_of_free_bytes'     => "$total_number_of_free_bytes",
			'total_number_of_full_bytes'     => "$total_number_of_full_bytes",
			'percentage_free'                => "$percentage_free",
			'percentage_full'                => "$percentage_full",
		};

		return $drive_hash;
		
	}
	else {

		return @drive_info;

	}
}	

sub _no_blanks_allowed {
	my ($incoming) = @_;
	
	if (not $incoming) {
		croak "No blanks allowed here!";
	}
	
	return $incoming;
}


#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

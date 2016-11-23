=head1 TITLE

BGI::ESM::Common::Diff

=head1 DESCRIPTION

Provides methods to diff files

=head1 USAGE

	use BGI::ESM::Common::Diff

=head1 TODO




=head1 REVISIONS

CVS Revision: $Revision: 1.8 $

  #####################################################################
  #  2005-10-11 - nichj - Development
  #####################################################################
 
=cut

##############################################################################
### Package Name #############################################################
package BGI::ESM::Common::Diff;
##############################################################################

##############################################################################
### Module Use Section #######################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Text::Diff;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type);

##############################################################################

##############################################################################
### Require Section ##########################################################
require Exporter;
##############################################################################

##############################################################################
### Who is this ##############################################################
our @ISA = qw(Exporter BGI::ESM::Common);
##############################################################################

##############################################################################
### Public Exports ###########################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	diff_files
	diff_added
	diff_removed
	diff_files_patch
	clean_diff_records
);
##############################################################################

##############################################################################
### VERSION ##################################################################
our $VERSION = (qw$Revision: 1.8 $)[-1];
##############################################################################

##############################################################################
# Public Variables
##############################################################################

##############################################################################
# Public Methods / Functions
##############################################################################

=head2 diff_files_patch ( file_a, file_b )
	returns a scalar in a patch format of the difference in the two files
=cut

sub diff_files_patch {
	my ($file_a, $file_b) = @_;
	my $differences;
	
	if ( (not $file_a) or
		 (not $file_b) )
	{
		carp "diff_files: incorrect number of parameters!";
		return 1;
	}

	if (not -e $file_a) {
		carp "diff_files: file $file_a does not exist!";
		return 1;
	}

	if (not -e $file_b) {
		carp "diff_files: file $file_b does not exist!";
		return 1;
	}

	$differences = diff "$file_a", "$file_b";
	
	return $differences;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 diff_files ( file_a, file_b )
	returns output of the unix diff command
	note: this method is not supported on Windows, yet
=cut

sub diff_files {
	my ($file_a, $file_b) = @_;
	my @differences;
	my $diff_cmd = "diff";
	
	if (os_type() eq 'WINDOWS') {
		carp "diff_files method is not supported on Windows";
		return 1;
	}
	
	if ( (not $file_a) or
		 (not $file_b) )
	{
		carp "diff_files: incorrect number of parameters!";
		return 1;
	}

	if (not -e $file_a) {
		carp "diff_files: file $file_a does not exist!";
		return 1;
	}

	if (not -e $file_b) {
		carp "diff_files: file $file_b does not exist!";
		return 1;
	}

	@differences = `$diff_cmd $file_a $file_b`;
	
	chomp(@differences);
	
	return \@differences;
	
}


sub diff_removed {
	my ($file_a, $file_b, $option) = @_;
	my $clean_diff;

	my $diff_raw = diff_files($file_a, $file_b);
	
	my @diff_rem = grep(/\</, @{$diff_raw});
	
	if (lc $option eq 'clean') {
		$clean_diff = clean_diff_records(\@diff_rem);
		@diff_rem = @{$clean_diff};
	}

	return \@diff_rem
	
	
}

sub diff_added {
	my ($file_a, $file_b, $option) = @_;
	my ($clean_diff);

	my $diff_raw = diff_files($file_a, $file_b);
	
	my @diff_add = grep(/\>/, @{$diff_raw});
	
	if (lc $option eq 'clean') {
		$clean_diff = clean_diff_records(\@diff_add);
		@diff_add = @{$clean_diff};
	}
	
	return \@diff_add
	
}

sub clean_diff_records {
	my $incoming = shift;
	my @outgoing;
	
	foreach my $record (@{$incoming}) {
		my ($filler, $clean) = split / /, $record, 2;
		push @outgoing, $clean;
	}
	
	return \@outgoing;
	
}

##############################################################################
### End of Public Methods / Functions ########################################
##############################################################################

##############################################################################
### Private Methods / Functions ##############################################
##############################################################################



##############################################################################
### End of Private Methods / Functions #######################################
##############################################################################



#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################


__END__



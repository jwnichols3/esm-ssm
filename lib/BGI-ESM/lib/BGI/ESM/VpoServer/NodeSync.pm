
=head1 NAME

BGI ESM VpoServer NodeSync

=head1 SYNOPSIS

This library is used in NodeSync programs

=head1 REVISIONS

CVS Revision: $Revision: 1.12 $
    Date:     $Date: 2006/04/19 19:13:04 $

    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2005-10-20   nichj   Getting initial release done
    #  2005-12-16   nichj   Moving to a named parameter standard
    #
    #####################################################################

=head1 TODO


=cut


#################################################################################
### Package Name ################################################################
package BGI::ESM::VpoServer::NodeSync;
#################################################################################

#################################################################################
### Module Use Section ##########################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared;
use BGI::ESM::Common::Network;
use BGI::ESM::VpoServer::VPO;
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::VpoServer);
#################################################################################

#################################################################################
### Public Exports ##############################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    write_nodelist
    write_nodelist_archive
    write_nodelist_deltas
    nodes_from_source
    netiq_vpo_node_add
);
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.12 $)[-1];
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

my ($debug, $debug_extensive);

=head2 nodes_from_source($area, $type, $PGM_BIN)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Description:  calls the corresponding program to populate <area> and <type>
	#               The corresponding program should return a simple list of nodes that can be
	#               used to populate the node source files.
	#
	# Returns:      The output of the corresponding program (which should be an array of nodes).
	#
	# Requires:     the corresponding program.  DEFINED HERE.
	# -------------------------------------------------------------------

=cut

sub nodes_from_source {
    my $area    = shift;
    my $type    = shift;
    my $PGM_BIN = shift;
    my @retval;
    my $command_to_get_list;
    my $command_parameters; 
  
    print "\n\tArea: $area\n"   if ($debug);
    print "\n\tType: $type\n\n" if ($debug);
    
    if ($area eq "netiq") {
        $command_to_get_list = "$PGM_BIN/netiq_node_list";
        $command_parameters  = "";
    }
    
    if ($area eq "windows") {
        $command_to_get_list = "$PGM_BIN/windows_node_list";
        $command_parameters  = "";
    }
  
    if ($area eq "unix"   ) {
        $command_to_get_list = "$PGM_BIN/unix_node_list";
        $command_parameters  = "--area=$type";
    }
    
    if ($area eq "mssql"  ) {
        $command_to_get_list = "$PGM_BIN/mssql_node_list";
        $command_parameters  = "$type";
    }
    
    if ($area eq "sybase" ) {
        $command_to_get_list = "$PGM_BIN/sybase_node_list";
        $command_parameters  = "$type";
    }
    
    @retval = `$command_to_get_list $command_parameters`;
    
    @retval = strip_comments_from_array(@retval);
    
    return @retval;  
    
}

=head2 write_nodelist_deltas(\@remove_nodes_list, \@new_nodes_list, $nodelist_delta_file)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Description:  writes the node list delta file.
	#
	# Returns:      1 (TRUE) if good, 0 (FALSE) if not
	#
	# Requires:     n/a
	# -------------------------------------------------------------------
	
=cut

sub write_nodelist_deltas {
    my ($remove_nodes_list, $new_nodes_list, $nodelist_delta_file) = @_;
    my  @remove_nodes_list = @$remove_nodes_list;
    my  @new_nodes_list    = @$new_nodes_list;
    my ($retval, $nodes_added_from_source,
        $nodes_removed_from_source, $date_time_stamp,
        @file_contents);
  
    # The format of the delta file is
    #  Date/Time stamp of last run
    #  nodes_added_from_source=[node list of nodes new to the source list]
    #  nodes_removed_from_source=[node list of nodes no longer found in the source]
    #
    # To establish this we loop through the new nodes and create a variable with spaces inbetween each element
    #  do the same for removed nodes
    #  then write this to the file.

	$date_time_stamp           = "\ndelta_date="              . get_display_date();
	$nodes_added_from_source   = "nodes_added_from_source="   . join(" ", @new_nodes_list);
	$nodes_removed_from_source = "nodes_removed_from_source=" . join(" ", @remove_nodes_list);
	
	@file_contents             = ($date_time_stamp, $nodes_added_from_source, $nodes_removed_from_source);
	
			print "\tWriting to $nodelist_delta_file\n"           if ($debug_extensive);
	
	$retval                    = write_file_contents($nodelist_delta_file, \@file_contents, "append");
	
			print "\tStatus of writing delta file:    $retval\n"       if ($debug_extensive);

    return $retval;  

}


=head2 write_nodelist_archive($nodelist_file_to_archive, $nodelist_archive_file)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Description:  This takes the file to archive, adds a date/time line, then creates the archive file
	#
	# Returns:      1 (TRUE) if good, 0 if not
	#
	# Requires:     n/a
	# -------------------------------------------------------------------
	
=cut

sub write_nodelist_archive {
  my ($nodelist_file_to_archive, $nodelist_archive_file) = @_;
  my ($retval, @to_archive_contents, $archived_dateline, $filler_line);
  
    if (not -e $nodelist_file_to_archive) {
    
        warn "write_nodelist_archive: File $nodelist_file_to_archive doesn't exist!";
        $retval = 0;
    
    }
    else {
		
		# Define the array for writing.  Add date/time stamp headers to the top and bottom of the file
		# 
		@to_archive_contents = read_file_contents($nodelist_file_to_archive);
		
		$archived_dateline   = "##### Archived Date: " . get_display_date() . " #####";
		$filler_line         = "\n";
		
		unshift @to_archive_contents, $archived_dateline;
		unshift @to_archive_contents, $filler_line;
		
		push    @to_archive_contents, $filler_line;
		push    @to_archive_contents, $archived_dateline;

			print "Writing $nodelist_archive_file with archived data\n"   if ($debug_extensive);
			
		$retval = write_file_contents($nodelist_archive_file, \@to_archive_contents, "replace");
  
			print "Status of writing archived data:    $retval\n"         if ($debug_extensive);
			
	}

  return $retval;  
  
}


=head2 write_nodelist(\@nodelist, $nodelist_file)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Description:  prepends and Appends a write date/time stamp line
	#               Writes the nodelist array to $nodelist_file
	#
	# Returns:      1 (TRUE) if good, 0 if not
	#
	# Requires:     n/a
	# -------------------------------------------------------------------
	
=cut

sub write_nodelist {
  my ($nodelist, $nodelist_file) = @_;
  my  @nodelist = @$nodelist;
  my  ($retval, $display_date, $dateline);
  
	$display_date = get_display_date();
	
	$dateline     = "#### Created date/time:\t$display_date ####";
	
	unshift @nodelist, $dateline;
	push    @nodelist, $dateline;
	
					print "Writing node list to $nodelist_file\n"   if ($debug);
					print "\tNode list:\n"                                if ($debug_extensive);
					print_array(@nodelist)                                if ($debug_extensive);
	
	$retval = write_file_contents($nodelist_file, \@nodelist, "replace");
	
					print "\tStatus of writing node list:    $retval\n"   if ($debug_extensive);
  
  return $retval;  
  
}

=head2 netiq_vpo_add_node($node_name)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function: netiq_vpo_add_node(\@node_list)
	#
	# returns: (reference) \@base_nodes, \@invalid_nodes, \@already_in_vpo, \%added_nodes_hash{'node_name' => $status_of_add}
	#
	#  Enhancements to do:
	#   - clear up the logging options.
	#   - return if $node is blank
	#
	# -------------------------------------------------------------------

=cut

sub netiq_vpo_node_add {
	my ($arg_ref) = @_;
    
    my $node_list = _no_blanks_allowed($arg_ref->{'NODE_LIST'});
    my $debug     = $arg_ref->{'DEBUG'};
    my $dry       = $arg_ref->{'DRY'};
    
	my @node_list = @{$node_list};
	my (@base_nodes, @nodes_to_add, @nodes_already_in_vpo, @invalid_nodes,
		$node, $base_node, $in_vpo,
		%status_return, $status);
	my $type  = "MESSAGE_ALLOWED";
	my $hier  = "netiq";
	my $group = "windows";
	
	
	print "\tIncoming node list:\n\n" if ($debug_extensive);
	print_array(@node_list) if ($debug_extensive);
	
	foreach $node (@node_list) {
	  
		chomp($node);
		
		$node = trim($node);
		
		$base_node = base_node_name($node);
		
		if ($base_node) {                                                  # If base_name is populated then nslookup worked.
			print "\nIncluding $node";
			push @base_nodes, $base_node;
			print "\t$node  =  $base_node\n" if ($debug_extensive);
	  
		} else {                                                           # If base_name is blank then nslookup DIDN'T work.
			push @invalid_nodes, $node;
			print "\n\t$node  is  INVALID!";
		  
		}
	  
	}
	
	print "\tInvalid node list:\n\n" if ($debug_extensive);
	print_array(@invalid_nodes) if ($debug_extensive);
	
	
	print "\tValid node list:\n\n" if ($debug_extensive);
	print_array(@base_nodes) if ($debug_extensive);
	
	# A valid list of nodes based on nslookup is in @base_nodes.  Now see if they are in vpo:
	
    my $vpo_node_list = get_vpo_node_list();
    my @node_delta_r  = remove_array_from_array(\@base_nodes, \@{$vpo_node_list});
    
    my @node_delta = split / /, $node_delta_r[0];
    
    print "\nNetIQ Nodes\n\n";
    print Dumper @base_nodes;
    print "\n===End of NetIQ Node List===\n\n";
    print "\nVPO Nodes\n\n";
    print Dumper $vpo_node_list;
    print "\n===End of VPO Node List===\n\n";
    print "\nDelta Nodes\n\n";
    print Dumper @node_delta;
    print "\n===End of Delta Nodes===\n\n";
    
	print "Checking for presence of nodes in VPO\n\n";
	foreach $node (@node_delta) {
	  
		$in_vpo = vpo_node_exist($node);
		
		if ($in_vpo) {
			
			print "$node already in VPO\n";
	  
			push @nodes_already_in_vpo, $node;
		  
		}
		else {
		  
			print "$node not in VPO\n";
			
			push @nodes_to_add, $node;
		  
		}
	  
	}
	
	print "\tNodes already in VPO:\n\n" if ($debug_extensive);
	print_array(@nodes_already_in_vpo)  if ($debug_extensive);
	
	print "\tNodes to add to VPO:\n\n" if ($debug_extensive);
	print_array(@nodes_to_add)         if ($debug_extensive);
	
	# A list of valid nodes not in VPO is in @noes_to_add
  
	foreach $node (@nodes_to_add) {
	  
		if (not $dry) {
            if ($debug_extensive)                                                 { print "\nCalling vpo_node_add $node $type $hier $group\n\n"; }
          
                $status = vpo_node_add($node,$type,$hier,$group);
                
                $status_return{$node} = $status;
          
            if ($debug_extensive)                                                 { print "\nvpo_node_add status: $status\n\n"; }
        }
        else {
            print "\nNot adding to vpo as the dry run option is set.\n";
        }
	}

	print "\tStatus of adding to VPO\n\n" if ($debug_extensive);
	print_hash_formatted(\%status_return);

	return (\@base_nodes, \@invalid_nodes, \@nodes_already_in_vpo, \%status_return);
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################

sub _no_blanks_allowed {
	my ($incoming) = @_;
	
	if (not $incoming) {
		croak "No blanks allowed here!";
	}
	
	return $incoming;
}


#################################################################################
### End of Private Methods / Functions ##########################################
#################################################################################

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES


=cut



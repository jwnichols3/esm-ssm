
=head1 NAME

BGI ESM Common Shared File Find Methods

=head1 SYNOPSIS

This library is used in BGI ESM programs to load a common set of file find utils.

=head1 REVISIONS

CVS Revision: $Revision: 1.1 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-10-25   nichj   Getting initial release done
  #  
  #####################################################################

=head1 TODO


=cut


#################################################################################
### Package Name ################################################################
package BGI::ESM::Common::FileFind;
#################################################################################

#################################################################################
### Module Use Section ##########################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use File::Find;
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::Common);
#################################################################################

#################################################################################
### Public Exports ##############################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    find_files_in_sub
);
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.1 $)[-1];
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

#sub find_files_in_subdir_regex_pattern {
#    my  $subdirectory_to_start = shift;
#    my  $pattern_to_match      = shift;
#       # (@find_files_list_file_found_list, @return_array);
#    
#     # Using the file
#    find (\&find_files_get_list_regex, "$subdirectory_to_start");
#    
#    foreach my $item (@log_list_file_found_list) {
#      $item =~ s/\\//g;   # replace any \ with /
#      push @return_array, $item
#    }
#
#
#   # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
#   # Sub Function: find_files_get_list_regex()
#   #  this function is called to setup all standard variables.
#   # ----------------------------------------------------------------
#  sub find_files_get_list_regex {
#    my ($file);
#    
#    $file = "$File::Find::name";
#  
#    return unless -f "$file";
#    
#    $file =~ s/ /\\ /g;
#    
#    if ($file =~ m/$pattern_to_match/) {
#    
#      push @log_list_file_found_list, $file;
#      
#    }
#    
#  }
#   # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
#
#  return @return_array;
#    
#}
# # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 find_files_in_sub($dir, $return_info)
    $dir = the directory to search
    $return_info = (all | files | dirs) - defaults to all
=cut

sub find_files_in_sub {
    my $target_path = shift;
    my $return_info = shift;
    our (@paths, @files, @all, @retval);

    find (\&ProcessTree,$target_path);

    if ($return_info) {
        
        if (lc $return_info eq "files") {
            
            @retval = @files;
            
        }
        elsif (lc $return_info eq "dirs") {
            
            @retval = @paths;
            
        }
        else {
            
            @retval = @all;
            
        }
    }
    else {
        
        @retval = @all;
        
    }

    (@paths, @files, @all) = "";
    
    return \@retval;

    ###############################
    sub ProcessTree
    {
        if (-d $File::Find::name) {
            #print "Directory: $File::Find::name\n";
            push @paths, $File::Find::name;
            push @all, $File::Find::name;
        }
        else {
            push @files, $File::Find::name;
            push @all, $File::Find::name;
            #print "File: $File::Find::name\n";
        }
    
    }

}

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################



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



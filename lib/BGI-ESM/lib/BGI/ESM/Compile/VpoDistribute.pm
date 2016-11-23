=head1 TITLE

SSM v2 VPO Distribution Module

=head1 DESCRIPTION

Use this module when wanting to copy programs, etc. to the VPO distribution
 directories.

=head1 USAGE

use BGI::ESM::Compile::VpoDistribute

=head1 TODO



=head1 REVISIONS

CVS Revision: $Revision: 1.25 $

  #####################################################################
  #  2005-09-06 - nichj - Original
  #  2005-10-27 - nichj - Adding LINUX logic
  #  2006-03-23 - nichj - The distribution program will make a backup of the existing
  #                        program - this should provide some level of backup.
  #                       
  #####################################################################
 
=cut

#################################################################################
### Package Name ################################################################
package BGI::ESM::Compile::VpoDistribute;
#################################################################################

#################################################################################
### Module Use Section ##########################################################
use 5.008000;
use strict;
use warnings;
use File::stat;
use Data::Dumper;
use Carp;
use File::Copy;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type unique_list_elements copy_file remove_file);
use BGI::ESM::Compile::Ssm;
use BGI::ESM::Compile::Common;
##############################################################################

##############################################################################
### Require Section ##########################################################
require Exporter;
##############################################################################

##############################################################################
### Who is this ##############################################################
our @ISA = qw(Exporter BGI::ESM::Compile);
##############################################################################

##############################################################################
### Public Exports ###########################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    distribute_continue
    get_agent_types
    get_distribute_dirs
    distribute_location_summary
    print_distribute_dirs
    print_distribute_file_list
    get_all_distrib
    get_all_os_distrib
    get_all_type_distrib
    get_destination_file_name
    get_from_file_name
    copy_distrib
    get_distrib_dest_file_name
    get_bin_name_with_compile_path
);

##############################################################################

##############################################################################
### VERSION ##################################################################
our $VERSION = (qw$Revision: 1.25 $)[-1];
##############################################################################

##############################################################################
# Public Methods / Functions
##############################################################################

=head2 distribute_continue()
    returns: 1 if successful, 0 if not
=cut

sub distribute_continue {
    my $retval = 1;
    # get the directories
    # make sure the target directories exists based on the type of
    # get the bin files
    # make sure the bin files exist
    
    if (not _distrib_dirs_exist()) {
        print "The distribution directories do not exist!\n";
        $retval = 0;
    }
    
    if (not compile_continue()) {
        print "The proper compile and cvs directories do not exist!\n";
        $retval = 0;
    }
    
    return $retval;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_agent_types

    returns array ref with list of agent types
    
=cut

sub get_agent_types {
    my @agent_type_list = qw(HTTPS DCE);
    return \@agent_type_list;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_distribute_dirs()
 returns: a hash reference with the following keys:
  'UNIX'    => {
                 'DCE'   => "solaris dce distribution location"
                 'HTTPS' => "solaris https distribution location",
                 'BIN'   => "solaris compiled bin directory"
                }
  'LINUX'    => {
                 'DCE'   => "linux dce distribution location"
                 'HTTPS' => "linux https distribution location",
                 'BIN'   => "linux compiled bin directory"
                }
  'WINDOWS' => {
                 'DCE'   => "windows dce distribution location"
                 'HTTPS' => "windows https distribution location"
                 'BIN'   => "windows compiled bin directory"
                }

=cut

sub get_distribute_dirs {
    
    return _distribute_dirs();
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 compile_location_summary()
=cut

sub distribute_location_summary {
  
    compile_location_summary();
    
    print_distribute_dirs();
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 print_distribute_dirs()
    prints the distribution directories
=cut

sub print_distribute_dirs {
    my $distrib_dirs = get_distribute_dirs();
    
    foreach my $key (keys %{$distrib_dirs}) {
        
        foreach my $subkey (keys %{$distrib_dirs->{$key}}) {
            print $key . " type: " . $subkey . " dir: " . $distrib_dirs->{$key}->{$subkey} . "\n";
        }
    }
    
}

sub print_distribute_file_list {
    my $all_programs_list = get_program_hash();
    
    print "\n\nThe list of programs that can be called for distribution:\n\n";
    
    foreach my $item (keys %{$all_programs_list}) {
        print "\t$item\n";
    }
    
}

=head2 get_all_os_distrib()
    Returns: reference to array with the OS types used in the distribution programs
=cut

sub get_all_os_distrib {
    my @retval = ('WINDOWS', 'UNIX', 'LINUX');
    
    return \@retval;
    
}

=head2 get_all_distrib()
    Returns: reference to array with a list of all programs that can be distributed
=cut

sub get_all_distrib {
    my $program_list = get_program_hash();
    
    my @list = keys %{$program_list};
    
    return \@list;

}

=head2 get_all_type_distrib()
    Returns: reference to array with the agent types
=cut

sub get_all_type_distrib {
    my @retval = ('DCE', 'HTTPS');
    
    return \@retval;    
}

=head2 get_distrib_dest_file_name($program, $os, $type)
    returns the distribution destination file name based on program, os, and type
=cut

sub get_distrib_dest_file_name {
    my ($program, $os, $type) = @_;
    
    return _distrib_dest_file_name($program, $os, $type);
    
}

=head2 copy_distrib($program, $os, $type, $logfile, $dry)
    Copies the distribution source file to the destination file based on the program name, os, and type.
    Writes out the results to $logfile
    Doesn't process if $dry is set
=cut

sub copy_distrib {
    my ($program, $os, $type, $logfile, $dry) = @_;
    my ($status);
    my $retval = 1;
    
    
    if (not $dry) {
        my $write_text  = "";
        my $from_file   = get_from_file_name($program, $os, $type);
        my $dest_file   = get_destination_file_name($program, $os, $type);
           $write_text  = "For real: $program, $type, $os\n" .
                          "\tFrom file: " . $from_file . "\n" .
                          "\tTo file:   " . $dest_file . "\n";

        if (should_copy($program, $os)) {
            
            $status = _copy_distrib($program, $os, $type);
            
            $write_text = $write_text . "\tStatus: $status\n";
            
            if (not $status) {
                carp "There was a problem copying the distribution file: $!\n";
                $retval = 0;
            }
        }
        else {
            $write_text = $write_text . "\tStatus: should not copy\n";
        }
        write_log($logfile, $write_text);
 
    }
    else {
        my $write_text = "";
        
        my $from_file   = get_from_file_name($program, $os, $type);
        my $dest_file   = get_destination_file_name($program, $os, $type);
        
        if ( not $from_file ) {
            
            $write_text = "Unable to determine from file name for $program\n";
            $retval = 0;
        }
        else {
        
            $write_text = "Dry run:  $program, $type, $os\n" .
                             "\tFrom file: " . $from_file . "\n" .
                             "\tTo file:   " . $dest_file . "\n";

            if (should_copy($program, $os)) {
                $write_text = $write_text . "\tStatus: COPY\n";
            }
            else {

                $write_text = $write_text . "\tStatus: should not copy\n";
            }

            write_log($logfile, $write_text);
        }

        print $write_text;
    }
    
    return $retval;
}


sub get_destination_file_name {
    my ($program, $os, $type) = @_;
    
    return _get_copy_file($program, $os, $type, 'to');
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

sub get_from_file_name {
    my ($program, $os, $type) = @_;
    
    return _get_copy_file($program, $os, $type, 'from');
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


sub should_copy {
    my ($program, $os) = @_;
    my $program_list   = get_program_hash();
    my $retval         = 0;
    
    if (exists($program_list->{$program}->{$os}) ) {
        if ($program_list->{$program}->{$os} ne "") {
            $retval = 1;
        }
    }
    
    return $retval;
    
}

##############################################################################
### End of Public Methods / Functions ########################################
##############################################################################


##############################################################################
### Private Methods / Functions ##############################################
##############################################################################

=head2 _copy_distrib($program, $os, $type)
    this is the private method of copy_distrib.
    It takes input from $program, $os, and $type to determine the from and to files
    It removes the old $to file
    It copies the from file to the $to file
    If all is successful it returns 1, else it returns 0
=cut

sub _copy_distrib {
    my ($program, $os, $type) = @_;
    my $retval                = 0;
    
    my $copy_from = get_from_file_name($program, $os, $type);
    my $copy_to   = get_destination_file_name($program, $os, $type);

    if ( _remove_dist_file($copy_to) ) {
        if (copy_file($copy_from, $copy_to)) {
            if (set_permissions($copy_to)) {
                $retval = 1;
            }
            else {
                carp "Unable to change permissions on $copy_to";
            }
        }
        else {
            carp "Unable to copy $copy_from to $copy_to: $!\n";
        }
    }
    else {
        carp "Unable to remove $copy_to file: $!\n";
    }
    
    return $retval;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _remove_dist_file($file_name)
    This will tack an .Z to the incoming file, then try to delete the $file_name.Z
    if that doesn't work it will try to remove $file_name (in case the vpo distribution hasn't happened).
    if neither works, then it returns a 0
=cut

sub _remove_dist_file {
    my $file_name = shift;
    my $retval    = 1;
    
    my $compressed_file_name = $file_name . ".Z";
    my $backup_copy_file_name = $file_name . ".old" . ".Z";
    
    if (-e $compressed_file_name) {
        if (not copy_file($compressed_file_name, $backup_copy_file_name)) {
            $retval = 0;
        }
        if (not remove_file($compressed_file_name)) {
            $retval = 0;
        }
    }
    else {
        if (-e $file_name) {
            if (not remove_file($file_name)) {
                $retval = 0;
            }
        }
    }

    return $retval;    
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _get_copy_file($program, $os, $type, $direction)
    returns the full path to the file name to copy.
    $direction should be either 'from' or 'to'
=cut

sub _get_copy_file {
    my ($program, $os, $type, $direction) = @_;
    my $retval;
    
    if (lc $direction eq 'from') {

        # determine if it is an exe, then find & return the exe based on the os
        # else return the source file
        if (compile_check($program)) {
            
            $retval = get_bin_name_with_cvs_path($program, $os);
            #$dist_dir_hash->{'BIN'} . "/" . get_bin_base_name($program, $os);
            
        }
        else {
            
            $retval = get_program_source_file($program, $os);
            
        }
        
    }
    elsif (lc $direction eq 'to') {

        ## get the to destination directory and file name based on the os

        $retval = get_distrib_dest_file_name($program, $os, $type);
        
    }
    
    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

sub _distrib_dest_file_name {
    my $program       = shift;
    my $os            = shift;
    my $type          = shift;
    my $program_list  = get_program_hash();
    my $dist_dir_hash = get_distribute_dirs();
    my $dist_dir      = $dist_dir_hash->{$os}->{$type};
    my $retval;
    
    if (exists($program_list->{$program}->{$os})) {
        return $dist_dir . "/" . $program_list->{$program}->{$os};
    }
    else {
        return 0;
    }
    
}
    

=head2 _distribute_dirs()
=cut

sub _distribute_dirs {
    
    my $distrib_dirs = {
        'UNIX'    => {
                      'DCE'   => "/var/opt/OV/share/databases/OpC/mgd_node/customer/sun/sparc/solaris/cmds",
                      'HTTPS' => "/var/opt/OV/share/databases/OpC/mgd_node/customer/sun/sparc/solaris7/cmds",
                      'BIN'   => "/apps/esm/vpo/SSM/bin/solaris"
                     },

        'LINUX'   => {
                      'DCE'   => "/var/opt/OV/share/databases/OpC/mgd_node/customer/linux/intel/linux24/cmds",
                      'HTTPS' => "/var/opt/OV/share/databases/OpC/mgd_node/customer/linux/x86/linux24/cmds",
                      'BIN'   => "/apps/esm/vpo/SSM/bin/linux"
                     },

        'WINDOWS' => {
                      'DCE'   => "/var/opt/OV/share/databases/OpC/mgd_node/customer/ms/intel/nt/cmds",
                      'HTTPS' => "/var/opt/OV/share/databases/OpC/mgd_node/customer/ms/x86/winnt/cmds",
                      'BIN'   => "/apps/esm/vpo/SSM/bin/windows"
                     }
    };

    return $distrib_dirs;
};
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _distrib_dirs_exist()
    Returns 1 if distrib dirs exist, 0 if not 
=cut

sub _distrib_dirs_exist {
    my $retval = 1;
    
    my $distrib_dirs = get_distribute_dirs();
    
    foreach my $key (keys %{$distrib_dirs}) {
        
        foreach my $subkey (keys %{$distrib_dirs->{$key}}) {
            #print $key . " type: " . $subkey . " dir: " . $distrib_dirs->{$key}->{$subkey} . "\n";
            if (not -e $distrib_dirs->{$key}->{$subkey}) {
                print "\tDirectory " . $distrib_dirs->{$key}->{$subkey} . " does not exist!\n";
                $retval = 0;
            }
        }
    }
    
    return $retval;
    
}


##############################################################################
### End of Private Methods / Functions #######################################
##############################################################################

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head2 DEVELOPER'S NOTES
 

=cut


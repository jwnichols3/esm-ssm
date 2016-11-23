=head1 TITLE

Compile Module: BGI::ESM::Compile::Common

=head1 DESCRIPTION

Use this module when wanting to compile programs.

=head1 USAGE

use BGI::ESM::Compile::Common

=head1 TODO

    


=head1 REVISIONS

CVS Revision: $Revision: 1.10 $
    Date: 

  #####################################################################
  #  2005-09-27 - nichj - Split into Common.pm
  #  2005-09-28 - nichj - adding set_permissions and set_execute
  #  2005-10-27 - nichj - Adding LINUX logic
  #####################################################################
 
=cut

#################################################################################
### Package Name ################################################################
package BGI::ESM::Compile::Common;
#################################################################################

#################################################################################
### Module Use Section ##########################################################
use 5.008000;
use strict;
use warnings;
use File::stat;
use Data::Dumper;
use File::Basename;
use File::chmod qw(chmod getmod);
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os);
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::Compile);
#################################################################################

#################################################################################
### Public Exports ##############################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    compile
    cvs_commit
    dry_run_settings
    get_compile_common_version
    get_compile_settings
    get_cvs_root
    get_module_dir
    get_perldoc_settings
    perldoc_pgm
    set_permissions
    set_permissions_server
    set_execute
    write_log
);
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.10 $)[-1];
#################################################################################

#################################################################################
# Public Variables
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################


=head2 get_compile_ssm_version

    returns a scalar with the version of this module
    
=cut

sub get_compile_common_version {
    return $VERSION;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_cvs_lroot([$os]) {
    Returns scalar with cvs root
    if $os is not specified then the current os is assumed
=cut

sub get_cvs_root {
    my $os      = shift;
    my $cvsroot = "";
    
    $os         = check_os($os);
    
    if ($os eq 'WINDOWS') {
        $cvsroot = "c:/code/vpo";
    }
    elsif ($os eq 'LINUX') {
        $cvsroot = "/apps/esm/vpo";
    }        
    else {
        $cvsroot = "/apps/esm/vpo";
    }
    
    return $cvsroot;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_module_dir([$os])
    returns scalar with module directory based on $os
    if $os is not specified then current os is assumed
=cut

sub get_module_dir {
    my $os = shift;
       $os = check_os($os);
    
    my $cvsroot = get_cvs_root($os);
    
    return "$cvsroot/BGI-ESM/lib";
       
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 dry_run_settings($opt_dry)
    returns 1 if $opt_dry is set, 0 if not
    usage my $dry = dry_run_settings($opt_dry)
=cut

sub dry_run_settings {
    my $dryrun = shift;
    
    if ($dryrun) {
      return 1;
    }
    else {
      return 0;
    }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 write_log($logfile, $logtext)
=cut

sub write_log {
    my $logfile = shift;
    my $logtext = shift;
    
    open (LOGFILE, ">> $logfile") or carp "Unable to open $logfile: $!\n";
    print LOGFILE "$logtext\n";
    close LOGFILE;

    return 1;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 compile($source_file, $destination_exe_file, $dry, $logfile, $checkin)
    returns 1 if successful
=cut

sub compile {
    my ($source, $destination, $dry, $logfile, $checkin) = @_;
    my $retval = 1;
    
    my ($compile_pgm, $compile_opts) = get_compile_settings();
    
    if ( (not $source) or (not $destination) ) {
        carp "Compile: Source and/or Destiantion not specified";
        return 0;
    }
  
    my $compile      = "$compile_pgm $compile_opts $destination $source";
    write_log($logfile, "compile entry: $compile");
    
    if (not $dry) {
        my $status = `$compile`;
      
        write_log($logfile, $status);
        
        if (not set_permissions($destination)) {
            carp "Unable to set permissions for $destination: $!";
        }
        
        if (not set_execute($destination)) {
            carp "Unable to make $destination executable: $!";
        }
     
        print $status . "\n";
    }
    
    my $cvs_checkin_message = "Checking $source post-compile in at " . time;
    my ($cvs_status, $cvs_message) = cvs_commit($destination, $checkin, $cvs_checkin_message, $dry);
    
    if ($checkin) {
        if (not $cvs_message) { $cvs_message = "unknown message"; }
        if (not $cvs_status)  { $cvs_status  = "unknown status";  }
        my $cvs_logtext = "CVS Check-in for $destination is $cvs_status: $cvs_message\n";
    
        write_log($logfile, $cvs_logtext);
    }
        
    return $retval;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_compile_settings([$os])
    returns Compile_program_exe, Compile_program_options based on $os
     if $os is not specified then current os is assumed
    Assumes that the compile program is in the path
=cut

sub get_compile_settings {
    my $os = shift;
       $os = check_os($os);
       
    my ($module_dir) = get_module_dir($os);
    my $compile_pgm  = "perlapp";
    my $compile_opts = "--lib $module_dir --force --exe ";
    
    return ($compile_pgm, $compile_opts);

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 perldoc_pgm($source_file, $destination_file, $dry, $logfile)
    returns 1 if successful
    Assumes the perldoc command is in the path
=cut

sub perldoc_pgm {
    my ($source, $destination, $dry, $logfile) = @_;
    my $retval = 1;
    
    if (-e $source) {
    
        my ($doc_pgm, $doc_opts) = get_perldoc_settings();
       
        my $doc_line = "$doc_pgm $doc_opts $source $destination";
        write_log($logfile, "documentation entry: $doc_line");
        print "\n\tdocumentation entry: " . $doc_line . "\n\n";
        
        if (not $dry) {
            my $status = `$doc_line`;
          
            write_log($logfile, $status);
         
            print $status . "\n";
            $retval = 1;
        }
      
    }
    else {
        carp "File $source doesn't exist\n";
        $retval = 0;
        
    }

    return $retval;        
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 get_perldoc_settings()
  return ($doc_program, $doc_options);
=cut

sub get_perldoc_settings {
  
    my $doc_pgm = "pod2text";
    my $doc_opts = "-l";
    
    return ($doc_pgm, $doc_opts);
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 cvs_commit($checkin_file, $checkin_flag, $checkin_message, $dry)
    $checkin_file    = the file to commit to cvs
    $checkin_flag    = 1 to checkin 0 to not
    $checkin_message = The message to post as the description during commit
    $dry             = 1 is a dry run, don't commit.  0 is not a dry run, commit.
    returns: ($status (0 | 1), $status message)
    Assumes the cvs command is in the path
=cut
    
sub cvs_commit {
    
    my ($checkin_file, $checkin_flag, $checkin_message, $dry) = @_;
    my ($fn, $path) = fileparse($checkin_file);
    
    if (not $checkin_file) {
        my $carpmsg = "CVS Checkin: No file specified!\n";
        carp $carpmsg;
        return (0, $carpmsg);
    }
    
    if (not -e $checkin_file) {
        my $carpmsg = "CVS Checking file $checkin_file doesn not exist!\n";
        carp $carpmsg;
        return (0, $carpmsg);
    }
    
    if (not $checkin_message) {
        $checkin_message = "Checking in $checkin_file at " . time;
    }
    
    my $cvscommand = "cvs commit -m \"$checkin_message\" ";

    my ($status, $status_message);
    if ( ($dry) or (not $checkin_flag) ) {
        $status_message = "Not checking in! Commit command is $cvscommand $fn and directory is $path\n";
        $status         = 1;
    }
    else {
        chdir $path or croak "Unable to change directory to $path: $!\n";
        $status_message = `$cvscommand $fn`;
        if (not $status_message) { $status_message = $!; }
    }

    if (not $status_message) { $status_message = "unknown"; }
    if (not $status)         { $status         = "unknown"; }
    print "CVS Status: ($status) $status_message\n";
    return ($status, $status_message);
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 set_permissions($file)
    returns 1 if successful
=cut

sub set_permissions {
    my $file = shift;
    my ($user, $group);

    if (not $file) {
        carp "set_permissions: file not specified!";
        return 0;
    }
    
    if ( (os_type() eq 'UNIX') or (os_type() eq 'LINUX') ) {
        defined($user  = getpwnam "opc_op") or carp "set_permissions: bad user";
        defined($group = getgrnam "other" ) or carp "set_permissions: bad group";
    }
    else {
        $user  = 1;
        $group = 1;
    }
    
    chown ($user, $group, $file);
    
    return 1;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 set_permissions_server($file)
    returns 1 if successful
=cut

sub set_permissions_server {
    my $file = shift;
    my ($user, $group);

    if (not $file) {
        carp "set_permissions: file not specified!";
        return 0;
    }
    
    if ( (os_type() eq 'UNIX') or (os_type() eq 'LINUX') ) {
        defined($user  = getpwnam "esm") or carp "set_permissions: bad user";
        defined($group = getgrnam "esm") or carp "set_permissions: bad group";
    }
    else {
        $user  = 1;
        $group = 1;
    }
    
    chown ($user, $group, $file);
    
    return 1;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 set_execute($file)
    returns 1 if successful
=cut

sub set_execute {
    my $file = shift;
    
    if (not $file) {
        carp "set_execute: file not specified!";
        return 0;
    }
    
    chmod ("+x", $file);
    
    return 1;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

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

=head2 DEVELOPER'S NOTES
 

=cut


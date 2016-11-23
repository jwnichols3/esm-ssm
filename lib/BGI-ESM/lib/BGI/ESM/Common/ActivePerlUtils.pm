=head1 NAME

BGI ESM Common ActiveState Perl Utilities

=head1 SYNOPSIS

This library is used to manage the activestate perl install configuration.

=head1 TODO


=head1 REVISIONS

CVS Revision: $Revision: 1.16 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-09-19   nichj   Starting
  #  2005-11-30   nichj   Added Test-Differences
  #  2005-12-06   nichj   Added Config and Log-Log4Perl
  #  2005-12-08   nichj   Added Filesys::DiskFree and Filesys::DiskUsage
  #
  #####################################################################

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::Common::ActivePerlUtils;

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use Carp;
#use MLDBM qw(DB_File Storable);
use Fcntl;                     
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(trim read_file_contents unique_list_elements os_type);
###############################################################################

###############################################################################
### Require Section ###########################################################
require Exporter;
###############################################################################

###############################################################################
### Who is this ###############################################################
our @ISA = qw(Exporter BGI::ESM::Common);
###############################################################################

###############################################################################
### Public Exports ############################################################
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    get_module_list
    get_ppm_cmd
    get_ppm_upgrade_cmd
    get_ppm_install_cmd
    get_ppm_uninstall_cmd
    get_ppm_describe_cmd
    get_ppm_search_cmd
    get_detail_cmd
    new_version_check
    upgrade_module
    uninstall_module
    install_module
    module_installed
    is_module_installable
);
###############################################################################

###############################################################################
### VERSION ###################################################################
my $VERSION = (qw$Revision: 1.16 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################

###############################################################################
# Public Methods / Functions
###############################################################################

sub get_module_list {
    my @list = qw(
        Archive-Tar
        Benchmark
        CGI
        Class-Accessor
        Class-Data-Inheritable
        Class-DBI
        Class-DBI-MSSQL
        Class-Trigger
        Class-WhiteHole
        Config
        Config-Auto
        Compress-Zlib
        Convert-ASN1
        CPAN
        Crypt-DES
        CWD
        Data-Dump
        Data-Dumper-Simple
        DB_File
        DB_File-DB_Database
        DB_File-Lock
        DBD-ADO
        DBD-ODBC
        DBI
        DBIx-MSSQLReporter
        Devel-Cover
        Devel-Coverage
        Digest-HMAC
        Digest-MD2
        Digest-MD5
        Digest-SHA1
        Env
        ExtUtils-Command
        ExtUtils-Liblist
        ExtUtils-MakeMaker
        ExtUtils-Manifest
        File-Basename
        File-CheckTree
        File-chmod
        File-Compare
        File-Copy
        File-CounterFile
        File-DosGlob
        File-Find
        File-Path
        File-Slurp
        File-Spec
        File-stat
        File-Temp
        Filesys-DiskFree
        Filesys-DiskUsage
        Font-AFM
        HTML-Parser
        HTML-Tagset
        HTML-Template
        HTML-Tree
        Ima-DBI
        IO-File
        IO-Handle
        IO-Pipe
        IO-Seekable
        IO-Select
        IO-Socket
        IO-String
        IO-Stringy
        IO-Zlib
        libwin32
        libwww-perl
        List-Util
        Logger
        Log-Log4Perl
        Mail-Sendmail
        MD5
        MLDBM
        Net-CMD
        Net-Config
        Net-DNS
        Net-Domain
        Net-FTP
        Net-hostent
        Net-IP
        Net-LDAP-Express
        Net-netent
        Net-Netrc
        Net-Nslookup
        Net-Ping
        Net-POP3
        Net-protoent
        Net-servent
        Net-SMTP
        Net-SNMP
        Net-Time
        PadWalker
        Params-Validate
        perl-ldap
        Perl6-Export
        Perl6-Form
        PerlIO
        Pod-Escapes
        Pod-Simple
        PPM3
        ppt
        Scalar-Util
        Shell
        Smart-Comments
        SOAP-Lite
        Sys-Syslog
        Test
        Test-Assertions
        Test-Differences
        Test-TestUtil
        Test-Builder
        Test-Builder-Tester
        Test-Harness
        Test-More
        Test-Pod
        Test-Simple
        Test-Soundex
        Test-Unit
        Text-Balanced
        Text-Diff
        Text-ParseWords
        Text-Tabs
        Text-Wrap
        Tie-Array
        Tie-File
        Tie-Handle
        Tie-Hash
        Tie-Memorize
        Tie-SubstrHash
        Time-Format
        Time-gmtime
        Time-HiRes
        Time-Local
        Time-localtime
        Time-tm
        Tk
        UNIVERSAL
        URI
        User-grent
        User-pwent
        utf8
        Win32-AuthenticateUser
        XML-NamespaceSupport
        XML-Parser
        XML-SAX
        XML-Simple
        XML-Writer
        XML-XPath
    );

    return \@list;
    
}


sub get_ppm_cmd {
    my $ppm_cmd = "ppm";
    
    return $ppm_cmd;
}

sub get_ppm_upgrade_cmd {
    my $ppm_cmd = get_ppm_cmd();
    return "$ppm_cmd upgrade ";
    
}

sub get_ppm_install_cmd {
    my $ppm_cmd = get_ppm_cmd();
    return "$ppm_cmd install ";
    
}
    
sub get_ppm_uninstall_cmd {
    my $ppm_cmd = get_ppm_cmd();
    return "$ppm_cmd uninstall ";
    
}

sub get_ppm_describe_cmd {
    my $ppm_cmd = get_ppm_cmd();
    return "$ppm_cmd describe ";
    
}

sub get_ppm_search_cmd {
    my $ppm_cmd = get_ppm_cmd();
    return "$ppm_cmd search ";
    
}

=head2 new_version_check($module)
    returns 1 if new version is available
=cut

sub new_version_check {
    my $module = shift;
    my $retval = 0;
    my $cmd  = get_ppm_upgrade_cmd();
    
	my $status_cmd   = `$cmd $module`;
    if (grep /new version/, $status_cmd) {
        $retval = 1;
    }
    
    return $retval;
    
}

sub uninstall_module {
    my $module = shift;
    my $retval = 0;
    my $cmd    = get_ppm_uninstall_cmd();
    
	my $status_cmd   = `$cmd $module`;
    
    if (grep /Successfully/, $status_cmd) {
        $retval = 1;
    }
    
    return $retval;
    
}


sub install_module {
    my $module = shift;
    my $retval = 0;
    my $cmd    = get_ppm_install_cmd();
    
	my $status_cmd   = `$cmd $module`;
    
    if (grep /Successfully/, $status_cmd) {
        $retval = 1;
    }
    
    return $retval;

}

sub upgrade_module {
    my $module = shift;
    my $retval = 0;
    
    if (uninstall_module($module)) {
        
        if (install_module($module)) {
            
            $retval = 1;
            
        }
        
    }
    
    return $retval;
    
}    

=head2 module_installed($module)
    Checks to see if a module is installed, if not, checks to see if it can be
     intalled on the platform.
    Returns 1 if installed, 0 if not and installable
=cut

sub module_installed {
    my $module = shift;
    my $retval = 1;
    my $cmd    = get_ppm_describe_cmd();
    
    my @status_cmd = `$cmd $module`;
    
    if (grep /not found/, @status_cmd) {
        
        print "\tModule NOT installed\n";
        
        if (is_module_installable($module)) {
            print "\t\tModule is installable\n";
            $retval = 0;
        }
        else {
            print "\t\tModule is NOT installable\n";
            $retval = 1;
        }

    }
    else {
        
        print "\tModule installed\n";
        
    }

    print "@status_cmd\n";
    return $retval;
}

sub is_module_installable {
    my $module     = shift;
    my $retval     = 0;
    my $search_text;
    my $cmd        = get_ppm_search_cmd();
    
    my @status_cmd = `$cmd $module`;
    
    #print "@status_cmd";
    
    if (os_type() eq 'WINDOWS') {
        $search_text = "MSWin32";
    }
    else {
        $search_text = "solaris"
    }
    
    if (grep /$search_text/, @status_cmd) {
        $retval = 1;
    }
    
    return $retval;
    
}

###############################################################################
### End of Public Methods / Functions #########################################
###############################################################################


###############################################################################
### Private Methods / Functions ###############################################
###############################################################################


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
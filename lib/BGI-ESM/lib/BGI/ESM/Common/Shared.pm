
=head1 NAME

BGI ESM Common Shared Methods

=head1 SYNOPSIS

This library is used in most BGI ESM programs to load a common set of methods.

=head1 REVISIONS

CVS Revision: $Revision: 1.58 $
    Date:     $Date: 2009/03/01 22:06:56 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-mm-dd   nichj   Converted to module from ssm_common.pm
  #  2005-09-09   nichj   Added copy_file
  #  2005-10-11   nichj   Added get_display_date & get_common_shared_version
  #  2005-10-20   nichj   Added print_hash_formatted, print_hash_formatted_file
  #  2005-10-27   nichj   Added LINUX to os_type()
  #  2005-11-12   nichj   Added say (Perl 6 function that prints with newline)
  #  2005-11-27   nichj   Fixed source_host_check method.
  #  2005-11-28   nichj   Updated perlpass_get to use ssm_variables instead of agent_variables
  #  2006-03-17   nichj   Added sms_alert_send
  #  2006-03-24   nichj   Updated sms_alert_send to be a named method
  #  2006-03-26   nichj   Added get_formatted_date_time
  #  2007_05-22   nichj   Updated get_hostname to validate hostname has something in it.
  #                       updated mail_alert to check for values and set defaults if not present
  #                       refined sms_alert_send/write_sms_file to better define the tmp dir location.
  #  2009-02-28   nichj   Added scalar_from_array function.
  #
  #####################################################################

=head1 TODO

  - finish packaging of common functions
  - figure out logging
  - Refactor

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::Common::Shared;
###############################################################################

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
use File::stat;
use File::Copy;
use File::Basename;
use Net::FTP;
use Mail::Sendmail;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
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
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	chk_running
	check_os
	copy_file
	dir_listing
	file_modified_younger
	flip_slashes_to_back
	flip_slashes_to_single_back
	ftp_file
	get_common_shared_version
	get_check_date
	get_display_date
	get_formatted_date_time
	get_hostname
	get_process_list
	get_service_list
	get_test_output_log
	is_process_running
	kill_process
	lc_array
	mail_alert
	matching_entries_in_arrays
	move_file
	nfs_error
	nonmatching_entries_in_arrays
	os_type
	perlpass_get
	print_array
	print_array_file
	print_hash_formatted
	print_hash_formatted_file
	process_count_running
	process_vposend_lf
	read_file_contents
	remove_array_from_array
	remove_file
	say
        scalar_from_array
	source_host_check
	sms_alert_send
	strip_comments_from_array
	test_check
	test_output_header
	test_output_footer
	trim
	unique_list_elements
	write_file_contents
);
###############################################################################

###############################################################################
### VERSION ###################################################################
our $VERSION = (qw$Revision: 1.58 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################


###############################################################################
# Public Methods / Functions
###############################################################################

=head2  os_type()

	# Description:  determines if running on Windows or UNIX
	# Returns:      'WINDOWS' or 'UNIX'
	# Requires:     n/a

=cut

sub os_type {
    my $retval;    
    my $platform = "$^O";
    chomp ($platform);
       
    if ( "$platform" eq "MSWin32" ) {
      $retval = 'WINDOWS';
    }
    elsif ( lc "$platform" eq "linux" ) {
      
      $retval = 'LINUX';
      
    }
    else {
      $retval = 'UNIX';
    }
    
    return $retval;
    
}  
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  trim($variable)

	#  use this function to strip leading spaces and trailing spaces from
	#  a variable or array

=cut

sub trim {
    my (@out) = @_;
    
    for (@out) {
      s/^\s+//;
      s/\s+$//;
    }
    
     return wantarray ? @out : $out[0];
      
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 say(text);
	prints text with newline
=cut

sub say {
	return print @_, "\n";
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_common_shared_version
	returns a scalar with the version of this module
=cut

sub get_common_shared_version {
	return $VERSION;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 unique_list_elements(@list)
	returns a reference to a list with unique elements found in @list
=cut

sub unique_list_elements {
	my @incoming_list = @_;
	my %seen = ( );
	my @uniq = ( );
	foreach my $item (@incoming_list) {
		unless ($seen{$item}) {
			# if we get here, we have not seen it before
			$seen{$item} = 1;
			push(@uniq, $item);
		}
	}
	
	return \@uniq;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2  perlpass_get($passtype)

	# Description:  Use this function to get perlpass values
	#
	# Returns:      corresponding value of $passtype
	#
=cut

sub perlpass_get {
    my $passget = shift;
    my ($retval, $passpgm);
    my $ssm_vars = ssm_variables();
    
    $passpgm = $ssm_vars->{'SSM_BIN'} . "/perlpass_get";
    
    $retval = `$passpgm $passget`;
    chomp($retval);
    
    return $retval;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 write_file_contents($filename, \@contents, $type_of_write)

	# Description:  Writes contents of \@contents to $filename in basic one-line per record form
	#               $type_of_write is:\#
	#                - append  - appends the data to the file (default)
	#                - replace - replaces the file with the contents
	#               The \@contents should have records in order and include any commented lines, etc.
	# Returns:      1 (TRUE) if successful, 0 (FALSE) if problem.
	
=cut

sub write_file_contents {
	############################
	## TODO: Refactor ##########
	############################
	my ($filename, $contents, $type_of_write) = @_;
	my  @contents      = @{$contents};
	    $type_of_write = lc $type_of_write;
	my  $type_default  = "append";
	my  $retval        = 0;
	my  $file_redirect;
	
	# Being safe with the file and contents
	chomp(@contents);    # don't want to trim the contents as the records should be formatted with leading spaces, etc.
	trim($type_of_write);
	trim($filename);

	# Basic error checking
	if (not $filename) {
		warn "\tFunction write_file_contents requires a filename.\n";
		return $retval;
	}
	
	# Default settinf for $type_of_write
	if (not $type_of_write) { $type_of_write = $type_default; }
	
	# If the file doesn't exist, then 'touch' it
	if (not -e $filename) {
		if (open FN, "> $filename") {
			close FN;
		} else {
			warn "Problem creating $filename: $!\n";
			$retval = 0;
		}
	}
	
	# establish a variable for the file redirection
	if ($type_of_write eq "replace") {
		$file_redirect = ">";
	} else {
		$file_redirect = ">>";
	}
	
	# Open the file with the proper redirection
	# Write the contents to the file
	# If there are problems with this then return 0
	if (not open FN, "$file_redirect $filename") {
		
		warn "Problem opening $filename!  $!\n";
		$retval = 0;

	} else {

		foreach my $item (@contents) {
			print FN "$item\n";
		}
		
		close FN;
		
		$retval = 1;
		
	}

	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  read_file_contents($file_to_read)

	# Description:  Reads the contents of $file_to_read into an array and returns an array with the contents
	# Returns:      array with contents of file or 0 if error.
	# Requires:     n/a

=cut

sub read_file_contents {
	my $file_name    = shift;
	my (@return_array, $CONFIG_FILE_TO_READ);
	
	if (-e $file_name) {
		open  $CONFIG_FILE_TO_READ, "< $file_name" or carp "Unable to open $file_name: $!";
		
		@return_array = <$CONFIG_FILE_TO_READ>;
		
		close $CONFIG_FILE_TO_READ or carp "Unable to close $file_name: $!";
		
		return @return_array;
	
	}
	else {
		
		carp "File $file_name does not exist!";
		return 0;
		
	}
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  strip_comments_from_array(@array)

	# Description:  This fuction strips the lines from an array that are blank or start with: #, ;, '
	# Returns:      array without commented lines
	# Requires:     n/a

=cut

sub strip_comments_from_array {
	my @incoming_array = @_;
	my @outgoing_array;
	my $counter        = 0;
	my ($blank, $comment, $line);
	
	for $line (@incoming_array) {
			
		chomp($line);
		
		trim($line);
		
		if ($line eq "")    { next; }

		$comment       =  (substr($line, 0, 1));
	
		if ( ($comment ne "#") &&
				 ($comment ne ";") &&
				 ($comment ne "'")    ) {

					push @outgoing_array, $line;

		}

	}
	
	return @outgoing_array;
	
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_process_list()

	# Description:  returns a reference to an array with the process list
	# Returns:      array with contents of file or 0 if error.
	# Requires:     n/a

=cut

sub get_process_list {
	return _read_process_list();
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_service_list()

	# Description:  returns a reference to an array with the process list
	# Returns:      array with contents of file or 0 if error.
	# Requires:     n/a

=cut

sub get_service_list {
	return _read_service_list();
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 file_modified_younger($filename, $threshold)

	# Description:  tests the file modified time (using File::stat) against $threshold
	# Returns:      returns 1 (TRUE) if younger, 0 (FALSE) if older
	# Requires:     n/a

=cut

sub file_modified_younger {
	my $filename  = shift;
	my $threshold = shift;
	my $retval    = 0;
	my $now       = time();
	my ($stats, $file_modified_time);
	
	if (-e $filename) {
		$stats              = stat($filename);
		$file_modified_time = $stats->mtime;
		
		## Calc the difference in time between now and the file modified time
		if (($now - $file_modified_time) <= $threshold) {
			$retval = 1;
		} else {
			$retval = 0;
		}
		
	} else {
		$retval = 0;
		
	}
	
	return $retval;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  is_process_running($process_name_to_check)

	# Description:  pulls the process list to see if there is a match.  This is case and complete word sensitive
	# Returns:      returns 1 (TRUE) if running, 0 (FALSE) if not
	# Requires:     1 if the process is running

=cut

sub is_process_running {
	my $process      = shift;
	my $process_list = get_process_list();
	
	if (grep /\b$process\b/, @{$process_list}) {
		return 1;
	} else {
		return 0;
	}
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 processes_count_running($process_to_check)

	# Description:  searches the process_list for a count of $process_to_check
	# Returns:      returns the number of processes found running
	# Requires:     n/a

=cut

sub process_count_running {
	my $process      = shift;
	my $process_list = get_process_list();
	
	my @process_count = grep /\b$process\b/, @{$process_list};
	
	return scalar(@process_count);
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  kill_process(@process_list)

	# Description:  kills any processes that match entries in @process_list
	# Returns:      returns 1 (TRUE) if successful, 0 if not
	# Requires:     n/a

=cut

sub kill_process {
    my @process_list       =  @_;                        # the list of processes that should be killed
    my $retval             =  0;                         # set to 1 if there is an error
    my $current_pid        =  $$;                        # the current program PID
    my ($pid_chk, $pid, $count, $status);
    
    #if ($debug)                                        { print " The current program PID is $current_pid\n"; }
    
    foreach my $kill_process (@process_list) {
        
      #if ($debug_extensive)                           { print " kill_process function: the process list...\n\n";
      #                                                  foreach $item (@process_list) { print " $item\n"; }
      #                                                }
    
      chomp($kill_process);
       
      $pid = _pid_extract($kill_process);
         
      if ( ($current_pid ne $pid) and ($pid ne "0") and ($pid) ) {
        print "Killing $pid.\n";
        
        if (_kill_pid($pid)) {
          $retval = 1;
        }
        
      }
          
    }
    
    return $retval;
    
    ##################################################
    sub _pid_extract {
      my $kill_process = shift;
      my $os = os_type();
      my ($pid_chk, $pid);
      
      if ($os eq 'WINDOWS') {
        $pid_chk = substr($kill_process,25,1);
    
        if ( "$pid_chk" eq " " ) {
          
           $pid  = substr($kill_process,21,4);
           
        }
        else {
          
           $pid  = substr($kill_process,21,5);
           
        }
        
      }
      else {
        
        $pid = `echo $kill_process |awk '{print \$2}'`;
      
      }
        
      return $pid;
      
    }
    ###################################################
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 copy_file($from_file, $to_file)
  calls _copy_file and returns value from that
=cut

sub copy_file {
    my ($from_file, $to_file) = @_;
    
    return _copy_file($from_file, $to_file);
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 remove_file($file_to_remove)
  calls _remove_file and returns value from that
=cut

sub remove_file {
    my ($file_to_remove) = shift;
    
    return _remove_file($file_to_remove);
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 move_file($from_file, $to_file, ['replace'])
	returns 1 if successful, otherwise 0
=cut

sub move_file {
	my ($from_file, $to_file, $option) = @_;
	
	# Safety check #1: Does the from file exist
	if (not -e $from_file) {
		carp "move_file: From file $from_file does not exist!";
		return 0;
	}
	
	# Safety check #2: 'replace' is specified on in the method
	if (lc $option eq "replace") {
		if (-e $to_file) {
			if (not remove_file($to_file)) {
				return 0;
			}
		}
	}
	# Safety check #3: 'replace' is NOT specified on in the method
	else {
		if (-e $to_file) {
			carp "move_file: The to file $to_file already exists and the 'replace' option is not set. ot moving!";
			return 0;
		}
	}

	# Perform the copy, return 0 if anything fails.
	if ( copy_file($from_file, $to_file) ) {
		if ( remove_file($from_file) ) {
			return 1;
		}
		else {
			carp "There was a problem removing $from_file: $!";
			return 0;
		}
	}
	else {
		carp "There was a problem copying $from_file to $to_file: $!";
		return 0;
	}
	
	# If we reach here then something is wrong.
	return 0;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 test_check($opt_flag_1, $opt_flag_2)

=cut

sub test_check {
    my ($flag1, $flag2) = @_;
    
    if ($flag1 or $flag2) {
        return 1;
    }
    else {
        return 0;
    }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_hostname()
	returns scalar with the hostname
	Possible modifications include determining the core hostname
=cut

sub get_hostname {
	my $hostname;
	
	if (os_type() eq 'WINDOWS') {
		$hostname = $ENV{'COMPUTERNAME'};
	}
	else {
		$hostname = $ENV{'HOSTNAME'};
        if (not $hostname) {
            $hostname = `hostname`;
        }
	}
	
    if (not $hostname) {
        $hostname = "unknown";
    }
    
	chomp($hostname);
	
	return $hostname;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  ftp_file($from_file, $to_server, $to_dir, $to_file, $ftp_user, $ftp_pass)

 #  This will return FALSE if there is a problem, TRUE if successful.

=cut

sub ftp_file {
    my 	(
              $from_file,
              $to_server, $to_dir, $to_file,
              $to_user, $to_pass
          ) = @_;
    
    my $retval         = 1;
    my ($ftp);
    
    if ( (not $from_file) or
         (not $to_server) or
         (not $to_dir)    or
         (not $to_file)   or
         (not $to_user)   or
         (not $to_pass)     ) {
      
          carp "ftp_file: not all required parameters are set!\n";
          return 0;
    }
    
    if (not $ftp=Net::FTP->new($to_server,Timeout=>240)) {
      
      warn "Can't connect to $to_server: $!\n";
      $retval = 0;
    
    } else {
      
      if (not $ftp->login($to_user, $to_pass)) {
        
        warn "Can't login to $to_server: $!\n";
        $retval = 0;
        
      } else {
        
        if (not $ftp->cwd("$to_dir")) {
    
          warn "Unable to change directories to $to_dir: $!\n";
          $retval = 0;
          
        } else {
          
          if (not $ftp->put("$from_file","$to_file")) {
    
          warn "Unable to send file $to_file: $!\n";
          $retval = 0;
          
          } else {
            
            $ftp->quit();
            
          }
        }
      }
    }
    
    return $retval;
  
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 check_os($os)
    returns the OS based on the current OS if $os is not set
=cut

sub check_os {
    my $os = shift;
    
    if (not $os) {
        return os_type();
    }
    else {
        return $os;
    }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  mail_alert($from, $to, $cc, $subject, $body)

 #  This will return FALSE if there is a problem, TRUE if successful.
 #  $to is required

=cut

sub mail_alert {
    
    my ($from, $to, $cc, $subject, $body) = @_;
    my $retval;
    my $mailserver = "us-exc-mailhost";
    
    if (not $to)      { return 0; }
    if (not $from)    { $from = "vpo\@barclaysglobal.com"; }
    if (not $cc)      { $cc = ""; }
    if (not $body)    { $body = ""; }
    if (not $subject) { $subject = ""; }
    
    my %mail = (
                 smtp    => "$mailserver",
                 To      => "$to",
                 From    => "$from",
                 Cc      => "$cc",
                 Message => "$body",
                 Subject => "$subject"
               );
    
    if (sendmail(%mail)) {
      
      $retval = 1;
      
    }
    else {
      
      print "Mail::Sendmail::error\n";
      $retval = 0;
      
    }
    
     return $retval;
   
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_display_date()
	returns a scalar with the display date
=cut

sub get_display_date {

	return localtime;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


sub get_formatted_date_time {
    my ($seconds, $minute, $hour, $day, $month, $year) = (localtime)[0,1,2,3,4,5];
    
    $month = $month + 1;
    $year  = $year  + 1900;
    
    my $retval = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $minute, $seconds);
    
    return $retval;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_check_date()
	returns a scalar with the check date
=cut

sub get_check_date {
	my ($chk_dw, $chk_mon, $chk_day, $chk_time, $chk_year)  = split(/ /,get_display_date());
	return "$chk_dw $chk_mon $chk_day";
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  dir_listing(@directory or directories)

	# Return:   \@file_list - reference to array
	#  This function is basic in nature as it returns an array with a list
	#  of files in the @directory/directories.  It does NOT return the full path
	#  to the files.

=cut


sub dir_listing {
  
	my @dir_names = @_;
	my (@file_list, $DIRECTORY_NAME, $file);
	
	#print "\n\tdir_listing dir_names\n";
	#print Dumper \@dir_names;

	for my $directory (@dir_names) {
	  
		opendir  (DIRECTORY_NAME, "$directory") or carp "Unable to open $directory: $!";
	  
		while ($file=readdir DIRECTORY_NAME) {
			
			push (@file_list, "$file");
		  
		}
	  
		closedir (DIRECTORY_NAME) or carp "Unable to close $directory: $!";
	  
	}
	
	return \@file_list;
  
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  matching_entries_in_arrays(\@array1, \@array2, $case_sensitive)

	#  returns: array with matching elements.
	#
	#  notes:
	#   You have to call this array using references to the two arrays (\@).
	#   case_sensitive can be: "yes", "no", TRUE, FALSE

=cut

sub matching_entries_in_arrays {
	my (@array1, @array2);
	my $array1 = shift;
	my $array2 = shift;
	my $case   = shift;
	my @intersect_array;
  
	@array1    = @$array1;
	@array2    = @$array2;
  
	# # # # # # #
	# Lower case arrays if not case sensitive (default behavior)
	# # # # # # #
	if ( lc $case eq "no" || not $case ) {
		@array1 = lc "@array1";
		@array2 = lc "@array2";
	}
  
	@intersect_array = sort(array_union_diff_intersect(\@array1, \@array2, "intersect"));
	
	return @intersect_array;
  
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  nonmatching_entries_in_arrays(\@array1, \@array2, $case_sensitive)
	#  returns: array with nonmatching elements.
	#
	#  notes:
	#   You have to call this array using references to the two arrays (\@).
	#   case_sensitive can be: "yes", "no", TRUE, FALSE
	#

=cut

sub nonmatching_entries_in_arrays {
	my (@array1, @array2);
	
	my $array1 = shift;
	my $array2 = shift;
	my $case   = shift;
	my @diff_array;
	
	@array1    = @$array1;
	@array2    = @$array2;
	
	 # # # # # # #
	 # Lower case arrays if not case sensitive (default behavior)
	 # # # # # # #
	if ( lc $case eq "no" || not $case ) {
	  @array1 = lc "@array1";
	  @array2 = lc "(@array2";
	}
	
	@diff_array      = sort(array_union_diff_intersect(\@array1, \@array2, "diff"));
  
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  remove_array_from_array(\@remove_list, \@master_list, $case_sensitive)

 #  returns: array with removed elements.
 #
 #  notes:
 #   You have to call this array using references to the two arrays (\@).
 #   case_sensitive can be: "yes", "no", TRUE, FALSE

=cut

sub remove_array_from_array {
	my (@array1, @array2);
	my $array1 = shift;
	my $array2 = shift;
	my $case   = shift;
	my (@full_union_array, @final_diff_array);
  
	@array1    = @{$array1};
	@array2    = @{$array2};
	
	 # # # # # # #
	 # Lower case arrays if not case sensitive (default behavior)
	 # # # # # # #
	if ( lc $case eq "no" || not $case ) {
	  @array1 = lc "@array1";
	  @array2 = lc "@array2";
	}
	
	@full_union_array = sort(array_union_diff_intersect(\@array1, \@array2, "union"));
	@final_diff_array = sort(array_union_diff_intersect(\@full_union_array, \@array2, "diff"));
	
	return @final_diff_array;
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  array_union_diff_intersect(\@array1, \@array2, $type)

	#  returns: array with requested elements.
	#
	#  notes:
	#   You have to call this array using references to the two arrays (\@).
	#
	#   $type should be set to one of the following:
	#         u[nion]
	#         i[intersection]
	#         d[ifference]
	# #
	# # Pulled from http://perl.active-venture.com/pod/perlfaq4-dataarrays.html
	# #

=cut


sub array_union_diff_intersect {
	my (@array1, @array2);
	my $array1 = shift;
	my $array2 = shift;
	my $type   = shift;
	   $type   = lc $type;
	my ($element, %count);
	
	@array1    = @$array1;
	@array2    = @$array2;
	
	my (@union, @intersection, @difference);

	%count = ();
	
	foreach $element (@array1, @array2) { $count{$element}++ }
	
	foreach $element (keys %count) {
	
	  push @union, $element;
	  push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element;
	  
	}
	
	if    ( $type =~ /^u/     ) { return @union        }
	elsif ( $type =~ /^i/     ) { return @intersection }
	elsif ( $type =~ /^d/     ) { return @difference   }
	else                        { return 0;            }
	
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 print_array(@array);

=cut

sub print_array {
   my @incoming_array = @_;
   my $line           = "";
   
   foreach $line (@incoming_array) {
      chomp($line);
      print "$line\n";
   }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 print_hash_formatted(\%hash_to_print)
	
	This prints the \%hash_to_print with a format

=cut

sub print_hash_formatted {
    my $hash = shift;
    my %hash = %$hash;
    my $k;
    
    
    $~ = 'HASH_OUT_HEADER';
    write();
    $~ = 'HASH_OUT';
    
    foreach $k (sort keys %hash) {
      write();
    }
  
  
format HASH_OUT_HEADER =
- - - Key - - - - - - - - - - - - - - - - -  - - - Value - - - - - - - - - - - - - - - - - - - - - - - - - -
.

format HASH_OUT =
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$k,                                          $hash{$k}
.
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 print_array_file(FILEHANDLE, \@array_to_print)

	This prints the \%hash_to_print to a file, defined in $filehandle with a format

	example:
	@test_array  = ("one, "two", "three);

	open LOGFILE, "> c:/code/templog.txt" || warn "Unable to open $!";

	print_array_file(LOGFILE, \%@est_array);

=cut


sub print_array_file {
	my $FH             = shift;
	my $incoming_array = shift;
	my @incoming_array = @$incoming_array;
	my $item;
	
	if (not $FH) {
		carp "print_array_file: file handle not defined!";
		return 0;
	}
	
	foreach $item (@incoming_array) {
		chomp($item);
		print $FH "$item\n";
	}
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 print_hash_formatted_file(\%hash_to_print)

	This prints the \%hash_to_print to a file, defined in $filehandle with a format
	
	example:
	%test_hash  = (
				 'one'    => "1",
				 'two'    => "2",
				 'three'  => "3",
				 'four'   => "4",
				 'five'   => "5",
				 'six'    => "6"
				);
	
	
	open LOGFILE, "> c:/code/templog.txt" || warn "Unable to open $!";
	
	print_hash_formatted_file(LOGFILE, \%test_hash);
	
=cut

sub print_hash_formatted_file {
	my $FH   = shift;
	my $hash = shift;
	my %hash = %$hash;
	my $k;
	
	if (not $FH) {
		carp "print_hash_formatted_file: file handle not defined!";
		return 0;
	}
	
	my $oldfh = select STDERR;
	
	select($FH);
	
	$~ = 'HASH_OUT_HEADER_FILE';
	write();
	
	$~ = 'HASH_OUT_FILE';
	
	foreach $k (sort keys %hash) {
		write();
	}
	
	select($oldfh);
	
format HASH_OUT_HEADER_FILE =
- - - Key - - - - - - - - - - - - - - - - -  - - - Value - - - - - - - - - - - - - - - - - - - - - - - - - -
.

format HASH_OUT_FILE =
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$k,                                          $hash{$k}
.
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 scalar_from_array(\@array, $separator)
    This takes an array reference and creates a scalar that is separated by the $separator
=cut
sub scalar_from_array ($$) {
    my $array_to_combine = shift;
    my $separator = shift;
    my @array_to_combine = @$array_to_combine;
    my $retval;
    my $i = 1;
    
    if (not $separator) { $separator = ","; }
    
    foreach my $element (@array_to_combine) {
        if ($i == 1) {
            $retval = $element;
        }
        else {
            $retval = $retval . $separator . $element;
        }
        $i++
    }
    
    return $retval;
}

=head2 test_output_header( prefix or identifier )
	This creates the test log file and inserts a header.
	The name of the file is identified by the prefix
	and is named $ssm_vars->{'SSM_LOGS'} . "/ssm-test-<identifier>.log";
=cut

sub test_output_header {
	my $prefix = shift;
	
	if (not $prefix) {
		carp "test_output_header: prefix variable is not defined!";
	}
	
	my $test_out_log = get_test_output_log($prefix);
	
	if (-e $test_out_log) {
		carp "Warning: overwriting existing $test_out_log!";
	}
	
	my ($TEST_LOG);
	my $display_date = get_display_date();
	
	open  $TEST_LOG, "> $test_out_log" or croak "Unable to open $test_out_log: $!";
	
	print $TEST_LOG "=== Starting test output from $0 at $display_date\n\n";
	#print $TEST_LOG " Calling from $print_version\n";
	
	close $TEST_LOG or croak "Unable to close $test_out_log: $!";
	
	return 1;
	
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 test_output_footer( prefix or identifier )
	This creates the test log file and inserts a header.
	The name of the file is identified by the prefix
	and is named $ssm_vars->{'SSM_LOGS'} . "/ssm-test-<identifier>.log";
=cut

sub test_output_footer {
	my $prefix = shift;
	my $direct = ">>";
	
	if (not $prefix) {
		carp "test_output_footer: prefix variable is not defined!";
	}
	
	my $test_out_log = get_test_output_log($prefix);
	
	if (not -e $test_out_log) {
		carp "test_output_footer: warning! $test_out_log doesn't exist... creating!";
		$direct = ">";
	}
	
	my ($TEST_LOG);
	my $display_date = get_display_date();
	
	open  $TEST_LOG, $direct, "$test_out_log" or croak "Unable to open $test_out_log: $!";
	
	print $TEST_LOG "===  Ending  test output from $0 at $display_date\n\n";
	#print $TEST_LOG " Calling from $print_version\n";
	
	close $TEST_LOG or croak "Unable to close $test_out_log: $!";
	
	return 1;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head get_test_output_log($prefix)
	returns the logfile name based on the prefix
=cut

sub get_test_output_log {
	my $prefix = shift;
	return _test_output_log($prefix);
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 process_vposend_lf($vposend_message_in_file_format, $test, $prefix)

	#  use this function to send the vposend message
	#  nichj: this will take the $message input in the format of a SSM logfile
	#   split the message apart at 'vposend_options:' and sendrun vposend -f
	#   with the everything to the right of 'vposend_options:'
	#  this will also write the entry to the ssm.log file for audit/troubleshooting

=cut


sub process_vposend_lf {
  
    my $message        = shift;
    my $test           = shift;
	my $prefix         = shift;
	
	my $ssm_vars       = ssm_variables();
	
    my $dummy          = "";
    my $vposend_params = "";
    my $vposend        = $ssm_vars->{'SSM_BIN'} . "/vposend";
	my $SSM_LOG        = $ssm_vars->{'SSM_LOGFILE'};
	
    my $extension      = "";
    my $open_method    = ">>";
	
	my $status;
    
    if (os_type() eq 'WINDOWS') { $extension = ".exe"; }
	
	$message =~ s/\%/ percent/g;

    $vposend = $vposend . $extension;
    
    if (not -e $vposend) {
		croak "ERROR! Unable to find $vposend. Exiting.";
    }
   
    if ($test) {
        $status = _process_vposend_test($message, $prefix);
    }
    else {
        
        #if ($debug)           { print "\n * * * processing error: $message\n"; }
        #if ($debug_extensive) { print "\n\tWriting message to $SSM_LOG\n";     }
        
        if (not -e $SSM_LOG) { $open_method = ">"; }
        
        open  (VPOSEND, "$open_method $SSM_LOG") or warn "Unable to open $SSM_LOG\n";
        print  VPOSEND ("$message\n");
        close (VPOSEND);
        
        ($dummy, $vposend_params) = split(/vposend_options:/, $message);
		
		if (not $vposend_params) {
			$vposend_params = trim($message);
		}
        
        $vposend_params           = trim($vposend_params);
        
        #if ($debug_extensive) { print "\n\t*** vposend params: $vposend_params\n"; }
        
        $status = `$vposend -f "$vposend_params"`;
        
        #if ($debug_extensive) { print "\tvposend status: $status\n"; }
        
    }
 
   return 1;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  nfs_error($nfs_error_file)
	 Returns:
	  1 (TRUE) if there is a problem, 0 (FALSE) if everything okay.

	 Purpose:
	  used on UNIX systems (will return FALSE if run on a Windows system)
	  runs the df.cmd $nfs_error_file file
	  runs a "nfs_error.sh-$nfs_error_file" command in background
	   if the nfs_error.sh cmd finishes it will remove the $nfs_error_file

	  Sleep a few seconds then see if the nfs_error_file still exists
	   if it does, then sleep again
	   if it doesn't then return FALSE
	   if the nfs_error_file still exists after a second loop then
	   delete the nfs_error_file and return TRUE

	 Dev notes: nichj: the nfs_error_file is passed so that if multiple
	   programs use this the file name can be unique.


=cut


sub nfs_error {
	
	my $ssm_vars       = ssm_variables();
	my $SSM_BIN        = $ssm_vars->{'SSM_BIN'};
	my $nfs_error_file = shift;
	my $sleep_time     = 10;
	my $loops          = 3;
	my $PROBLEM        = 1;
	my $OKAY           = 0;
	my $counter        = 0;
	my $nfscheck       = "$SSM_BIN/nfs_error.sh";
	my ($forked_pid, @forked_process);
	 
	 #
	 # If the OS is Windows then return FALSE
	 #
	if ( os_type() eq 'WINDOWS' ) {
		return $OKAY;
	}
	
	print " The nfs error file is $nfs_error_file\n";
	 
	if (not $nfs_error_file) {
		print " nfs error file is blank, generating temporary file\n";
		
		$nfs_error_file = "/tmp/vpo_nfserror" . time;
	}
	  
	 
	 # Clean up residual files
	 # usually these files will be cleaned up by this program; however, if it aborts abnormally then
	 #  they might still be there.
	 #
	if (-e "$nfs_error_file") {
		print " The file $nfs_error_file still exists.  Removing\n";
		unlink "$nfs_error_file";
	}
	 
	print " \nRunning the $nfscheck command\n";
	 
	# call the df command and place it in the background.
	#  The df command will create the $nfs_error_file and place the PID for that command
	#  as the only line.
	#
	# Once the df.cmd finishes it will erase the temorary file, signalling a successful completion.
	system"($nfscheck \"$nfs_error_file\" \&)";
	 
	# sleep one second to allow the df.cmd command to create the temporary file.
	#
	sleep 1;
	 
	# get the forked process from the temporary file
	#
	@forked_process = read_file_contents("$nfs_error_file");
	$forked_pid     = $forked_process[0];
	 
	print " \nThe forked df process is $forked_pid\n";
	print " \nStarting the loop\n";
	
	# Loop for a period of time and check for the removal of the temporary file.
	#
	for ($counter = 1; $counter <= $loops; $counter++) {
	  
		print "  \n\nLoop $counter times, sleeping " . $counter*5 . " seconds\n";
	  
		sleep (5 * $counter);
		  
		if (not -e "$nfs_error_file") {
			return $OKAY;
		}
		
	}
	 
	# Getting to here means the df.cmd file has hung, so we need to kill the child pid, erase the temp file
	#  and return PROBLEM
	print " \nKilling process $forked_pid\n\n";
	kill -9, $forked_pid;
	return $PROBLEM;
	 
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  chk_running($process_name_to_check, $???, $???)

	use this function to determine is a monitor is already running
	based off the passed monitor name

	This returns number of processes if more than one process is running

	2005-03 nichj: restructured this function for visual flow.
				   converted kill commands to function
	2005-11-16 - nichj - coverted to module.

   TODO
	- Needs refactoring

=cut


sub chk_running {
    
    my $return_val     =  0;              # value to return to calling program
    my $chk_process    =  shift;          # 
    my $send_vpo_msg   =  shift;          # set to ??? if a message should be sent, default = yes
	my $retval         =  1;
	
	my (
		@process_view, @process_chk, @process_found, $process_found,
		@shell, @left_over_processes, $kill_status, 
	   );
    
    if ( not $send_vpo_msg) {
		$send_vpo_msg  =  "Y";
    }
    
    #if ($debug)                                       { print "Process = $chk_process Send = $send_vpo_msg Times = $chk_times \n"; }
    
    
    my $running_count = process_count_running($chk_process);
    
    if ($running_count > 2) {
    
        @process_view     = get_process_list();
        
        my @process_chk   =  grep(/$chk_process/, @process_view);   # process_chk is ???
        my $process_found += @process_chk;                          # process_found is ???
        
        #if ($debug) {
        #                                                   print "Checking for $chk_process.\nFound @process_chk \n\n ";
        #  if ($debug_extensive)                          { print " @process_view \n"; }
        #}
        
        $process_found --;                                 # # decrement the processes found by one to account for the current program
        
        #if ($debug)                                       { print "Number of $chk_process processes running \= $process_found\n"; }
        
        if ($process_found le 0) {                         # # If the processes found are equal to or less than zero it is good to go.
        
          #if ($debug)                                    { print "Ok to Run\n"; }
          
           # # Replacing this functionality with status_report();
           #if ( -e "$process_running" ) {                  # # If the $process_found file exists then remove it.
           #  
           #   if ($debug)                                 { print "Removing Process Runing trigger file $process_running\n"; }
           #   
           #   unlink "$process_running";
           #   unlink "$process_running_time";
           #   
           #}
          
        }
        else {
        
           #
           # Kill the running process
           #
           @shell = grep /.sh/, @process_chk;
           @left_over_processes = nonmatching_entries_in_arrays(\@shell, \@process_chk);
           #if ($debug) { print "\nchk_running: left over process list\n";
           #              print_array(@left_over_processes);
           #}
           
            if (@left_over_processes gt 0) {
                $kill_status = kill_process(@left_over_processes);      # # Kill the offending processes
                
                #if ($debug)                                    { print "kill_status = $kill_status.\n"; }
                
                croak "Error with program: Multiple instances running.";
                
            }
      
        }
        
    }
    
    return $retval;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  source_host_check($source_host)

	returns: 1 if source host, 0 if not
	
	if $source_host is not defined, assume 1
	
	If the $host_name is not blank and the hostname is
	 not the same then return 0,
	 else return 1 (match = true, no source_host specified, or Windows)
	Note: this only works on UNIX at this time
	Requires hostalias executable

=cut

sub source_host_check {
    my $source_host  = shift;
    my $return_var   = 1;
    my ($chk_hostname, $found);
	
	if ( (not $source_host) or (os_type() eq 'WINDOWS') ) {
		return 1;
	}
    
	my $ssm_vars      = ssm_variables();
	my $SSM_BIN       = $ssm_vars->{'SSM_BIN'};
	my $hostalias_cmd = "$SSM_BIN/hostalias";

	if (-e $hostalias_cmd) {
		$chk_hostname = `$hostalias_cmd $source_host`;
	}
	else {
		carp "Unable to find executable $hostalias_cmd!";
		return 1;
	}
	
	#
	# hostalias returns the word FALSE or TRUE.
	# check the returned string for TRUE.  If it is there return 1, otherwise return 0
	#
	$found = index($chk_hostname, "TRUE");

	if ( $found ge 0 ) {
	  
	   $return_var = 1;

	}
	else {

	   $return_var = 0;

	}
	   
    return $return_var;
    
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 flip_slashes_to_back($entry)

	Description:  flips the slashes from / to \\ in $entry
	Returns:      $entry with flipped slashes
	Requires:     

=cut


sub flip_slashes_to_back {
	my $entry = shift;
	my $os    = os_type();
	
	# Don't do this for UNIX systems...
	if ($os ne 'WINDOWS') {
		return $entry;
	}
	
	# first reduce any double / to single (using # as delimiter for readability)
	$entry =~ s#/{2}#/#g;
	
	# change all \ to \\
	$entry =~ s#\\#\\\\#g;
	  
	# now change all / to \\
	$entry =~ s#/#\\\\#g;
	
	# now make sure there aren't any \\\\
	$entry =~ s#\\{4}#\\\\#g;
	
	# now make sure there aren't any \\\
	$entry =~ s#\\{3}#\\\\#g;
	
	return $entry;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 flip_slashes_to_single_back($entry)

	Description:  flips the slashes from / to \\ in $entry
	Returns:      $entry with flipped slashes
	Requires:     

=cut


sub flip_slashes_to_single_back {
	my $single_entry = shift;
	
	# Don't do this for UNIX systems...
	if (os_type() ne 'WINDOWS') {
		return $single_entry;
	}
	
	#first get the slashses swapped around
	$single_entry = flip_slashes_to_back($single_entry);
	
	#change all \\ to \
	$single_entry =~ s#\\\\#\\#g;
	
	return $single_entry;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  sms_alert_send({ sms_number=>$sms_phone_number, message=>$message_to_send })
 # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
 #  Call this function when you want to send a message via SMS
 #  It returns TRUE if successful, FALSE if not.
 #
 #  ********************************************
 #  *** This requires Net::FTP to be loaded. ***
 #  ********************************************
 #
 # -------------------------------------------------------------------

=cut

sub sms_alert_send {
    my ($arg_ref) = @_;
    
    my $sms_number                = _not_blank($arg_ref->{sms_number});
    my $message                   = _not_blank($arg_ref->{message});

    my $retval       = 1;
    my @sms_info     = ($sms_number, $message);
     
    my $ftp_server   = "esm";
    my $user         = "esm_ftp";
    my $pass         = "HYPertext01";
    my $destdir      = "/sms";
    
    my $FROM_TMPFILE = write_sms_file(@sms_info);
    my $TO_TMPFILE   = basename($FROM_TMPFILE);
    
    if (not ftp_file($FROM_TMPFILE, $ftp_server, $destdir, $TO_TMPFILE, $user, $pass)) {
      $retval = 0;
    }
    else {
    
      print "ftp of $FROM_TMPFILE to $ftp_server\:$destdir/$TO_TMPFILE successful\n";
    
    }
    
    unlink "$FROM_TMPFILE";
    
    return $retval;
    
    # = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 
    # Beginning of sub-Functions
    # = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 

     
    # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
    # Function: generate_sms_temp_file()
    #  this function generates a temporary file name based on the
    #  hostname, epoch time, and a randomly genrated number
    # -------------------------------------------------------------------
    sub generate_sms_temp_file_name {
            my ($retval, $timefile, $rnd);
            
            # #
            # # generate a file based on $hostname and epoch time and random number
            # #
            $timefile = time;
            $rnd      = int( rand(510) );
            my $HOSTNAME = get_hostname();
            
            
            $retval   = lc "$HOSTNAME" . "$timefile" . "$rnd";
            
            return $retval;
            
    }
    # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

    # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
    # Function: write_sms_file(@array_to_write_to_file)
    #
    # # The incoming array is made up elements which will be written to the temp file.  Each
    # #  element will be written to each line.
    # #  
    # # The temp file name will created, populated, then the temp file name will be returned
    # #  to the calling program.
    # #
    # -------------------------------------------------------------------
    sub write_sms_file {
            my @incoming_data = @_;
            my $ssm_vars      = ssm_variables();
            my $ssm_tmp       = $ssm_vars->{'SSM_TMP'};
    if ($ssm_tmp eq ".") { $ssm_tmp = _os_temp(); }
    if (not -w $ssm_tmp) { $ssm_tmp = _os_temp(); }
            my $tmpfile       = "$ssm_tmp/" . generate_sms_temp_file_name();
            my $retval        = $tmpfile;
            my $item;
    my $writeable     = 1;
            
    if (not -w "$ssm_tmp") {
              
        warn "Error! unable to write $tmpfile.\n";
        $writeable = 0;
        $retval    = 0;
        
            }

    if ($writeable) {
              
                    open  (TMPFILE, ">$tmpfile");
                    foreach $item (@incoming_data) {
                            print TMPFILE "$item\n";
                    }
                    
                    close (TMPFILE);
            }
            
            return $retval;
              
    }
    # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

    # = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 
    # End of sub-Functions
    # = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = 

}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################

=head2 _process_vposend_test($message, $prefix)

=cut


sub _process_vposend_test {
    my $message       = shift;
	my $prefix        = shift;
    my $logfile       = get_test_output_log($prefix);
    my $LOGFILE;
    my $display_time  = get_display_date();
    
    if (not -e $logfile) {
		my $status = test_output_header($prefix);
		#open  $LOGFILE, "> $logfile"  or warn "Unable to open $logfile: $!\n";
		#print $LOGFILE "=== Starting Debug from $0 at $display_time\n\n";
    }
    
	open  $LOGFILE, ">> $logfile" or warn "Unable to open $logfile: $!\n";

    print $LOGFILE "$display_time SSM test output __TEST__ " . $message . "\n";
    
    close $LOGFILE or warn "Unable to close file $logfile: $!";

    return 1;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head _get_test_output_log($prefix or descriptor)

=cut

sub _test_output_log {
	my $prefix = shift;
	my $ssm_vars = ssm_variables();
	
	return $ssm_vars->{'SSM_LOGS'} . "/ssm-test-" . $prefix . ".log";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _read_process_list()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _read_process_list()
	# Description:  the ps command can be ugly if run too many times, so this
	#                will look for a file called process_list and if it is present, not empty and
	#                younger than $file_access_threshold it will use the contents of the file; otherwise,
	#                the OS-specific ps command will run and write the results into process_list
	# Returns:      reference to array with the process list
	# Requires:     n/a
  # -------------------------------------------------------------------

=cut

sub _read_process_list {
	my $agent_vars            = agent_variables();
	my $ssm_vars              = ssm_variables();
	my $process_list_file     = $ssm_vars->{'SSM_LOGS'} . "/process_list";
	my $file_access_threshold = 120; # Change this to adjust the age of the process list file
	my $retry_threshold       = 3;   # The retry count to writing the process_list_file
	my (@process_list, $counter);
	
	# Check for the process list file, see if it is younger than the threshold, if it is not empty. If these are true, read the file.
	#  Validate the array has contents and if so, return the reference to the array.
	if (-e $process_list_file) {
		#print "\t\tFound $process_list_file\n";
		if (file_modified_younger($process_list_file, $file_access_threshold)) {
			#print "\t\t$process_list_file is younger than $file_access_threshold\n";
			@process_list = read_file_contents($process_list_file);
			chomp(@process_list);
			if (@process_list > 0) {
				#print "\t\tThe read of process_list is good and the count is " . @process_list . "\n";
				return \@process_list;
			}
		}
	}
	
	## If this section of code is being called then 
	##  the process list file is too old and/or empty OR the read of the process list file went sour
	@process_list = _get_running_processes($agent_vars);
	
	## Do this three times before bailing.  We have what we need, but not writing the process_list_file isn't crucial to success.
	for ($counter = 1; $counter <= $retry_threshold; $counter++) {
		## Double check the modified time on the process_list in case there are multiple programs creating the process list file
		if (file_modified_younger($process_list_file, $file_access_threshold)) {
			last;
		}
		## if the file is successfully written, then exit the for loop
		if (write_file_contents($process_list_file, \@process_list, 'replace')) {
			last;
		}
	}
	chomp (@process_list);
	return \@process_list;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _read_service_list()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _read_service_list()
	# Description:  Get the service list for Windows
	# Returns:      reference to array with the service list
	# Requires:     n/a
  # -------------------------------------------------------------------

=cut

sub _read_service_list {
	my $agent_vars            = agent_variables();
	my $ssm_vars              = ssm_variables();
	my $service_list_file     = $ssm_vars->{'SSM_LOGS'} . "/service_list";
	my $file_access_threshold = 120; # Change this to adjust the age of the process list file
	my $retry_threshold       = 3;   # The retry count to writing the process_list_file
	my (@service_list, $counter);
	
	# Check for the process list file, see if it is younger than the threshold, if it is not empty. If these are true, read the file.
	#  Validate the array has contents and if so, return the reference to the array.
	if (-e $service_list_file) {
		#print "\t\tFound $process_list_file\n";
		if (file_modified_younger($service_list_file, $file_access_threshold)) {
			#print "\t\t$process_list_file is younger than $file_access_threshold\n";
			@service_list = read_file_contents($service_list_file);
			chomp(@service_list);
			if (@service_list > 0) {
				#print "\t\tThe read of service_list is good and the count is " . @service_list . "\n";
				return \@service_list;
			}
		}
	}
	
	## If this section of code is being called then 
	##  the process list file is too old and/or empty OR the read of the process list file went sour
	@service_list = _get_running_services($agent_vars);
	
	## Do this three times before bailing.  We have what we need, but not writing the process_list_file isn't crucial to success.
	for ($counter = 1; $counter <= $retry_threshold; $counter++) {
		## Double check the modified time on the process_list in case there are multiple programs creating the process list file
		if (file_modified_younger($service_list_file, $file_access_threshold)) {
			last;
		}
		## if the file is successfully written, then exit the for loop
		if (write_file_contents($service_list_file, \@service_list, 'replace')) {
			last;
		}
	}
	chomp (@service_list);
	return \@service_list;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _get_running_processes(\%agent_variables)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _get_running_processes($agent_variables)
	# Description:  Based on the OS, this will run the appropriate process list command.
	#                So as to not have to call the agent_variables() function again, this is passed the reference
	#                to the agent_variables hash
	# Returns:      array with process list (note: not a reference to an array)
	# Requires:     n/a
  # -------------------------------------------------------------------

=cut

sub _get_running_processes {
	my $agent_vars = shift;
	my $os = os_type();
	my $ps_command;
	
	if ($os eq 'WINDOWS') {
		$ps_command = $agent_vars->{'OpC_CMD'} . "/process -c";
	}
	else {
		$ps_command = 'ps -ef -o "etime,pid,args"';
	}
	
	return `$ps_command`;
	
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _get_running_services(\%agent_variables)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _get_running_services($agent_variables)
	# Description:  Based on the OS, this will run the appropriate service list command.
	#                So as to not have to call the agent_variables() function again, this is passed the reference
	#                to the agent_variables hash
	# Returns:      array with service list (note: not a reference to an array)
	# Requires:     n/a
  # -------------------------------------------------------------------

=cut

sub _get_running_services {
	my $agent_vars = shift;
	my $os = os_type();
	my $ps_command;
	
	if ($os eq 'WINDOWS') {
		$ps_command = $agent_vars->{'OpC_BIN'} . "/opcntmserv /list a /width Display 60";
	}
	else {
		$ps_command = 'ps -ef -o "etime,pid,args"';
	}
	
	return `$ps_command`;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _kill_pid(\%agent_variables)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _get_running_processes($agent_variables)
	# Description:  Based on the OS, this will run the appropriate process list command.
	#                So as to not have to call the agent_variables() function again, this is passed the reference
	#                to the agent_variables hash
	# Returns:      array with process list (note: not a reference to an array)
	# Requires:     n/a
  # -------------------------------------------------------------------

=cut

sub _kill_pid {
  my $pid            = shift;
  my $os             = os_type();
  my (@count, $count);
  
  if ($os eq 'WINDOWS') {
    
    my $ssm_vars       = ssm_variables();
    my $win_kill_cmd   = $ssm_vars->{'SSM_BIN'} . "/itokill.exe";
    my $win_kill_param = "/f /pid $pid";
    
    @count = `$win_kill_cmd $win_kill_param`;
    $count = scalar(@count);
    
  } else {
    
    $count = kill -9, $pid;
    
  }

  return $count;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 _copy_file($from_file, $to_file)
  copies from_file to to_file.
  Returns 0 if something fails.
=cut

sub _copy_file {
    my ($from_file, $to_file) = @_;
    my $retval = 0;
    
    if (not -e $from_file) {
        carp "$from_file doesn't exist: $!\n";
        return $retval;
    }
    
    if (not $to_file) {
        carp "To file in _copy_file is not specified!\n";
        return $retval;
    }
    
    if (not copy($from_file, $to_file)) {
        carp "Unable to copy $from_file to $to_file: $!\n";
        return $retval;
    }
    else {
        $retval = 1;
        return $retval;
    }
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

sub _remove_file {
  my $file_to_remove = shift;
  my $retval;
  
  if (not -e $file_to_remove) {
    carp "\n\t$file_to_remove does not exist!";
    $retval = 0;
  }
  else {
    if (not unlink $file_to_remove) {
        carp "Unable to remove $file_to_remove: $!\n";
        $retval = 0;
    }
    else {
        $retval = 1;
    }
    
  }
  
  return $retval;
  
}  

sub _not_blank {
    my ($var_to_check) = @_;
    
    if (not $var_to_check) {
        croak "Error: Variable must be set.";
    }
    
    return $var_to_check;
    
}

sub _os_temp {
    
    if ($ENV{'TMP'}) {
        return $ENV{'TMP'};
    }
    elsif (os_type eq "WINDOWS") {
        return "c:/temp";
    }
    else {
        return "/tmp";
    }
    
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


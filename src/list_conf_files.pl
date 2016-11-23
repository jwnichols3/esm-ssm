###################################################################
#
#             File: list_conf_files.pl
#         Revision: 2.50
#
#           Author: Bill Dooley
#
#    Original Date: 09/03
#
#      Description: This program will list the configuration files
#                   that are located on the system for the passed
#                   type of monitor.
#                   
#           Usage:  list_conf_files.pl --monitor_prefix=<monitor_prefix
#                   monitor_prefix = filesys, fileage, process, service, rotate, other
#
# Revision History:
#
#  Date     Initials  Vers  Description of Change
#
#  09/03      wpd     1.00  <Initial Version>
#
#  2005-04-03 nichj   2.50  Brought up to current standards.
#                           Converted to using get_config_files, get_config_entries
#                           and used hash array to process information.
#                           The oldmethod is now a function at the bottom of the file.
#
#####################################################################

$version             = "$0 version 2.50\n";
$program_description = "list configuration files";

# ===================================================================
# Use Modules
# ===================================================================
use Getopt::Long;

# ===================================================================
# Get Command Line Options
# ===================================================================
GetOptions( "monitor_prefix:s" => \@monitor_prefix,
					  "s", "summary",
					  "v", "version",
            "h", "help",
            "d", "debug", "debugextensive"
          );

# ===================================================================
# Version Check
# ===================================================================
if ( $opt_v or $opt_version ) { print "$version";
                                exit 0;           }

# ===================================================================
# Help Check
# ===================================================================
if ( $opt_h or $opt_help ) {
  usage();
  exit 0;
}

# ===================================================================
# Set up the standard variables
# ===================================================================
get_ssm_vars();

# ===================================================================
# Incorporate the common functions
# ===================================================================
get_ssm_common_functions();

# ===================================================================
# Determine Debug settings
# ===================================================================
## Calling the check_debug_settings will evaluate the command line options and the debug files
## $debug and/or $debug_extensive are set to true if the corresponding setting is true

$DEBUG_FILENAME           = "list_conf_files.debug";
$DEBUG_EXTENSIVE_FILENAME = "list_conf_files.debugextensive";
check_debug_settings("$DEBUG_FILENAME", "$DEBUG_EXTENSIVE_FILENAME");

# ===================================================================
# ===================================================================
# Begining of Main
# ===================================================================
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v

# ===================================================================
# Help Check
# ===================================================================
my %alert_config_index    = ( );
my %alert_config_contents = ( );
my ($file, @contents, @alert_config_files);

if ( $opt_s or $opt_summary ) {
  $summary = 1;
}

my (@alert_config_files, @global_alert_config_files);

if ($monitor_prefix[0] eq "") {
	 print "Error: you must specify a monitor prefix\n";
	 usage();
	 exit 0;
}

##
## Gather the config files and uncommented contents of those files in a hash array
##
foreach $monitor_alert_prefix (@monitor_prefix) {
	 
	 @alert_config_files = get_config_files($monitor_alert_prefix);
	 
	 push ( @{$alert_config_index{"$monitor_alert_prefix"}}, @alert_config_files );
	 
	 foreach $file (@alert_config_files) {
			
			@contents = get_config_entries($file);
			
			push ( @{$alert_config_contents{"$file"}}, @contents );
			
	 }
	 
}


if (not $alert_config_files[0] eq "") {
	 
	 print "\n=== Listing SSM Configuration Files ===\n\n";
	 
	 print "\n=-= Summary of SSM config files =-=\n";
	 print_filelist_summary();
	 
	 if (not $summary) {
			print "\n=-= Details of each config file =-=\n";
			print_alert_file_contents();
	 }

}

exit 0;

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
# ===================================================================
# ===================================================================
# End of Main
# ===================================================================
# ===================================================================


# ===================================================================
# Beginning of Functions
# ===================================================================
# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: print_filelist_summary()
#  Prints the hash array with the filelist summary
# -------------------------------------------------------------------
sub print_filelist_summary {
	 foreach $item (sort keys %alert_config_index) {
			
			# chomp($item);
	 
			print "\n== " . trim($item) . " ==\n"; #: ", scalar( @{$alert_config_index{$item}} ), "item.\n";
			
			foreach $file (sort @{$alert_config_index{$item}}) {
				 chomp($file);
				 print "$file\n";

			}
			
			
	 }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: print_alert_file_contents()
#  Prints the hash array with the filelist summary
# -------------------------------------------------------------------
## Detailed
sub print_alert_file_contents {
	 foreach $file (sort keys %alert_config_contents) {
			
			print "\n-- file contents of " . trim($file) . " --\n";
			
			print_array(@{$alert_config_contents{$file}});
			
	 }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: usage()
#  this function is called when the usage output is required
# -------------------------------------------------------------------
sub usage {
  print "
  
Program USAGE:

list_conf_files --monitor_prefix=<prefix> [--summary | --debug | --debug_extensive | --help | --version]

<prefix> is the monitor alert config file prefix.  Examples:
 --filesys
 --fileage
 --process
 --reboot
 --rotate
 --powerpath

This will return the list of uncommented entries in each config file.

Using the --summary option will just list the config files.
";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_ssm_vars()
#  this function is called to setup all standard variables.
# -------------------------------------------------------------------
sub get_ssm_vars {
   $platform = "$^O";
   chomp ($platform);
   
   if ( "$platform" eq "MSWin32" ) {
     # Windows Platform
     $ov_dir    = $ENV{"OvAgentDir"};
     
     if ( "$ov_dir" eq "" ) {
        $ov_dir = "c:/usr/OV";
     }
     
     require      $ov_dir . "/bin/OpC/cmds/setvar.pm";
     $vposend   = $ov_dir . "/bin/opc/cmds/vposend.exe";
      
    } elsif ( "$platform" eq "aix" ) {
     # AIX Platform  
     require      "/var/lpp/OV/OpC/cmds/setvar.pm";
     $vposend   = "/var/lpp/OV/OpC/cmds/vposend";
   
    } else {
     # Everything else, assume Solaris
     require      "/var/opt/OV/bin/OpC/cmds/setvar.pm";
     $vposend   = "/var/opt/OV/bin/OpC/cmds/vposend";
   }
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
# Function: get_ssm_common_functions()
#  this function is called to incorporate all ssm common functions
# -------------------------------------------------------------------
sub get_ssm_common_functions {
   my $ssm_common_functions_file = $SSM_BIN . "ssm_common.pm";
   
   if (-e $ssm_common_functions_file) {
      require $ssm_common_functions_file;
   }
   
   if ($debug) { print " Incorporated $ssm_common_functions_file\n"; }
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

# ===================================================================
# End of Functions
# ===================================================================

# ===================================================================
# Developer's Notes
#  insert any comments or thought processes here
# ===================================================================
#
# The hash array processing is a bit funky.  I ended up copying something
#  from the Perl Cookbook.  
#
#
#

#### Everything from here to the end of the file is being replaced

sub TheOldWay {
	 # print "Getting $platform drive information $OpC_CMD$DF\n";
	 
	 if ( "$platform" eq "MSWin32" ) {
			$DriveInfo = "listdrives";
			system "$DF > $DriveInfo";
			open (DriveInfo, "$DriveInfo");
			@df_rec = <DriveInfo>;
			close(DriveInfo);
			@df = grep(/FIXED/, @df_rec);
	 } else {
			# print "Getting File System information\n";
			@df = `$DF`;
	 }
	 
	 # print "Got drive information for $platform\n";
	 
	 foreach $filesys (@df) {
			if ( "$platform" eq "MSWin32" ) {
				 chomp($filesys);
				 $chk = (substr($filesys,1,1));
				 @fields = split(/\s+/, $filesys);
	 
				 if ("$chk" eq ":" ) {
						$drive = substr($fields[0],0,2);
						chomp($drive);
				$app_config_file = $drive . "\\ssm\\" . $ARGV[0] . ".dat*";
				@app_files = `$LL $app_config_file`;
				chomp(@app_files);
				$app_files_found += @app_files;
				# print "Checking for .ssm using $LL $app_config_file\n";
				if ( $app_files_found > 0 ) {
					 foreach $app_file (@app_files) {
										($type, $config, $rest) = split(/\./,basename($app_file));
										if ($ARGV[0] eq "*") {
											 if ($type eq "process" || $type eq "filesys" || $type eq "fileage" || $type eq "email" || $type eq "service" || $type eq "rotate") {
													next;
											 }
											 if ($config ne "dat") {
													next;
											 }
										}
									$new_file = "$drive\\ssm\\$app_file";
									if ($ARGV[0] eq "*") {
										 print "== Found other files $new_file ==\n";
									} else {
										 print "== Found $ARGV[0] file $new_file ==\n";
									}
									open (conf_file, "$new_file");
									@conf_file = <conf_file>;
									close(conf_file);
									foreach $conf_rec (@conf_file) {
										 $conf_rec =~ s/^\s+//;
										 $blank = (substr($conf_rec, 0, 1));
										 if ("$blank" eq "") {next;};
										 $comment   = (substr($conf_rec, 0, 1));
										 if (($comment ne "#") && ($comment ne " ")) {
												print "$conf_rec";
										 }
									}
									print "\n\n";
					 }
				}
				 }
			} else {
	 
				 #
				 # Eliminate the non file system records
				 #
	 
				 @chk_field = split(/ /, $filesys);
				 if ("$chk_field[0]" eq "Filesystem") {
						next;
				 }
				 $fld_count=0;
				 foreach $fld (@chk_field) {
						$fld_count ++;
				 }
				 if ($fld_count == 1) {
						next;
				 }
	 
				 #
				 #  Get the mountpoint name
				 #
	 
				 $FS = @chk_field[$fld_count - 1];
				 chomp($FS);
				 $app_config_file = $FS . "/.ssm/" . $ARGV[0] . ".dat*";
				 @app_files = `$LL $app_config_file 2>/dev/null`;
				 chomp(@app_files);
				 $app_files_found += @app_files;
				 # print "Checking for .ssm in $FS\n";
				 if ( $app_files_found > 0 ) {
						foreach $app_file (@app_files) {
							 ($type, $config, $rest) = split(/\./,basename($app_file));
							 if ($ARGV[0] eq "*") {
									if ($type eq "process" || $type eq "filesys" || $type eq "fileage" || $type eq "email" || $type eq "service" || $type eq "rotate") {
										 next;
									}
									if ($config ne "dat") {
										 next;
									}
							 }
							 if ($ARGV[0] eq "*") {
									print "== Found other files $app_file ==\n";
							 } else {
									print "== Found $ARGV[0] file $app_file ==\n";
							 }
							 open (conf_file, "$app_file");
							 @conf_file = <conf_file>;
							 close(conf_file);
							 foreach $conf_rec (@conf_file) {
									$conf_rec =~ s/^\s+//;
									$blank = (substr($conf_rec, 0, 1));
									if ("$blank" eq "") {next;};
									$comment   = (substr($conf_rec, 0, 1));
									if (($comment ne "#") && ($comment ne " ")) {
										 print "$conf_rec";
									}
							 }
							 print "\n\n";
						}
				 }
			}
	 }
	 if ( "$platform" eq "MSWin32" ) {
			$app_config_file = $ov_dir . "\\conf\\" . $ARGV[0] . ".dat*";
			@app_files = `$LL $app_config_file`;
			chomp(@app_files);
			$app_files_found += @app_files;
			# print "Checking for .ssm using $LL $app_config_file\n";
			if ( $app_files_found > 0 ) {
				 foreach $app_file (@app_files) {
						($type, $config, $rest) = split(/\./,basename($app_file));
						if ($ARGV[0] eq "*") {
							 if ($type eq "process" || $type eq "filesys" || $type eq "fileage" || $type eq "email" || $type eq "service" || $type eq "rotate") {
									next;
							 }
							 if ($config ne "dat") {
									next;
							 }
						}
						$new_file = "$ov_dir\\conf\\$app_file";
						if ($ARGV[0] eq "*") {
							 print "== Found other files $new_file ==\n";
						} else {
							 print "== Found $ARGV[0] file $new_file ==\n";
						}
						open (conf_file, "$new_file");
						@conf_file = <conf_file>;
						close(conf_file);
						foreach $conf_rec (@conf_file) {
							 $conf_rec =~ s/^\s+//;
							 $blank = (substr($conf_rec, 0, 1));
							 if ("$blank" eq "") {next;};
							 $comment   = (substr($conf_rec, 0, 1));
							 if (($comment ne "#") && ($comment ne " ")) {
									print "$conf_rec";
							 }
						}
						print "\n\n";
				 }
			}
	 } else {
			$app_config_file = "/var/opt/OV/conf/" . $ARGV[0] . ".dat*";
			@app_files = `$LL $app_config_file 2>/dev/null`;
			chomp(@app_files);
			$app_files_found += @app_files;
			# print "Checking for $app_config_file in $FS\n";
			if ( $app_files_found > 0 ) {
				 foreach $app_file (@app_files) {
						($type, $config, $rest) = split(/\./,basename($app_file));
						if ($ARGV[0] eq "*") {
							 if ($type eq "process" || $type eq "filesys" || $type eq "fileage" || $type eq "email" || $type eq "service" || $type eq "rotate") {
									next;
							 }
							 if ($config ne "dat") {
									next;
							 }
						}
						if ($ARGV[0] eq "*") {
							 print "== Found other files $app_file ==\n";
						} else {
							 print "== Found $ARGV[0] file $app_file ==\n";
						}
						open (conf_file, "$app_file");
						@conf_file = <conf_file>;
						close(conf_file);
						foreach $conf_rec (@conf_file) {
							 $conf_rec =~ s/^\s+//;
							 $blank = (substr($conf_rec, 0, 1));
							 if ("$blank" eq "") {next;};
							 $comment   = (substr($conf_rec, 0, 1));
							 if (($comment ne "#") && ($comment ne " ")) {
									print "$conf_rec";
							 }
						}
						print "\n\n";
				 }
			}
	 }
	 
	 #
	 # Get the files in $SSM_ETC/ssm_pointers
	 #
	 
	 $ssm_file = $SSM_ETC . "ssm_pointers";
	 
	 if ( -e "$ssm_file" ) {
			open (ssm_pointers, "$ssm_file");
			@pointers = <ssm_pointers>;
			if ($ARGV[0] eq "*") {
				 @filesys_pointers = <ssm_pointers>;
			} else {
				 @filesys_pointers = grep(/$ARGV[0]/, @pointers);
			}
			close(ssm_pointers);
			foreach $pointer (@filesys_pointers) {
				 chomp($pointer);
				 if ( -e "$pointer" ) {
						if ($ARGV[0] eq "*") {
							 print "== Found other files $pointer ==\n";
						} else {
							 print "== Found $ARGV[0] file $pointer ==\n";
						}
						open (conf_file, "$pointer");
						@conf_file = <conf_file>;
						close(conf_file);
						foreach $conf_rec (@conf_file) {
							 ($type, $config, $rest) = split(/\./,basename($conf_rec));
							 if ($ARGV[0] eq "*") {
									if ($type eq "process" || $type eq "filesys" || $type eq "fileage" || $type eq "email" || $type eq "service" || $type eq "rotate") {
										 next;
									}
									if ($config ne "dat") {
										 next;
									}
							 }
							 $conf_rec =~ s/^\s+//;
							 $blank = (substr($conf_rec, 0, 1));
							 if ("$blank" eq "") {next;};
							 $comment   = (substr($conf_rec, 0, 1));
							 if (($comment ne "#") && ($comment ne " ")) {
									print "$conf_rec";
							 }
						}
						print "\n\n";
				 }
			}
	 }

}
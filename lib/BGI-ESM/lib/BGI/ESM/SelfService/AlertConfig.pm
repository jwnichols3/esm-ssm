=head1 NAME

BGI::ESM::SelfService::AlertConfig

=head1 SYNOPSIS

Package is used by the Self Service modules to parse the alert configs

=head1 MAJOR REVISIONS

CVS Revision: $Revision: 1.4 $
    Date:     $Date: 2005/11/17 05:00:41 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-11-02   nichj   Converting to package
  #  2005-11-15   nichj   Code format
  #####################################################################

=cut


#################################################################################
### Package Name ################################################################
package BGI::ESM::SelfService::AlertConfig;

#################################################################################
### Module Use Section ##########################################################
use 5.008;
use warnings;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(trim os_type read_file_contents dir_listing
                                strip_comments_from_array flip_slashes_to_back
                                flip_slashes_to_single_back);
use BGI::ESM::Common::Variables;
#################################################################################

#################################################################################
### Require Section #############################################################
require Exporter;
#################################################################################

#################################################################################
### Who is this #################################################################
our @ISA = qw(Exporter BGI::ESM::SelfService);
#################################################################################

#################################################################################
### Public Exports ##############################################################
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    alert_config_array_of_hashes
    parse_alert_config
    get_config_files
    get_config_entries
);
#################################################################################

#################################################################################
### VERSION #####################################################################
our $VERSION = (qw$Revision: 1.4 $)[-1];
#################################################################################

#################################################################################
# Public Methods / Functions
#################################################################################

=head2 alert_config_array_of_hashes ($config_prefix)

    $config_prefix is the prefix to the DAT file name (e.g. filesys.dat.whatever)

    Returns: an reference to an array of hash references that hold the configuration information

    When to Use: use to gather all config entries efficiently.  Once you have the array of hashes,
     you can loop through dereferencing as you go. With the dereferenced values, you can
     check for defaults, check for requiremetns, then process any hits.

     %array_of_hashes = (\%alert_config_data, %alert_config_data, etc.)

     $config_hash_array = $array_of_hashes[0];
     %config_hash_array = %$config_hash_array;

     Action(s) are held in each hash array as an array of actions
      $actions = $config_hash_array->{'action'};
      @actions = @$actions;
    
    Example of decoding:

     $prefix_config = "filesys";
     $config_ref = alert_config_array_of_hashes($prefix_config);

     @config_ref = @$config_ref;

     print "\n\nv v v Config entries for $prefix_config v v v\n\n";

     -- here is where eyou dereference the hash --
     foreach $config (@config_ref) {
     
       %config = %$config;
     
       print_hash_formatted(\%config);

       -- here is where the actions are dereferenced (they are stored as an array in the hash)
       $actions = $config->{'action'};

       if (defined($actions)) {
         print "-- Actions --\n";
         @actions = @$actions;
         print_array(@actions);
       }
     
     
     }


=cut

sub alert_config_array_of_hashes {
    my $config_prefix = shift;
    
    my  (
            @config_files, @config_entries, @config_entries_ref,
            $config_file, $config_entry, $parsed_config_entry,
        );
    
    if (not $config_prefix) {
        carp "The config prefix is undefiend in alert_config_array_of_hashes!\n";
        return 0;
    }
    
    #print "\n\n\n" . "v v v " . "*** Prefix $prefix_config ***" . " v v v" . "\n\n"      if ($debug_extensive);
    
    @config_files = get_config_files($config_prefix);
    
    chomp(@config_files);
    
    #print "\n\n" . "   v v " . "Config File Listing" . " v v  " . "\n"                   if ($debug_extensive);
    #print_array(@config_files)                                                           if ($debug_extensive);
    
    foreach $config_file (@config_files) {
      
        @config_entries = get_config_entries($config_file);
        
        if (not @config_entries) {
            #print "\tConfiguration entries blank, next!\n"                                   if ($debug_extensive);
            next;
        }
        
        #print "\n\n" . "     v " . "Config Entries for $config_file" . " v     " . "\n"    if ($debug_extensive);
        #print_array(@config_entries) if ($debug_extensive);
        
        foreach $config_entry (@config_entries) {

            $parsed_config_entry = parse_alert_config($config_entry);

            push @config_entries_ref, $parsed_config_entry;

        }
      
    }
    
    chomp(@config_entries_ref);
    @config_entries_ref = trim(@config_entries_ref);
    
    #print_array(@config_entries_ref)                                                     if ($debug_extensive);
    
    return \@config_entries_ref;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  parse_alert_config($config_entry)

    $config_entry = the named value pair entry from a ssm config file.

    returns: a referenced hash array with the named / value pairing.

    Developer's notes: This is UUUGLY! But it works.
     The split command returns an array with several spaces / blanks, so
     there is a proess to step through the array and remove blanks / spaced values.

     A secondary level of validation should be added to this at some point.


=cut

sub parse_alert_config {
    my $incoming = shift;
    
    my (
        %alert_config, $item, $key,
        %to_parse, $value, @stripped, @processed,
        $capture_next, @alert_config_parse_actions
        );

    undef @alert_config_parse_actions; # undefine this so it doesn't carry over.
  
    my @parsed = split( /\s*([^\s=]+)=([^=]*)( |\Z)/, $incoming );
    
    foreach $item (@parsed) {
        chomp($item);
        $item = trim($item);
        
        if ( ($item ne "") and ($item ne " ") ) {
            push @stripped, $item;
        }
      
    }
    
    ##
    ## The logic for dealing with multiple actions
    ##
    ## Flip through the array looking for "action"
    ## Take the next value and add it to an array
    ##
    ## At the end append two elements: action and a reference to the action array.
    ##
    ## Yuck!!!
    ##
    foreach $item (@stripped) {
      
        if (lc $item eq "action") {
          
            $capture_next = 1;
            next;
          
        }
        elsif ($capture_next) {
          
            push @alert_config_parse_actions, $item;
            undef $capture_next;
            
        }
        else {
          
            push @processed, $item;
        
        }
      
    }


    # Convert the processed array into a hash
    %to_parse = (@processed);
    
    while ( ($key, $value) = each %to_parse ) {
      
        if (lc $key eq "action") { next; }
    
        $alert_config{lc $key} = $value;  # App becomes APP, sev becomes SEV, etc

    }
    
    # If an action is defined then set the action key to the reference value of the array.
    #
    # This can be dereferenced using
    #  $alert_config = parse_alert_config(\%alert_config_entry);
    #  %alert_config = %$alert_config;
    #  $actions      = $alert_config->{'action'};
    #  @actions      = @$actions;
    #
    if ( @alert_config_parse_actions ) {
      
        $alert_config{'action'} = \@alert_config_parse_actions;
      
    }
    
    return \%alert_config;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  get_config_files(@ssm_monitor_names)

    This function searches the standard SSM file locations for $ssm_monitor_name.dat.*
    It returns an array with the list of process configuration files.

    # 2005-04-07: NichJ: Added ability to send more than one monitor name.
    #
    # 2005-04-12: NichJ: Fixed an issue with reading the mountpoints file.
    #
    # 2005-04-28: NichJ: Converted the ssm directory search to use the perl directory tools.
    #                    Need to do this for the other file listing operations.
    # 2005-11-15: NichJ: Moving to using module based variables.

=cut

sub get_config_files {
    my $ssm_vars = ssm_variables();
    my $commands = get_command_hash();
    
    my $SSM_LOGS = $ssm_vars->{'SSM_LOGS'};
    my $SSM_ETC  = $ssm_vars->{'SSM_ETC'};
    my $LL       = $commands->{'LL'};
    
    my @config_prefixes = @_;   # prefix of the config file(s)
    my $config_prefix   = "";   # used in the foreach loop
    my $MountInfo       = $SSM_LOGS . "/mount.info";
    my (@pointers,
        @config_pointers,
        $get_files,
        $config_file,
        @config_files,
        @mountpoints,
        $mount,
        $file,
        @file_list,
        $file_list_pattern,
        $file_list_found,
       );
    
     #
     # Get the files in $SSM_ETC/ssm_pointers
     #
    if ( -e "$SSM_ETC/ssm_pointers" ) {
     
        #if ($debug)                                                    { print "Processing pointers\n"; }
     
        open (ssm_pointers, "$SSM_ETC/ssm_pointers");
        
        @pointers = <ssm_pointers>;
        
        foreach $config_prefix (@config_prefixes) {
            #if ($debug)                                                { print "Checking for $config_prefix files in $SSM_ETC/ssm_pointers\n"; }
     
            @config_pointers  = grep(/$config_prefix/, @pointers);
     
        }
        
        close(ssm_pointers);
     
        foreach my $pointer (@config_pointers) {
          
            chomp($pointer);
            push (@config_files, "$pointer\n");
            
            #if ($debug_extensive)                                       { print " Pointer processing. Found: $pointer.\n"; }
           
        }
        
    }
    
    #
    # Get the config.dat* files to process
    #
    foreach $config_prefix (@config_prefixes) {
     
        $file_list_pattern  = "$SSM_ETC/$config_prefix.dat\*";
        $file_list_pattern  = flip_slashes_to_single_back($file_list_pattern);
        @file_list          = `$LL $file_list_pattern`;
        chomp(@file_list);
        
        foreach my $file (@file_list) {
         
            if ( os_type() eq 'WINDOWS' ) {
              
                $config_file = "$SSM_ETC/$file";
               
            }
            elsif ( os_type() eq 'LINUX') {
                
                $config_file = $file;

            }
            else {
              
                $config_file = $file;
               
            }
           
           push (@config_files, "$config_file\n");
           
        }
     
    }
     #
     # Get files from the .ssm directories for a mountpoint
     #
    
     # This assumes that the @MountInfo array has been populated...
    @mountpoints = read_file_contents("$MountInfo");
    
    foreach $mount (@mountpoints) {
     
        foreach $config_prefix (@config_prefixes) {
        
            chomp($mount);
            	#=head2  get_config_entries(filename, search_string)

            if ( os_type() eq 'WINDOWS' ) {
           
                #$file_list_pattern  = $mount . "\\ssm\\" . $config_prefix . ".dat.";
                my $pattern_search     = "$config_prefix.dat.*";
                # #
                # # Make sure the mount point exists before getting a directly listing.
                # #
                if (-e "$mount/ssm") {
                    # #
                    # # Replacing the $LL with the perl directory listing.
                    # #
                    #@file_list          = `$LL $file_list_pattern`;
                    my $raw_file_list       = dir_listing("$mount/ssm");
                    # #
                    # # Search the raw file list array and return only those files matching
                    # #
                    @file_list = grep(/^$pattern_search/, @{$raw_file_list});
                    
                    chomp(@file_list);
                    $file_list_found   += @file_list;
                    #if ($debug)                                               { print "Checking for $pattern_search files in $mount/ssm\n"; }
                    
                    if ( $file_list_found > 0 ) {
                          
                        foreach $file (@file_list) {
                            push (@config_files, "$mount/ssm/$file\n");
                        }
                        
                    }
                
                }
               
            }
            else {
            
                $file_list_pattern  = $mount . "/.ssm/" . $config_prefix . ".dat.*";
                @file_list          = `$LL $file_list_pattern 2>/dev/null`;
                chomp(@file_list);
                $file_list_found   += @file_list;
              
                #if ($debug)                                                  { print "Checking for .ssm in $mount\n"; }
              
                if ( $file_list_found > 0 ) {
                    
                    foreach $file (@file_list) {
                        push (@config_files, "$file\n");
                        #if ($debug_extensive)                                    { print " Alert config file processing. Found $file\n"; }
                    }

                }
               
            }
          
        }
          
    }
    
    chomp(@config_files);
    return @config_files ;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  get_config_entries(filename, search_string)

    usage: if a search string is specified then all entries with a match are returned.
           if no entries are found then a blank is returned.
           if nothing is specified in the search string, then all uncommented entries are returned.

    notes: This function calls the following functions:
                  - read_file_contents(filename) - returns file contents as array
                  - strip_comments_array(@array_name) - strips commented lines from array (blank, or starting with  #, ', or ;)
                  - search_config_array(arrary, search_string) - Searches array for search_string and returns an array with lines that match

    revisions:
    2005-03-09 - nichj - added the option if the search string is blank, return all uncommented rows.
    2005-11-15 - nichj - Converted to module and module variables.   


=cut

sub get_config_entries {
    my $filename                  = shift;
    my $search_string             = shift;
    my (@return_array, @file_contents, @file_contents_no_comments);
    
    if (not $filename) {
        print "get_config_entries: filename value blank!\n";
        return 1;
    }
    
     # #
     # # read file contents of the passed filename into an array
     # #
    #if ($debug)                                                      { print "\tget_config_entries: reading file contents of $filename\n"; }
    @file_contents             = read_file_contents($filename);
    
    chomp(@file_contents);
    
     # #
     # # strip any commented or blank lines from the array
     # #
    #if ($debug)                                                      { print "\tget_config_entries: stripping comments from array\n"; }
    @file_contents_no_comments = strip_comments_from_array(@file_contents);
    
     # #
     # # if the search string is blank then return all of the uncommented lines
     # #
     # # search the array for the search variable and put the results into an array
     # #
    if ( not defined($search_string) ) {
        
        #if ($debug)                                                  { print "\tno search string specified, returning all uncommented config entries.\n"; }
        @return_array          = @file_contents_no_comments;
        
    }
    else {
        
        #if ($debug)                                                  { print "\tget_config_entries: searching config entry for $search_string\n"; }
        @return_array          = search_config_array($search_string, \@file_contents_no_comments);
    
    }
    
    # #
    # # return the results array
    # #
    #if ($debug_extensive) {
    #                                                                   print "\tget_config_entries: found the following matches\n";
    #                                                                   print_array(@return_array);
    #                      }
    
    return @return_array;
    
}
 # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

    
#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__

=head1 DEVELOPER'S NOTES

=cut


=head1 TITLE

BGI::ESM::VpoServer::Alarmpoint

=head1 DESCRIPTION

Common Alarmpoint methods

=head1 USAGE



=head1 TODO



=head1 REVISIONS

CVS Revision: $Revision: 1.7 $
    Date:     $Date: 2005/11/30 20:16:21 $

	#####################################################################
	#  2005-10-05 - nichj - Migrated to Perl Module
	#  2005-11-27 - nichj - Added get_apclient_cmd
	#
	#####################################################################
 
=cut

#########################################################################
### Package Name ########################################################
package BGI::ESM::VpoServer::Alarmpoint;
#########################################################################

#########################################################################
### Module Use Section ##################################################
use 5.008000;
use strict;
use warnings;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os trim);

#########################################################################
### Require Section #####################################################
require Exporter;
#########################################################################

#########################################################################
### Who is this #########################################################
our @ISA = qw(Exporter BGI::ESM::VpoServer);
#########################################################################

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	alarmpoint_alert
	numeric_sev
	get_apclient_command
	get_alarmpoint_hash_structure
);

#########################################################################
### VERSION #############################################################
our $VERSION = (qw$Revision: 1.7 $)[-1];
#########################################################################

  
=head2 alarmpoint_alert(\%ap_data, $test)

    if the $test variable is true (or set) then a printout of the command is sent
    to the screen

    Data Structure Notes
     ap_data{ 'map_data'       }*
     ap_data{ 'script'         }*
     ap_data{ 'groupname'      }*
     ap_data{ 'eventid'        }*
     ap_data{ 'messagetext'    }
     ap_data{ 'host'           }
     ap_data{ 'severity'       }
     ap_data{ 'ticket'         }
     ap_data{ 'logfile'        }
     ap_data{ 'contact_device' }
     ap_data{ 'behavior'       }

     ap_data{ 'netiq_severity' }
     ap_data{ 'netiq_specifics' }
     ap_data{ 'longmessage' }

     Based on the map_data value, this will re-arrange these elements into the proper order and call
      the AP Java Client.

     If the AP Java Client doesn't exist, then it will warn and return a 0.

     Returns: 1 (TRUE) or 0 (FALSE)
    
  
=cut

sub alarmpoint_alert {
    my $ap_data    = shift;
    my $test       = shift;
    my $debug      = shift;
    my $debug_file = shift;
    
    my %ap_data = %{$ap_data};
    my $retval  = 1;
    my ($command_parameters, $status);
    
    my $ap_map_data        = lc $ap_data{'map_data'                 };
    my $ap_script          =    $ap_data{'script'                   };
    my $ap_groupname       =    $ap_data{'groupname'                };
    my $ap_eventid         =    $ap_data{'eventid'                  };
    my $ap_messagetext     =    $ap_data{'messagetext'              };
    my $ap_longmessage     =    $ap_data{'longmessage'              };
    my $ap_host            =    $ap_data{'host'                     };
    my $ap_severity        =    $ap_data{'severity'                 };
    my $ap_ticket          =    $ap_data{'ticket'                   };
    my $ap_logfile         =    $ap_data{'logfile'                  };
    my $ap_contact_device  =    $ap_data{'contact_device'           };
    my $ap_behavior        =    $ap_data{'behavior'                 };
    my $ap_contact_options =    $ap_data{'contact_options'          };
    
    my $netiq_severity     =    $ap_data{'netiq_severity'           };
    my $netiq_specifics    =    $ap_data{'netiq_specifics'          };
    
    my $apjc_command       =    get_apclient_command();
    
    my ($ap_longmessage_2, $ap_longmessage_3, $ap_longmessage_4) = "";
    
    
    ##
    ## Error checking for required parameters
    ##
    if ( (not $ap_map_data) and (not $ap_script) and (not $ap_groupname) and (not $ap_eventid) ) {
      
        carp "Invalid number of parameters specified in alarmpoint_alert.";
        $retval = 0;
      
    } else {
    
        if (-e $apjc_command) {
            ## Order is important to each of the interface data maps.
            if      ($ap_map_data eq "openview")                {
                $command_parameters = "\"$ap_map_data\""        .
                                      " \"$ap_script\""         .
                                      " \"$ap_groupname\""      .
                                      " \"$ap_eventid\""        .
                                      " \"$ap_messagetext\""    .
                                      " \"$ap_host\""           .
                                      " \"$ap_severity\""       .
                                      " \"$ap_ticket\""         .
                                      " \"$ap_logfile\""        .
                                      " \"$ap_contact_device\"" .
                                      " \"$ap_behavior\""       ;
              
            }
            elsif ($ap_map_data eq "comfort")                 {
                $command_parameters = "\"$ap_map_data\""        .
                                      " \"$ap_script\""         .
                                      " \"$ap_groupname\""      .
                                      " \"$ap_eventid\""        .
                                      " \"$ap_host\""           .
                                      " \"$ap_contact_device\"" .
                                      " \"$ap_messagetext\""    .
                                      " \"$ap_severity\""       .
                                      " \"$ap_logfile\""        .
                                      " \"$ap_behavior\""       ;
              
              
            }
            elsif ($ap_map_data eq "alternate-notification")  {

                $command_parameters = "\"$ap_map_data\""        .
                                      " \"$ap_script\""         .
                                      " \"$ap_groupname\""      .
                                      " \"$ap_eventid\""        .
                                      " \"$ap_host\""           .
                                      " \"$ap_contact_device\"" .
                                      " \"$ap_severity\""       .
                                      " \"$ap_ticket\""         .
                                      " \"$ap_messagetext\""    .
                                      " \"$netiq_severity\""    .
                                      " \"$netiq_specifics\""   .
                                      " \"$ap_logfile\""        .
                                      " \"$ap_contact_options\"".
                                      " \"$ap_behavior\""       .
                                      " \"$ap_longmessage\""    .
                                      " \"$ap_longmessage_2\""  .
                                      " \"$ap_longmessage_3\""  .
                                      " \"$ap_longmessage_4\""  ;
        
              
            }
            elsif ($ap_map_data eq "peregrine")               {
            
                $command_parameters = "\"$ap_map_data\""        .
                                      " \"$ap_script\""         .
                                      " \"$ap_groupname\""      .
                                      " \"$ap_eventid\""        .
                                      " \"$ap_host\""           .
                                      " \"$ap_severity\""       .
                                      " \"$ap_ticket\""         .
                                      " \"$ap_messagetext\""    .
                                      " \"$ap_contact_device\"" ;
              
            }
            else                                              {
                $command_parameters = "\"$ap_map_data\""        .
                                      " \"$ap_script\""         .
                                      " \"$ap_groupname\""      .
                                      " \"$ap_eventid\""        .
                                      " \"$ap_host\""           .
                                      " \"$ap_contact_device\"" .
                                      " \"$ap_messagetext\""    .
                                      " \"$ap_severity\""       .
                                      " \"$ap_logfile\""        .
                                      " \"$ap_ticket\""         .
                                      " \"$ap_behavior\""       ;
              
            }
            
            if (not $test) {
                $status = system("$apjc_command --map-data $command_parameters");
            }
            else {
                print "The alarmpoint command is '$apjc_command --map-data $command_parameters\n";
            }
        
            if ($debug) {
                my ($debug_out, $DEBUG_FILE, $direction);
                
                $debug_out = "The alarmpoint command is '$apjc_command --map-data $command_parameters\n";
                
                if ($debug_file) {
                    
                    if (not -e $debug_file) {
                        $direction = ">";
                    }
                    else {
                        $direction = ">>";
                    }
                        
                    open ($DEBUG_FILE, "$direction $debug_file") or carp "Unable to open file $debug_file: $!";
                    print $DEBUG_FILE "$debug_out\n";
                    close $DEBUG_FILE;
                    
                }
                else {
                    say($debug_out);
                }
            }
            
        }
        else {
          
            $retval = 0;
            warn "Alarmpoint Java Client ($apjc_command) does not exist on this system.\n";
          
        }
      
    }
    
    return $retval;  

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 numeric_sev($severity)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  # Function: numeric_sev($severity)
  #  returns the alarmpoint numeric severity based on text (warning, major, etc)
  #  if no match, then return the incoming value.
  #
  # -------------------------------------------------------------------

=cut

sub numeric_sev {
	my $severity = shift;
    $severity = lc $severity;
	my $retval;
	
	if ($severity eq "normal")    { $retval = 6;         } elsif
	   ($severity eq "warning")   { $retval = 5;         } elsif
	   ($severity eq "minor")     { $retval = 4;         } elsif
	   ($severity eq "major")     { $retval = 3;         } elsif
	   ($severity eq "critical")  { $retval = 2;         } else
	                              { $retval = $severity; }
	
	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_apclient_command()

	returns a scalar with the apclient command

=cut

sub get_apclient_command {
	
	my ($ap_cmd, $ap_drv, $ap_exe,);
	
	if (os_type() eq 'WINDOWS') {
		$ap_drv = "e:";
		$ap_exe = "/APAgent/APClient.bin.exe";
		$ap_cmd = "${ap_drv}${ap_exe}";
		
		if (not -e $ap_cmd) {
			$ap_drv = "c:";
			$ap_cmd = "${ap_drv}${ap_exe}";
		}
		else {
			carp "Unable to locate apclient command!";
			$ap_cmd = $ap_exe;
		}
		
	}
	elsif (os_type() eq 'LINUX') {
		$ap_cmd = "/opt/OV/apagent/APClient.bin";
		
	}
	elsif (os_type() eq 'UNIX') {
		$ap_cmd = "/opt/OV/apagent/APClient.bin";
		
	}
	else {
		$ap_cmd = "";
	}
	
	return $ap_cmd;
}

=head2 get_alarmpoint_hash_structure()

	returns a reference to a hash with the alarmpoint data structure

=cut

sub get_alarmpoint_hash_structure {
	    my $ap_data = {
                   'map_data'        => "",
                   'script'          => "",
                   'groupname'       => "",
                   'eventid'         => "",
                   'messagetext'     => "",
                   'host'            => "",
                   'severity'        => "",
                   'ticket'          => "",
                   'logfile'         => "",
                   'contact_device'  => "",
                   'behavior'        => "",
                   'netiq_severity'  => "",
                   'netiq_specifics' => "",
                   'longmessage'     => "",
                  };
	return $ap_data;
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



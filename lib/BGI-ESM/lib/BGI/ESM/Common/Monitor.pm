
=head1 NAME

BGI ESM Common Shared Methods

=head1 SYNOPSIS

This library is used for Object Oriented Monitors.

=head1 REVISIONS

CVS Revision: $Revision: 1.1 $
    Date:     $Date: 2006/01/02 20:42:07 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-12-28   wpd     Initial Version
  #####################################################################

=head1 TODO

  - finish adding all other monitors

=cut

###############################################################################
### Package Name ##############################################################
package BGI::ESM::Common::Monitor;
###############################################################################

###############################################################################
### Module Use Section ########################################################
use 5.008000;
use strict;
use warnings;
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
	ssm_check_config_update
	ssm_get_config_data
	ssm_process_errors
	ssm_process_rtn
	ssm_fileage_monitor
);
###############################################################################

###############################################################################
### VERSION ###################################################################
our $VERSION = (qw$Revision: 1.1 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################


###############################################################################
# Public Methods / Functions
###############################################################################

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head ssm_check_config_update($prefix)
	Check if a new global configuration file has been distributed.
=cut

sub ssm_check_config_update {
    my $prefix = shift;
    my $init_file = $ssm_vars->{'SSM_BIN'} . "/" . $prefix . ".dat";

    if ( -e "$init_file" ) {

        print "Installing $fileage\n";
        my $ssm_etc_dir = $ssm_vars->{'SSM_ETC'};
        my $copy_status = copy_file($init_file, $ssm_etc_dir);
   
        if (not $copy_status) {
            croak "Unable to copy file $init_file to $ssm_etc_dir: $!";
        }

    }

    return 1;
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head ssm_get_config_data($prefix)
	Check if a new global configuration file has been distributed.
=cut

sub ssm_get_config_data {
    my $prefix       = shift;
    my @return_array = "";
    my $config_file  = "";

    # 
    # Get the configuration fils
    # 

    our @appl_files = _ssm_get_config_files($prefix);

    foreach $config_file (@appl_files) {
        chomp($config_file);

        my @config_data_raw = read_file_contents($config_file);
        my @config_data     = strip_comments_from_array(@config_data_raw);

        push (@return_array, @config_data);
    }

    return \@return_array;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head _ssm_get_config_files($prefix)
	Get configuration files for SSM prefix
=cut

sub _ssm_get_config_files {
    my $prefix       = shift;
    my @return_array = "";
   
    @return_array    = get_config_files($prefix);
   
    ###
    ### Append pointer files to @appl_files
    ###
    my $ssm_pointers = $ssm_vars->{'SSM_ETC'} . "/ssm_pointers";

    if ( -e "$ssm_pointers" ) {
        print "Processing pointers\n";

        my @pointers         = read_file_contents($ssm_pointers);
        my @fileage_pointers = grep( /fileage/, @pointers );

        foreach my $pointer (@fileage_pointers) {
            chomp($pointer);
            push( @return_array, "$pointer\n" );
        }
    }

    return \@return_array;
   
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head ssm_get_config_vars($config_line, $prefix)
	Return a hash of variables from the configuration record
=cut

sub ssm_get_config_vars {
    my ($config_line, $prefix) = @_;

    my %opts = (
        "D" => { cl => "-D", lf => "dir="             },
        "F" => { cl => "-F", lf => "file="            },
        "a" => { cl => "-a", lf => "app=",            },
        "T" => { cl => "-T", lf => "age_threshold=",  },
        "H" => { cl => "-H", lf => "start="           },
        "J" => { cl => "-J", lf => "stop="            },
        "W" => { cl => "-W", lf => "dayofweek="       },
        "Z" => { cl => "-Z", lf => "description="     },
        "A" => { cl => "-A", lf => "action=",         },
        "s" => { cl => "-s", lf => "sev=",            },
        "z" => { cl => "-z", lf => "severity=",       },
        "M" => { cl => "-M", lf => "message_age=",    },
        "E" => { cl => "-E", lf => "error_times="     },
        "S" => { cl => "-S", lf => "service=",        },
        "O" => { cl => "-O", lf => "source_host="     },
        "X" => { cl => "-X", lf => "file_notfound="   },
    );

    chomp($config_line);

    #
    # Check for blank line
    #
    $config_line =~ s/^\s+//;
    my $blank = ( substr( $config_line, 0, 1 ) );
    if ( "$blank" eq "" ) { next; }

    #
    # Skip the config_line if it is a comment
    #
    my $comment = ( substr( $config_line, 0, 1 ) );
    if ( "$comment" eq "#" )  { next; }
    if ( "$comment" eq "\n" ) { next; }

    my @fargs = $config_line;
    foreach my $o ( keys %opts ) {
        my $fargs[$fidx] =~ s/$opts{$o}{lf}/\t$opts{$o}{cl}\t/i;
    }

    #
    # Strip leading spaces from each argument
    #
    $fargs[$fidx] =~ s/^\s*//;

    #
    # Get the arguments from the configuration record into a standard array
    #
    my @PARMS = split /\t/, $fargs[$fidx];

    #
    # Process the argument array
    #
    our (
            $Error_Times, $DESC,        $dir,           $file,    $appl,  $age,
            $action,      $severity,    $ITO_AGE,       $Service, $start, $stop,
            $dayofweek,   $source_host, $file_notfound, $fname,
        ) = "";

    foreach my $a (@PARMS) {

        #
        # Strip leading AND trailing spaces per field
        #
        $a =~ s/^\s*(.*?)\s*$/$1/;

        if ( $arg_cnt == 1 ) {

            #
            # Set the variables used for processing
            #
            if ($debug) { print "Processing arg $vposend_arg value = $a\n"; }

            if ( "$vposend_arg" eq "-D" ) { $dir           = "$a";               }
            if ( "$vposend_arg" eq "-F" ) { $file          = "$a";               }
            if ( "$vposend_arg" eq "-a" ) { $appl          = lc($a);             }
            if ( "$vposend_arg" eq "-T" ) { $age           = $a;                 }
            if ( "$vposend_arg" eq "-H" ) { $start         = "$a";               }
            if ( "$vposend_arg" eq "-J" ) { $stop          = "$a";               }
            if ( "$vposend_arg" eq "-W" ) { $dayofweek     = lc($a);             }
            if ( "$vposend_arg" eq "-Z" ) { $DESC          = "$a";               }
            if ( "$vposend_arg" eq "-A" ) { $action        = "action=" . lc($a); }
            if ( "$vposend_arg" eq "-s" ) { $severity      = lc($a);             }
            if ( "$vposend_arg" eq "-z" ) { $severity      = lc($a);             }
            if ( "$vposend_arg" eq "-M" ) { $ITO_AGE       = $a;                 }
            if ( "$vposend_arg" eq "-E" ) { $Error_Times   = $a;                 }
            if ( "$vposend_arg" eq "-S" ) { $Service       = $a;                 }
            if ( "$vposend_arg" eq "-O" ) { $source_host   = $a;                 }
            if ( "$vposend_arg" eq "-X" ) { $file_notfound = "$a";               }
            $arg_cnt = 0;
        } else {
            $arg_cnt     = 1;
            $vposend_arg = $a;
        }

    }

    # Source Host Check - if source_host_check returns 1 the source_host option matches
    if ($source_host) {
        chomp($source_host);
        $source_host = trim($source_host);
        if ( source_host_check($source_host) ) {
            if ($debug_extensive) { print " match on source host: $source_host\n"; }
        } else {
            if ($debug_extensive) { print " no match on source host: $source_host\n"; }
            next;
        }
    }

    chomp($dir);
    if ( os_type() eq 'WINDOWS' ) {
        $share_name = "$dir";

        $dir = $dir . "\\";

        $share_chk = substr( $share_name, 0, 2 );

        if ( "$share_chk" eq "\\\\" ) {
            print "Using mount_share with share name: $share_name\n";

            $status = mount_share($share_name);

            if ($debug_extensive) { print "  mount_share status: $status\n"; }

        }

    } else {
        $dir = $dir . "/";
    }

    chomp($severity);
    if ( not "$severity" ) {
        $severity = "major";
    }

    if (    ( "$severity" ne "critical" )
        and ( "$severity" ne "major" )
        and ( "$severity" ne "minor" )
        and ( "$severity" ne "warning" )
        and ( "$severity" ne "normal" ) )
    {
        $severity = "major";
    }

    if ( not "$start" ) {
        $start = "00";
    }

    if ( not "$stop" ) {
        $stop = "24";
    }

    if ( ( not "$dayofweek" ) or ( "$dayofweek" eq "all" ) ) {
        $dayofweek = "sun mon tue wed thu fri sat";
    }

    if ($debug) { print "Start = $start | Stop = $stop | DayofWeek = $dayofweek\n"; }

    chomp($ITO_AGE);
    if ( not "$ITO_AGE" ) {
        $ITO_AGE = 60;
    }

    chomp($Error_Times);
    if ( not "$Error_Times"  ) {
        $Error_Times = "0";
    }

    chomp($Service);
    if ( not "$Service" ) {
        $Service = "os";
    }


    return $agent_vars;

}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head ssm_process_errors($prefix)
	Check if a new global configuration file has been distributed.
=cut

sub ssm_process_errors {
	my $prefix = shift;

        ##
        ## Set other variables here
        ##
        #$agent_vars->{'agent_version'} = "$agent_version";

        return $agent_vars;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head ssm_process_rtn($prefix)
	Check if a new global configuration file has been distributed.
=cut

sub ssm_process_rtn {
	my $prefix = shift;

        ##
        ## Set other variables here
        ##
        #$agent_vars->{'agent_version'} = "$agent_version";

        return $agent_vars;

}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head ssm_fileage_monitor($prefix)
	Check if a new global configuration file has been distributed.
=cut

sub ssm_fileage_monitor {
	my $prefix = shift;

        ##
        ## Set other variables here
        ##
        #$agent_vars->{'agent_version'} = "$agent_version";

        return $agent_vars;

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


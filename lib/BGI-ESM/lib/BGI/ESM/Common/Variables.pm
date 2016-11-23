=head1 NAME

BGI ESM Common Shared Methods: Variables

=head1 SYNOPSIS

This library is used in most BGI ESM programs to load a common set of variables.

=head1 REVISIONS

CVS Revision: $Revision: 1.46 $
    Date:     $Date: 2009/03/20 21:58:04 $

  #####################################################################
  #
  # Major Revision History:
  #
  #  Date       Initials  Description of Change
  #  ---------- --------  ---------------------------------------
  #  2005-10-01   nichj   Converted to module from ssm_common.pm
  #  2005-10-26   nichj   Added more server variables.
  #                       Added SSM_LOGFILE to ssm_variables
  #                       Added get_command_hash
  #  2005-10-27   nichj   Added Linux Logic
  #  2005-11-16   nichj   Added better comments around get_command_hash
  #  2005-12-15   nichj   Added PS commands in the get_command_hash
  #  2005-12-17   nichj   Added DU to commands hash
  #  2009-03-20   nichj   Getting Windows OVO v8 Agent working
  #
  #####################################################################

=head1 TODO

##
## 2005-08-22: Nichj: TODO:
##  - _server_agent_version
##  - server_variables
##  - Refactoring as needed
##

=cut


###############################################################################
### Package Name ##############################################################
package BGI::ESM::Common::Variables;
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
#use BGI::ESM::Common::Shared qw(os_type);
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
	agent_variables
	server_variables
	ssm_variables
	get_agent_version
	get_server_version
	get_agent_dirs
	get_agent_comm_type
	get_command_hash
	print_agent_variables
	print_server_variables
	print_ssm_variables
	
);
###############################################################################

###############################################################################
### VERSION ###################################################################
our $VERSION = (qw$Revision: 1.46 $)[-1];
###############################################################################

###############################################################################
# Public Variables
###############################################################################
#our $ssm_vars                     = ssm_variables();
#our $agent_vars                   = agent_variables();
#our $agent_version                = get_agent_version();
#our $agent_comm_type              = get_agent_comm_type();


###############################################################################
# Public Methods / Functions
###############################################################################

=head2  agent_variables()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     agent_variables()
	# Description:  sets a hash array with various variables based on the version of the agent version.
	# Returns:      Reference to hash array
	# Requires:     
  # -------------------------------------------------------------------

=cut
sub agent_variables {
	my ($agent_vars);
	#my $agent_version   = get_agent_version();
	my $agent_comm_type = get_agent_comm_type();
	
	my ($ov_agent_dir, $ov_data_dir, $ov_install_dir) = get_agent_dirs();
	
	##
	## Directory variables
	##
	if ($agent_comm_type eq 'DCE') {
	  
		$agent_vars = {
		  'OpC_BIN'        => "$ov_agent_dir/bin/OpC",
		  'OpC_INSTALL'    => "$ov_agent_dir/bin/OpC/install",
		  'OpC_UTILS'      => "$ov_agent_dir/bin/OpC/utils",
		  'OpC_CMD'        => "$ov_data_dir/bin/OpC/cmds",
		  'OpC_ACT'        => "$ov_data_dir/bin/OpC/actions",
		  'OpC_MON'        => "$ov_data_dir/bin/OpC/monitor",
		  'OpC_CONF'       => "$ov_data_dir/conf/OpC",
		  'OpC_TMP'        => "$ov_data_dir/tmp/OpC",
		  'OpC_CONTRIB'    => "$ov_agent_dir/contrib/OpC",
		  };
	  
	} elsif ($agent_comm_type eq 'HTTPS') {
	  
		if (_os_type() eq 'WINDOWS') {
			  
			$agent_vars = {
			  'OpC_BIN'        => "$ov_agent_dir/bin/OpC",
			  'OpC_INSTALL'    => "$ov_install_dir/bin/OpC/install",
			  'OpC_UTILS'      => "$ov_agent_dir/bin/OpC/utils",
			  'OpC_CMD'        => "$ov_data_dir/bin/instrumentation",
			  'OpC_ACT'        => "$ov_data_dir/bin/instrumentation",
			  'OpC_MON'        => "$ov_data_dir/bin/instrumentation",
			  'OpC_CONF'       => "$ov_data_dir/conf/OpC",
			  'OpC_TMP'        => "$ov_data_dir/tmp/OpC",
			  'OpC_CONTRIB'    => "$ov_agent_dir/contrib/OpC",
			  };
			  
		}
		elsif (_os_type() eq 'LINUX') {
			$agent_vars = {
			  'OpC_BIN'        => "$ov_agent_dir/bin/OpC",
			  'OpC_INSTALL'    => "$ov_agent_dir/bin/OpC/install",
			  'OpC_UTILS'      => "$ov_agent_dir/bin/OpC/utils",
			  'OpC_CMD'        => "$ov_data_dir/bin/instrumentation",
			  'OpC_ACT'        => "$ov_data_dir/bin/instrumentation",
			  'OpC_MON'        => "$ov_data_dir/bin/instrumentation",
			  'OpC_CONF'       => "$ov_data_dir/conf/OpC",
			  'OpC_TMP'        => "$ov_data_dir/tmp/OpC",
			  'OpC_CONTRIB'    => "$ov_agent_dir/contrib/OpC",
			  }
		  }
		  else {
			  
			$agent_vars = {
			  'OpC_BIN'        => "$ov_agent_dir/bin/OpC",
			  'OpC_INSTALL'    => "$ov_agent_dir/bin/OpC/install",
			  'OpC_UTILS'      => "$ov_agent_dir/bin/OpC/utils",
			  'OpC_CMD'        => "$ov_data_dir/bin/instrumentation",
			  'OpC_ACT'        => "$ov_data_dir/bin/instrumentation",
			  'OpC_MON'        => "$ov_data_dir/bin/instrumentation",
			  'OpC_CONF'       => "$ov_data_dir/conf/OpC",
			  'OpC_TMP'        => "$ov_data_dir/tmp/OpC",
			  'OpC_CONTRIB'    => "$ov_agent_dir/contrib/OpC",
		  };
			  
		  }
  
	}
	
	# Validate the presence of the directories
	$agent_vars = _dir_validate($agent_vars);
	
	##
	## Set other variables here
	##
	#$agent_vars->{'agent_version'} = "$agent_version";
  
	return $agent_vars;
  
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  server_variables

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     server_variables
	# Description:  sets a hash array with various variables based on the version of the management server.
	# Returns:      Reference to hash array
	# Requires:     
  # -------------------------------------------------------------------

=cut
sub server_variables {
	my ($server_vars);
	my $bin_main  = "/opt/OV";
	my $var_main  = "/var/opt/OV";
	my $etc_main  = "/etc/opt/OV";
	my $ov_bin   = $bin_main . "/bin";
	my $vpo_bin  = $ov_bin . "/OpC";
	my $ov_etc   = "$etc_main";
	my $vpo_etc  = "$etc_main";
	my $ov_var   = "$var_main";
	my $vpo_var  = $var_main . "/OpC";
	
	$server_vars = {
		'OV_BIN'      => "$ov_bin",
		'VPO_BIN'     => "$vpo_bin",
		'OV_ETC'      => "$ov_etc",
		'VPO_ETC'     => "$vpo_etc",
		'OV_VAR'      => "$ov_var",
		'VPO_VAR'     => "$vpo_var",
		'RAGENT'      => "$vpo_bin/opcragt",
		'TMP_MGMT_SV' => "$var_main/share/tmp/OpC/mgmt_sv",

	};

	return $server_vars;
  
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  ssm_variables

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     ssm_variables
	# Description:  sets a hash array with SSM variables.  This uses agent_variables to get some core values.
	# Returns:      Reference to hash array with ssm variables
	# Requires:     
  # -------------------------------------------------------------------

=cut
sub ssm_variables {
  my ($ssm_vars);
  my $agent_vars = agent_variables();
  my ($ov_agent_dir, $ov_data_dir, $ov_install_dir) = get_agent_dirs();
  
  ##
  ## SSM Directories
  ##
  $ssm_vars = {
				'SSM_BIN'     => $agent_vars->{'OpC_CMD'},
				'SSM_CONF'    => "$ov_data_dir/conf",
				'SSM_ETC'     => "$ov_data_dir/conf",
				'SSM_HOLD'    => "$ov_data_dir/log",
				'SSM_LOGS'    => "$ov_data_dir/log",
				'SSM_LOGFILE' => "$ov_data_dir/log/ssm.log",
				'SSM_ARCH'    => "$ov_data_dir/log/archive",
				'SSM_TMP'     => "$ov_data_dir/tmp",
                'VPOSEND'     => $agent_vars->{'OpC_CMD'} . "/vposend",
              };
  
  $ssm_vars = _dir_validate($ssm_vars);
  
  ##
  ## Set other variables here
  ##
	# $ssm_vars->{'key_name'} = "value";

  return $ssm_vars;
  
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  print_agent_variables

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     print_agent_variables
	# Description:  prints the hash array with agent variables using Data::Dumper
	# Returns:      N/A
	# Requires:     Data::Dumper
  # -------------------------------------------------------------------

=cut
sub print_agent_variables {
  my $var = agent_variables();
  print Dumper ($var);
  
  return 1;
  
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  print_server_variables

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     print_server_variables
	# Description:  prints the hash array with server variables using Data::Dumper
	# Returns:      N/A
	# Requires:     Data::Dumper
  # -------------------------------------------------------------------

=cut
sub print_server_variables {
  my $var = server_variables();
  print Dumper ($var);
  
  return 1;
  
}

# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  print_ssm_variables

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     print_ssm_variables
	# Description:  prints the hash array with SSM variables using Data::Dumper
	# Returns:      N/A
	# Requires:     Data::Dumper
  # -------------------------------------------------------------------

=cut
sub print_ssm_variables {
  my $var = ssm_variables();
  print Dumper ($var);
  
  return 1;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  print_agent_version

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     print_agent_version
	# Description:  prints the version of the agent
	# Returns:      N/A
	# Requires:     
  # -------------------------------------------------------------------

=cut
sub print_agent_version {
  # my $version = get_agent_version();
  my $version = "";
  print "Agent version: $version\n";
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  print_server_version

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     print_server_version
	# Description:  prints the version of the agent
	# Returns:      N/A
	# Requires:     
  # -------------------------------------------------------------------

=cut
sub print_server_version {
  my $version = _server_version();
  print "Server version: $version\n";
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  get_server_version

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     get_server_version
	# Description:  returns the version of the server
	# Returns:      N/A
	# Requires:     
  # -------------------------------------------------------------------

=cut
sub get_server_version {
  my $version = _server_version();
  return $version;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  get_agent_version

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     get_agent_version
	# Description:  returns the version of the agent
	# Returns:      N/A
	# Requires:
	# Notes:        Be careful of over using this function as it takes a moment or two to process.
  # -------------------------------------------------------------------

=cut
sub get_agent_version {
  my $version = _agent_version();
  return $version;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  get_agent_dirs()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     get_agent_dirs()
	# Description:  calls _ov_agent_dirs to get agent and data dirs
	# Returns:      $ov_agent_dir, $ov_data_dir depending on directory presence
	# Requires:     
  # -------------------------------------------------------------------

=cut
sub get_agent_dirs {
	my ($ov_agent_dir, $ov_data_dir, $ov_install_dir) = _ov_agent_dirs();
	return ($ov_agent_dir, $ov_data_dir, $ov_install_dir);
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  get_agent_comm_type()

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     get_agent_comm_type()
	# Description:  calls _ov_agent_comm_type to get get the comm type
	# Returns:      $ov_comm_type of 'DCE' or 'HTTPS'
	# Requires:
	#
	# -------------------------------------------------------------------

=cut
sub get_agent_comm_type {
	return _ov_agent_comm_type();
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_command_hash()
	returns a hash with command values

	Current commands covered:
				LL - list directory
				DF - display disk information
				CP - copy file
=cut

sub get_command_hash {
	my ($command_hash);
	my $agt_vars = agent_variables();
	my $OpC_CMD  = $agt_vars->{'OpC_CMD'};
	
	if (_os_type() eq 'WINDOWS') {
		$command_hash =
			{
				'LL'    => "cmd /c dir /ON /B",
				'DF'    => "\"$OpC_CMD/winosspi_windiag.exe\" /drives",
				'CP'    => "copy",
				'PS'    => "\"$OpC_CMD/winosspi_confserv.exe\" /list a /width Display 60",
				'PS_NT' => "\"$OpC_CMD/Process.exe\" -c",
				'DU'    => "\"$OpC_CMD/du.exe\"",
			};
	}
	elsif (_os_type() eq 'LINUX') {
		$command_hash =
			{
				'LL' => "ls -1",
				'DF' => "df -k",
				'CP' => "cp -p",
				'PS' => "ps ux",
				'DU' => "du",
			};
	}
	else {
		$command_hash =
			{
				'LL' => "ls -1",
				'DF' => "df -k",
				'CP' => "cp -p",
				'PS' => 'ps -ef -o "etime,pid,args"',
				'DU' => "du",
			};
	}
	
	return $command_hash;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

#################################################################################
### End of Public Methods / Functions ###########################################
#################################################################################


#################################################################################
### Private Methods / Functions #################################################
#################################################################################

=head2  _agent_version

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:    _agent_version
	# Description:  checks to see the version of the management server
	# Returns:      value of the agent version
	# Requires:     
  # -------------------------------------------------------------------

=cut
sub _agent_version {
	my ($ov_agent_dir, $ov_data_dir, $ov_install_dir) = get_agent_dirs();
	my $opcagt_cmd    = "\"$ov_install_dir/bin/OpC/\"opcagt";
	my $opcagt_param  = "-version";
	my $opc_info_file = "$ov_agent_dir/bin/OpC/install/opcinfo";
	my ($retval);
  
	$retval = `$opcagt_cmd $opcagt_param 2>&1`;
	
	if ( not $retval ) {
		my $contents = _read_file_contents($opc_info_file);
		my @version = grep { /OPC_INSTALLED_VERSION/ } @{$contents};
		
		my @opcver = split / /, $version[0];
		
		$retval    = $opcver[1];

	}
  
	if ( not $retval ) {
	  $retval = 'UNKNOWN';
	}
	
	chomp($retval);
	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  _server_version

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _server_version
	# Description:  checks to see the version of the management server
	# Returns:      value of the server version
	# Requires:     
  # -------------------------------------------------------------------

=cut

sub _server_version {
  ###############################################
  ### TODO: Get actual version from somewhere ###
  ###############################################
  return '0.00';
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  _ov_agent_comm_type

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _ov_agent_comm_type
	# Description:  determines the comm type of the agent (either DCE or HTTPS)
	# Returns:      'DCE' or 'HTTPS'
	# Requires:     
  # -------------------------------------------------------------------

=cut

sub _ov_agent_comm_type {
	
	my ($ov_agent_dir, $ov_data_dir, $ov_install_dir) = get_agent_dirs();
    my $status;

	my $opcagt_cmd   = "\"$ov_install_dir/bin/OpC/\"opcagt";
	my $opcagt_param = "-type";
    
    $status = `$opcagt_cmd $opcagt_param 2>&1`;
    chomp($status);
    
    if (not $status) {
        if (_os_type() eq 'WINDOWS') {
            $status = "DCE";
        } else {
            if ( !-e "$ov_agent_dir/bin/OpC/install/opcinfo" || -z "$ov_agent_dir/bin/OpC/install/opcinfo" ) {
                $status = "HTTPS";
            } else {
                $status = "DCE";
            }
        }
    }

	# my $status = `$opcagt_cmd $opcagt_param`;
	# chomp($status);

	return $status;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _ov_install_dir


=cut

=head2  _ov_agent_dirs()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _ov_agent_dirs()
	# Description:  Looks for directories for agent.  If nothing found, returns .
	# Returns:      $ov_agent_dir, $ov_data_dir
	# Requires:     
  # -------------------------------------------------------------------

=cut

sub _ov_agent_dirs {

	my $os              = _os_type();
	my ($ov_agent_dir, $ov_data_dir, $ov_install_dir);
	my $unix_http        = "/opt/OV";
	my $unix_http_data   = "/var/opt/OV";
	my $unix_dce         = "/opt/OV";
	my $unix_dce_data    = "/var/opt/OV";
	my $linux_http       = "/opt/OV";
	my $linux_http_data  = "/var/opt/OV";
	my $linux_dce        = "/opt/OV";
	my $linux_dce_data   = "/var/opt/OV";
	my $win_http         = "/Program Files/HP OpenView";       # use in conjunction with drive: "c:{$win_http}"
	my $win_http_data    = "/Program Files/HP OpenView/data";  # use in conjunction with drive: "c:{$win_http_data}"
	my $win_dce          = "/usr/OV";                          # use in conjunction with drive: "c:{$win_dce}"
	my $win_dce_data     = "/usr/OV";                          # use in conjunction with drive: "c:{$win_dce_data}"
	
	if ($os eq 'WINDOWS') {
	  
        if ($ENV{'OvAgentDir'}) {
            my $ov_agent_env =  $ENV{'OvAgentDir'};
               $ov_agent_env =~ s/\\\\/\\/g;
               $ov_agent_env =~ s/\\/\//g;
            
            $ov_agent_dir = $ov_agent_env;
        }

        if ($ENV{'OvDataDir'}) {
            my $ov_data_env = $ENV{'OvDataDir'};
               $ov_data_env =~ s/\\\\/\\/g;
               $ov_data_env =~ s/\\/\//g;
            
            $ov_data_dir = $ov_data_env;
        }

		if ($ENV{'OvInstallDir'}) {
            my $ov_inst_env = $ENV{'OvInstallDir'};
               $ov_inst_env =~ s/\\\\/\\/g;
               $ov_inst_env =~ s/\\/\//g;
            
            $ov_install_dir = $ov_inst_env;
        }
        ## The OvAgentDir environment variable isn't set, so find the directory
        if (not $ov_agent_dir) {
            ## HTTPS directories
             if    ( -e "c:{$win_http}" )      { $ov_agent_dir = "c:{$win_http}";     }
             elsif ( -e "e:{$win_http}" )      { $ov_agent_dir = "e:{$win_http}";     }
            ## DCE directories 
             elsif ( -e "c:{$win_dce}"  )      { $ov_agent_dir = "c:{$win_dce}";      }
             elsif ( -e "e:{$win_dce}"  )      { $ov_agent_dir = "e:{$win_dce}";      }
             else                              { $ov_agent_dir = ".";                 }
        }
        
        if (not $ov_data_dir) {
            ## HTTPS directories
             if    ( -e "c:{$win_http_data}" ) { $ov_data_dir = "c:{$win_http_data}"; }
             elsif ( -e "e:{$win_http_data}" ) { $ov_data_dir = "e:{$win_http_data}"; }
            ## DCE directories
             elsif ( -e "c:{$win_dce_data}"  ) { $ov_data_dir = "c:{$win_dce_data}";  }
             elsif ( -e "e:{$win_dce_data}"  ) { $ov_data_dir = "e:{$win_dce_data}";  }
             else                              { $ov_data_dir = ".";                  }
        }

        if (not $ov_install_dir) {
            ## HTTPS directories
             if    ( -e "c:{$win_http_data}" ) { $ov_install_dir = "c:{$win_http_data}"; }
             elsif ( -e "e:{$win_http_data}" ) { $ov_install_dir = "e:{$win_http_data}"; }
            ## DCE directories
             elsif ( -e "c:{$win_dce_data}"  ) { $ov_install_dir = "c:{$win_dce_data}";  }
             elsif ( -e "e:{$win_dce_data}"  ) { $ov_install_dir = "e:{$win_dce_data}";  }
             else                              { $ov_install_dir = ".";                  }
        }
	  
	}
	elsif ($os eq 'LINUX') {
  
	  ## OS is LINUX
	   ## HTTPS directories
		if    ( -e "$linux_http" )        { $ov_agent_dir = "$linux_http";       }
	   ## DCE directories 
		elsif ( -e "$linux_dce"  )        { $ov_agent_dir = "$linux_dce";        }
		else                              { $ov_agent_dir = ".";                 }
		
	   ## HTTPS directories
		if    ( -e "$linux_http_data" )   { $ov_data_dir = "$linux_http_data";   }
	   ## DCE directories 
		elsif ( -e "$linux_dce_data"  )   { $ov_data_dir = "$linux_dce_data";    }
		else                              { $ov_data_dir = ".";                  }
		
	   ## HTTPS directories
		if    ( -e "$linux_http_data" )   { $ov_install_dir = "$linux_http_data";   }
	   ## DCE directories 
		elsif ( -e "$linux_dce_data"  )   { $ov_install_dir = "$linux_dce_data";    }
		else                              { $ov_install_dir = ".";                  }

	}
	else {
  
	  ## OS is UNIX
	   ## HTTPS directories
		if    ( -e "$unix_http" )         { $ov_agent_dir = "$unix_http";        }
	   ## DCE directories 
		elsif ( -e "$unix_dce"  )         { $ov_agent_dir = "$unix_dce";         }
		else                              { $ov_agent_dir = ".";                 }
		
	   ## HTTPS directories
		if    ( -e "$unix_http_data" )    { $ov_data_dir = "$unix_http_data";    }
	   ## DCE directories 
		elsif ( -e "$unix_dce_data"  )    { $ov_data_dir = "$unix_dce_data";     }
		else                              { $ov_data_dir = ".";                  }
		
	   ## HTTPS directories
		if    ( -e "$unix_http_data" )    { $ov_install_dir = "$unix_http_data";    }
	   ## DCE directories 
		elsif ( -e "$unix_dce_data"  )    { $ov_install_dir = "$unix_dce_data";     }
		else                              { $ov_install_dir = ".";                  }

	}
	
	return ($ov_agent_dir, $ov_data_dir, $ov_install_dir);
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  _os_type()

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _os_type
	# Description:  determines if running on Windows or UNIX
	# Returns:      'WINDOWS' or 'UNIX'
	# Requires:     n/a
  # -------------------------------------------------------------------

=cut

sub _os_type {
	my $retval   = "";    
	my $platform = "$^O";
	chomp ($platform);
	   
	if ( "$platform" eq "MSWin32" ) {
	  
	  $retval = 'WINDOWS';
	  
	}
	elsif ( lc "$platform" eq "linux" ) {
		
		$retval = 'LINUX';
		
	}
	else {
          ##
          ## Temporary fix to add /opt/OV/bin to the path
          ## 

	  $retval = 'UNIX';
	  
	}
	
	return $retval;
	
}  
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  _dir_validate(\%directory_hash_to_validate)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _dir_validate(\%directory_hash_to_validate)
	# Description:  validates that all values in the hash have a directory if the directory doesn't exist then set the value to '.'
	# Returns:      reference to fixed hash
	# Requires:     n/a
  # -------------------------------------------------------------------

=cut

sub _dir_validate ($) {
	my $validate_hash = shift;
	
	###
	### Directory validation time (primarily used for development purposes).  If the directory doesn't exist, then
	###  set the variable to ".";
	foreach my $var (keys %{$validate_hash}) {
	  if ($validate_hash->{$var}) {
		if (not -e $validate_hash->{$var}) {
		  $validate_hash->{$var} = ".";
		}
	  }
	}
	
	return $validate_hash;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2  _read_file_contents($file_to_read)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	# Function:     _read_file_contents($file_to_read)
	# Description:  Reads the contents of $file_to_read into an array and returns a reference to the array
	# Returns:      reference to array with contents of file
	# Requires:     n/a
  # -------------------------------------------------------------------

=cut

sub _read_file_contents {
    my $file_name    = shift;
    my @return_array = "";
    
    open  CONFIG_FILE_TO_READ, "< $file_name";
    
    @return_array    = <CONFIG_FILE_TO_READ>;
    
    close CONFIG_FILE_TO_READ;
    
    return \@return_array;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _check_os($os)
    returns the OS based on the current OS if $os is not set
=cut

sub _check_os {
    my $os = shift;
    
    if (not $os) {
        return os_type();
    }
    else {
        return $os;
    }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

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




=head1 NAME

BGI::ESM::Common::VpoAgent

=head1 SYNOPSIS

This package deals with VpoAgent methods, inlcuding getting the status of the
agent, stopping, starting, restarting, and killing the agent, getting the
monitoring policies, and returning the various command associated with these
commands.

=head1 REVISIONS

CVS Revsion: $Revision: 1.6 $

    #####################################################################
    #
    # Major Revision History:
    #
    #  Date       Initials  Description of Change
    #  ---------- --------  ---------------------------------------
    #  2005-09-22   nichj   Creating
    #####################################################################

=cut

##############################################################################
### Package Name #############################################################
package BGI::ESM::Common::VpoAgent;

##############################################################################
### Module Use Section #######################################################
use 5.008000;
use strict;
use warnings;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Variables;
use BGI::ESM::Common::Shared qw(os_type read_file_contents trim);
##############################################################################

##############################################################################
### Require Section ##########################################################
require Exporter;
##############################################################################

##############################################################################
### Who is this ##############################################################
our @ISA = qw(Exporter BGI::ESM::Common);
##############################################################################

##############################################################################
### Public Exports ###########################################################
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    get_monitoring_policies
    get_monitoring_policies_cmd
    get_agent_status
    get_agent_status_output
    get_agent_status_cmd
    get_agent_start_cmd
    get_agent_kill_cmd
    get_agent_stop_cmd
    agent_kill
    agent_start
    agent_restart
    agent_stop
    agent_start
    get_nodeinfo_file_contents
    get_nodeinfo_file_name
    get_opcinfo_file_contents
    get_opcinfo_file_name
    get_mgrconf_file_contents
    get_mgrconf_file_name
    get_primmgr_file_contents
    get_primmgr_file_name
    disable_monitoring_policy
    return_all_monitoring_policies
    return_monitoring_policy
    enable_monitoring_policy
);
##############################################################################

##############################################################################
### VERSION ##################################################################
our $VERSION = (qw$Revision: 1.6 $)[-1];
##############################################################################

##############################################################################
# Public Methods / Functions
##############################################################################

=head2 get_monitoring_policies()
    returns reference to array with a list of monitoring policies
=cut

sub get_monitoring_policies {
  return _monitoring_policies();

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_agent_status()
    returns 1 if agent is healthy, 0 if problem
=cut

sub get_agent_status {
    return _agent_status();
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_agent_status_output()
    returns 1 if agent is healthy, 0 if problem
=cut

sub get_agent_status_output {
    return _agent_status_output();
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_agent_status_cmd()
    Returns 

=cut

sub get_agent_status_cmd {
    #TODO: refactor to find proper agent status command based on OS and agent
    #       type
    return "opcagt -status";
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_agent_stop_cmd()
    Returns 

=cut

sub get_agent_stop_cmd {
    #TODO: refactor to find proper agent status command based on OS and agent
    #       type
    return "opcagt -stop";
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_agent_kill_cmd()
    Returns 

=cut

sub get_agent_kill_cmd {
    #TODO: refactor to find proper agent status command based on OS and agent
    #       type
    return "opcagt -kill";
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_agent_start_cmd()
    Returns 

=cut

sub get_agent_start_cmd {
    #TODO: refactor to find proper agent status command based on OS and agent
    #       type
    if (os_type() eq 'WINDOWS') {
        return "opcagt -start";
    }
    else {
        return "/etc/init.d/opcagt start";
    }
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

sub get_monitoring_policies_cmd {
    #TODO: refactor to find proper agent status command based on agent type
    return "opctemplate";
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 agent_kill()
    Returns 
=cut

sub agent_kill {
    return _agent_kill();
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 agent_restart()
    Returns 
=cut

sub agent_restart {
    return _agent_restart();
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 agent_stop()
    Returns 
=cut

sub agent_stop {
    return _agent_stop();
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 agent_start()
    Returns 
=cut

sub agent_start {
    return _agent_start();
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_nodeinfo_file_contents()
    Returns reference to array with contents of node info file
=cut

sub get_nodeinfo_file_contents {
  return _nodeinfo_file_contents();
}

=head2 get_nodeinfo_file_name()
    Returns scalar with full path to nodeinfo file
=cut

sub get_nodeinfo_file_name {
  return _nodeinfo_file_name();
}

=head2 get_opcinfo_file_contents()
    Returns reference to array with contents of opc info file
=cut

sub get_opcinfo_file_contents {
  return _opcinfo_file_contents();
}

=head2 get_opcinfo_file_name()
    Returns scalar with full path to opcinfo file
=cut

sub get_opcinfo_file_name {
  return _opcinfo_file_name();
}

=head2 get_mgrconf_file_contents()
    Returns reference to array with contents of mgrconf file
=cut

sub get_mgrconf_file_contents {
  return _mgrconf_file_contents();
}

=head2 get_mgrconf_file_name()
    Returns scalar with full path to mgrconf file
=cut

sub get_mgrconf_file_name {
  return _mgrconf_file_name();
}

=head2 get_primmgr_file_contents()
    Returns reference to array with contents of node info file
=cut

sub get_primmgr_file_contents {
  return _primmgr_file_contents();
}

=head2 get_primmgr_file_name()
    Returns scalar with full path to primmgr file
=cut

sub get_primmgr_file_name {
  return _primmgr_file_name();
}

=head2 disable_monitoring_policy($policy_to_disable)
    returns the status of the command
=cut

sub disable_monitoring_policy {
    my $policy     = shift;
    my $policy_cmd = get_monitoring_policies_cmd();
    
    return `$policy_cmd -d $policy`;
}

=head2 disable_monitoring_policy($policy_to_disable)
    returns the status of the command
=cut

sub enable_monitoring_policy {
    my $policy     = shift;
    my $policy_cmd = get_monitoring_policies_cmd();
    
    return `$policy_cmd -e $policy`;
}

=head2 return_all_monitoring_policies
    returns a reference to an array with the monitoring policies list
=cut

sub return_all_monitoring_policies {
    my @monitoring_policies;
    my $policy_cmd = get_monitoring_policies_cmd();
    my @monitoring_policy_list = `$policy_cmd`;
    
    foreach my $policy_line (@monitoring_policy_list) {
        
        my ($type, $policy, $status) = split /\"/, $policy_line;
        if ($policy) {
            $policy = "\"" . $policy . "\"";
            push @monitoring_policies, $policy;
        }
    
    }
    
    return \@monitoring_policies;    
    
}

=head2 return_monitoring_policy($policy_search_term)
    returns a reference to an array with the found monitoring policies
=cut

sub return_monitoring_policy {
    my $search_policy = shift;
    my @monitoring_policies;
    my $monitoring_policy_list = return_all_monitoring_policies();
    
    @monitoring_policies = grep /$search_policy/, @{$monitoring_policy_list};
    
    return \@monitoring_policies;    
    
}



##############################################################################
### End of Public Methods / Functions ########################################
##############################################################################


##############################################################################
### Private Methods / Functions ##############################################
##############################################################################

=head2 _monitoring_policies()

=cut

sub _monitoring_policies {
    #TODO: Refactor to use native VPO8/HTTPS commands where appropriate.
    
    my $monitoring_policies_cmd = get_monitoring_policies_cmd();
    
    my @monitoring_policies = `$monitoring_policies_cmd`;
    chomp(@monitoring_policies);
    return \@monitoring_policies;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _agent_status()
    returns 1 or 0 based on the analysis of the agent status
=cut

sub _agent_status {
    #TODO: Refactor to include additional checks,
    # determine agent type, os, etc.
    
    my $agent_status_output = _agent_status_output();
    my $retval = 1;
    
    if ( grep /not running/, @{$agent_status_output} ) {
        $retval = 0;
    }
    
    if ( grep /Not Running/, @{$agent_status_output} ) {
        $retval = 0;
    }
    
    if ( grep /Aborted/, @{$agent_status_output} ) {
        $retval = 0;
    }

    return $retval;
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 _agent_status_output()
    returns a reference to an array with the output of the agent status command
=cut

sub _agent_status_output {
    my $agent_status_command = get_agent_status_cmd();
    
    my @status = `$agent_status_command`;
    
    chomp(@status);
    
    return \@status;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns 
=cut

sub _agent_kill {
    #TODO: Refactor to validate kill worked
    
    my $retval   = 1;
    my $kill_cmd = get_agent_kill_cmd();
    
    my $agent_kill_status = `$kill_cmd`;
    
    # Commented out until get_agent_status is more intelligent
    #if (not get_agent_status()) {
    #    $retval = 1;
    #}

    return $retval;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns 
=cut

sub _agent_restart {
    #TODO: Refactor to validate restart worked

    my $retval = 0;

    if (agent_kill()) {
        if (agent_start()) {
            $retval = 1;
        }
    }
    
    # Commented out until get_agent_status is more intelligent
    #if (get_agent_status()) {
    #    $retval = 1;
    #}

    return $retval;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns 
=cut

sub _agent_stop {
    #TODO: Refactor to validate stop worked
    my $retval   = 1;
    my $stop_cmd = get_agent_stop_cmd();
    
    my $agent_stop_status = `$stop_cmd`;
    
    # Commented out until get_agent_status is more intelligent
    #if (not get_agent_status()) {
    #    $retval = 1;
    #}

    return $retval;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns 
=cut

sub _agent_start {
    #TODO: Refactor to validate start worked
    my $retval    = 1;
    my $start_cmd = get_agent_start_cmd();
    
    my $agent_start_status = `$start_cmd`;
    
    # Commented out until get_agent_status is more intelligent
    #if (get_agent_status()) {
    #    $retval = 1;
    #}

    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns reference to array with contents file
=cut

sub _nodeinfo_file_contents {
    my (@file_contents);
    
    my $nodeinfo_file = get_nodeinfo_file_name();
    
    if (-e $nodeinfo_file) {
      @file_contents = read_file_contents($nodeinfo_file);
    }
    
    trim(@file_contents);
    chomp(@file_contents);
  
    return (\@file_contents);
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns scalar with file name
=cut

sub _nodeinfo_file_name {
    my $agent_vars = agent_variables();
    
    return $agent_vars->{'OpC_CONF'} . "/nodeinfo";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
  
=head2 
    Returns reference to array with contents file
=cut

sub _opcinfo_file_contents {
    my (@file_contents);
    
    my $opcinfo_file = get_opcinfo_file_name();
    
    if (-e $opcinfo_file) {
      @file_contents = read_file_contents($opcinfo_file);
    }
    
    trim(@file_contents);
    chomp(@file_contents);
  
    return (\@file_contents);
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns scalar with file name
=cut

sub _opcinfo_file_name {
    my $agent_vars = agent_variables();
    
    return $agent_vars->{'OpC_INSTALL'} . "/opcinfo";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns reference to array with contents file
=cut

sub _mgrconf_file_contents {
    my (@file_contents);
    
    my $mgrconf_file = get_mgrconf_file_name();
    
    if (-e $mgrconf_file) {
      @file_contents = read_file_contents($mgrconf_file);
    }
    
    trim(@file_contents);
    chomp(@file_contents);
  
    return (\@file_contents);
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns scalar with file name
=cut

sub _mgrconf_file_name {
    my $agent_vars = agent_variables();
    
    return $agent_vars->{'OpC_CONF'} . "/mgrconf";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns reference to array with contents file
=cut

sub _primmgr_file_contents {
    my (@file_contents);
    
    my $primmgr_file = get_primmgr_file_name();
    
    if (-e $primmgr_file) {
      @file_contents = read_file_contents($primmgr_file);
    }
    
    trim(@file_contents);
    chomp(@file_contents);
  
    return (\@file_contents);
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 
    Returns scalar with file name
=cut

sub _primmgr_file_name {
    my $agent_vars = agent_variables();
    
    return $agent_vars->{'OpC_CONF'} . "/primmgr";

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
 
##############################################################################
### End of Private Methods / Functions #######################################
##############################################################################

#####################################################################
# Do not change this.  Required for successful require load
1;
#####################################################################

__END__


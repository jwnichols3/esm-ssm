=head1 TITLE

BGI::ESM::VpoServer::VPO

=head1 DESCRIPTION

Common VPO Server methods

=head1 USAGE



=head1 TODO



=head1 REVISIONS

CVS Revision: $Revision: 1.27 $
    Date:     $Date: 2006/08/06 22:26:01 $

	#####################################################################
	#  2005-10-05 - nichj - Migrated to Perl Module
	#  2005-10-20 - nichj - Moved netiq_vpo_node_add to bgi::esm::VpoServer:NodeSync
	#                       Added network module requirement
	#  2005-11-30 - nichj - Added get_opc_notify_cmd, vpo_tti_cli_generate, vpo_data_hash_blank
	#  2005-12-16 - nichj - Removed netiq_vpo_node_add from exported methods
	#  2006-03-30 - nichj - Improved the get_vpo_node_list to read from locally cached file
    #  2006-04-18 - nichj - Improved get_vpo_node_list command to use full-sql
    #  2006-07-06 - nichj - Added ovo_server_status and get_ovo_server_status_cmd
	#
	#####################################################################
 
=cut

##############################################################################
### Package Name #############################################################
package BGI::ESM::VpoServer::VPO;
##############################################################################

##############################################################################
### Module Use Section #######################################################
use 5.008000;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use lib "/code/vpo/BGI-ESM/lib";     # Windows - assumes cvs checkout is at /code
use lib "/apps/esm/vpo/BGI-ESM/lib"; # UNIX    - assumes cvs checkout is at /apps/esm
use BGI::ESM::Common::Shared qw(os_type check_os trim read_file_contents
                                write_file_contents file_modified_younger);
use BGI::ESM::Common::Variables qw(agent_variables server_variables);
use BGI::ESM::Common::Network;
##############################################################################

##############################################################################
### Require Section ##########################################################
require Exporter;
##############################################################################

##############################################################################
### Who is this ##############################################################
our @ISA = qw(Exporter BGI::ESM::VpoServer);
##############################################################################

##############################################################################
### Public Exports ###########################################################
# This allows declaration	use BGI::VPO ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	deconstruct_vpo_data_hash
	get_opc_notify_cmd
	get_remote_agent_status
	get_remote_agent_status_command
	get_vpo_node_list
	get_vpo_own_cmd
	mv_hier
    ovo_server_status
    get_ovo_server_status_cmd
	parse_cma
	vpo_ack_event
	vpo_data_hash_blank
	vpo_data_populate
	vpo_message_groups
	vpo_node_add
	vpo_node_exist
	vpo_own_event
	vpo_sql_call
	vpo_tti_cli_generate
    vpo_annotate
);
##############################################################################

##############################################################################
### VERSION ##################################################################
our $VERSION = (qw$Revision: 1.27 $)[-1];
##############################################################################

##############################################################################
# Public Variables
##############################################################################

##############################################################################
# Public Methods / Functions
##############################################################################


=head2 vpo_data_populate(\@ARGV)

  # v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
  #  Purpose:  Takes the ARGV array passed by VPO and translates it into a hash array to be used by TTI / Notification programs.
  #
  #  Returns:  reference to hash array
  #            
  #  Requires: @ARGV from TTI/Notification programs
  #
  #  Issues/Enhancements:
  # -------------------------------------------------------------------

=cut

sub vpo_data_populate {
	my $params   = shift;
	my @params   = @{$params};
	my ($retval);
	
	my (
		$vpo_msgid,  
		$vpo_nodename, 
		$vpo_nodetype, 
		$vpo_event_date_node, 
		$vpo_event_time_node, 
		$vpo_event_date_mgmtsvr, 
		$vpo_event_time_mgmtsvr,
		$vpo_appl, 
		$vpo_message_group, 
		$vpo_obj, 
		$vpo_severity, 
		$vpo_operators, 
		$vpo_message, 
		$vpo_instruction_text, 
		$vpo_cma
	) 
	= @params;
	
	$retval = {
		'message_group'      => $vpo_message_group          ,
		'node'               => strip_domain($vpo_nodename) ,
		'cma'                => $vpo_cma                    ,
		'message_text'       => $vpo_message                ,
		'msgid'              => $vpo_msgid                  ,
		'node_type'          => $vpo_nodetype               ,
		'event_date_node'    => $vpo_event_date_node        ,
		'event_time_node'    => $vpo_event_time_node        ,
		'event_date_mgmtsvr' => $vpo_event_date_mgmtsvr     ,
		'event_time_mgmtsvr' => $vpo_event_time_mgmtsvr     ,
		'appl'               => $vpo_appl                   ,
		'obj'                => $vpo_obj                    ,
		'severity'           => $vpo_severity               ,
		'operators'          => $vpo_operators              ,
		'instruction_text'   => $vpo_instruction_text
	};
	
	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 deconstruct_vpo_data_hash($vpo_data_hash, not_quotes)

	takes the constructed vpo_data_hash and returns it to an array as used in @ARGV
	
	set no_quotes to true to not include quotes.

=cut

sub deconstruct_vpo_data_hash {
	my $incoming_hash = shift;
	my $no_quotes     = shift;
	my $qs            = '"';
	
	if ($no_quotes) {
		$qs = "";
	}
	
	my @retval;
	
	push @retval, qq?${qs}$incoming_hash->{'msgid'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'node'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'node_type'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'event_date_node'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'event_time_node'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'event_date_mgmtsvr'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'event_time_mgmtsvr'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'appl'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'message_group'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'obj'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'severity'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'operators'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'message_text'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'instruction_text'}${qs}?;
	push @retval, qq?${qs}$incoming_hash->{'cma'}${qs}?;

	return \@retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_opc_notify_cmd($option)

	returns a scalar with the location of the opc_notify_cmd
	
	if $option is set then the pointer is to the production opc_notify
	
	note: the non-production/windows version assumes perl is
	in the path and is the correct version (activeperl)

=cut

sub get_opc_notify_cmd {
	my $option = shift;
	my ($opc_notify);
	
	if ( $option ) {
		$opc_notify = "/apps/esm/tti/bin/opc_notify";
	}
	else {
		$opc_notify = "perl /apps/esm/vpo/vpo_server/src/opc_notify.pl";
	}
	
	if (os_type() eq 'WINDOWS') {
		$opc_notify = "perl c:/code/vpo/vpo_server/src/opc_notify.pl";
	}
	
	return $opc_notify;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 vpo_tti_cli_generate (\%vpo_event_hash)

	this method takes the incoming hash (assuming it is in the format defined by
	vpo_data_hash_blank()) and returns a scalar with the opc_notify or TTI
	command line in the proper order with properly escaped values

=cut

sub vpo_tti_cli_generate {
	
	#  An example data structure
	#
	#  msgid               = "043dd610-6145-71da-03f9-4534682e0000"
	#  node                = "calntesm001.insidelive.net"
	#  node_type           = "Intel x86/Px"
	#  event_date_node     = "11/29/2005"
	#  event_time_node     = "18:00:01"
	#  event_date_mgmtsvr  = "11/29/2005"
	#  event_time_mgmtsvr  = "18:00:01"
	#  appl                = "VPO-SERVICECENTER-ALARMPOINT"
	#  message_group       = "notification"
	#  obj                 = "MESSAGE CHECKER"
	#  severity            = "major"
	#  operators           = "alarmpoint bdooley hamilti makskri nichj opc_adm rahmkha rtucholski "
	#  message_text        = "ENDTOEND"
	#  instruction_text    = ""
	#  cma                 = ""
	#  unknown             = "0"

	my $ih = shift;
	if (not $ih) {
		return 0;
	}
	
	my $retval = qq?"$ih->{'msgid'}" "$ih->{'node'}" "$ih->{'node_type'}" "$ih->{'event_date_node'}" "$ih->{'event_time_node'}" "$ih->{'event_date_mgmtsvr'}" "$ih->{'event_time_mgmtsvr'}" "$ih->{'appl'}" "$ih->{'message_group'}" "$ih->{'obj'}" "$ih->{'severity'}" "$ih->{'operators'}" "$ih->{'message_text'}" "$ih->{'instruction_text'}" "$ih->{'cma'}"?;
	
	return $retval;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 vpo_data_hash_blank()

	this returns a reference to a hash that has a blank vpo data hash

=cut

sub vpo_data_hash_blank {
	my $retval = {
		'message_group'      => '',
		'node'               => '',
		'cma'                => '',
		'message_text'       => '',
		'msgid'              => '',
		'node_type'          => '',
		'event_date_node'    => '',
		'event_time_node'    => '',
		'event_date_mgmtsvr' => '',
		'event_time_mgmtsvr' => '',
		'appl'               => '',
		'obj'                => '',
		'severity'           => '',
		'operators'          => '',
		'instruction_text'   => '',
	};
	
	return $retval;
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 vpo_annotate($vpo_msgid, $annotation_text)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#  Annotates the vpo event at $vpo_msgid with $annotation_text
	# -------------------------------------------------------------------

=cut

sub vpo_annotate {
	my ($vpo_msgid, $annotation_text) = @_;
	my $annotation_command = "/opt/OV/bin/OpC/opcannoadd";
	my $retval = 0;
	
	if (-e $annotation_command) {
	  system("$annotation_command", "$vpo_msgid", "$annotation_text");
	  $retval = 1;
	}
	
	return $retval;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 vpo_ack_event($vpo_msgid)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#  
	#  acknowledges $vpo_msgid
	#
	# -------------------------------------------------------------------

=cut

sub vpo_ack_event {
	my $vpo_msgid       = shift;
	my $vpo_ack_command = "/opt/OV/bin/OpC/opcmack";
	my $retval          = 1;
	
	if (-e $vpo_ack_command) {
	  system("$vpo_ack_command", "$vpo_msgid");
	} else {
	  $retval = 0;
	}
	  
	return $retval;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 vpo_own_event($vpo_msgid, $vpo_userid, $vpo_password)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#  
	#  owns $vpo_msgid with $vpo_userid
	#
	# -------------------------------------------------------------------

=cut

sub vpo_own_event {
	my ($vpo_msgid, $vpo_userid, $vpo_password) = @_;
	my $retval          = 1;
	my $vpo_own_cmd     = get_vpo_own_cmd();
	
	if (not $vpo_password) {
		$vpo_password = $vpo_userid;
	}
	
	my $status = `$vpo_own_cmd $vpo_userid $vpo_password $vpo_msgid`;
	
	if (not $status) {
		$status = 1;
	}
	
	return $status;
  
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_vpo_own_cmd()
	
	returns the chg_own command if it exists

=cut

sub get_vpo_own_cmd {
	
	my $chg_own_cmd = "/apps/esm/bin/chg_own";
	
	if (-e $chg_own_cmd) {
		return $chg_own_cmd;
	}
	else {
		return 0;
	}
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 parse_cma($vpo_cma)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#  parse the $cma field and retrun an array suitable for converting to a hash
	# -------------------------------------------------------------------

=cut

sub parse_cma {
	my $incoming_cma = shift;
	my (@retval, $cma_field, $cma_value);
	
	my @cma_fields = split /;;/, $incoming_cma;
	
	foreach $cma_field (@cma_fields) {
	  push @retval, split /=/, $cma_field, 2;
	}
	
	return @retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 mv_hier($node_name)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# returns: 1 at this point.
	#
	#  Enhancements to do:
	#   - clear up return value
	#   - clear up the logging options.
	#
	# -------------------------------------------------------------------

=cut

sub mv_hier {

	my $node         = shift;
	my $hier         = shift;
	my $mv_hier_pgm  = "/apps/esm/bin/mv_hier";
	my $mv_hier_opts = "-p HYPertext01 -l $hier -n $node";
   
	my $retval       = 1;

	#
	# Move the objects to the passed Node Hierarchy
	#
 
	`$mv_hier_pgm $mv_hier_opts`;
 
	return $retval;
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 vpo_node_exist($node_name)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Function: vpo_node_exist($node_name)
	#
	# Returns: the number of $node_name nodes existing in VPO 
	#
	#  Enhancements to do:
	#   - add a nslookup for the root node, if possible.
	#   - clear up the logging options.
	#
	# -------------------------------------------------------------------

=cut

sub vpo_node_exist {

	my $node           = shift;
	my $vpo_node_count = 0;
	
	  ## Clean up
	chomp($node);
	
	my $node_list = get_vpo_node_list();
	
	my $results = grep /$node/, @{$node_list};
	
	return $results;
   
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 vpo_node_add($node_name, $node_type, $hierarchy, $node_group)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Returns: 0 = problem, 1 = successfully added, 2 = node already exists
	#
	#
	#  Enhancements to do:
	#   - add a nslookup for the root node, if possible. Done: 2005-06-01, nichj
	#   - clear up the logging options.
	#   - return if $node is blank or if nslookup doesn't find host/ip. Done: 2005-06-01, nichj
	#
	# -------------------------------------------------------------------

=cut

sub vpo_node_add {

	#TODO: Convert to use variables from BGI::ESM::Common::Variables
    my  $node        = shift;
    my  $type        = shift;
    my  $HIER_NAME   = shift;
    my  $GROUP_NAME  = shift;
    my  $PROBLEM     = 0;
    my  $SUCCESS     = 1;
    my  $EXISTS      = 2;
    my  $valid_host  = 1;        # use this to trigger on a valid host name.
    my  $agent_vars  = agent_variables();
     
    my $vpo_node_pgm = $agent_vars->{'OpC_BIN'} . "/utils/opcnode";
    my ($ip, $vpo_node_opts, $logfile, $retval, $NODE_LABEL, $status, $vpo_node_count);
  
      # Clean up
    chomp($node);
  
    ## Validity check: if $node is blank then return PROBLEM
    ##
    if ($node eq "") {
      return $PROBLEM;
    }
    
  
      # See if the node already exists in VPO:
       
    ## Get the ip address for the passed node
    ##
    ##  If the ip address or the PTR record are not found, set a flag to return PROBLEM
    ##
    $node = base_node_name($node);
    
    if (not $node) { $valid_host = 0; }
    
    #
    # if the host is valid, then process the add to vpo.
    #  else return PROBLEM
	if ($valid_host) {
      
		$ip = nslookup_ip($node);                                        # slightly redundant, but much easier to deal with.
  
		$vpo_node_count = vpo_node_exist(strip_domain($node));
  
		if ($vpo_node_count == 0) {
  
        
			# Make sure the vpo node program exists.
			#
			if (-e "$vpo_node_pgm") {
			
				#
				# Attempt to add the node group just in case it is not there.
				#
			
				$vpo_node_opts = "-add_group group_name=$GROUP_NAME group_label=$GROUP_NAME";
			
				$status = system "$vpo_node_pgm $vpo_node_opts > /dev/null 2>&1";
			
				#
				# Set the node variables
				#
				$NODE_LABEL = strip_domain($node);
				$node       = add_domain($node);
			
				#
				# Add the node to OVO intially and the Node Group
				#
				$vpo_node_opts = "-add_node node_name=\"$node\" node_label=\"$NODE_LABEL\" group_name=$GROUP_NAME node_type=$type net_type=NETWORK_IP mach_type=MACH_OTHER";
				
				system "$vpo_node_pgm $vpo_node_opts";
				$status        = $?;
			
				#
				# Move the objects to the passed Node Hierarchy
				#
			
				$status = mv_hier($node,$HIER_NAME);
			
				$retval = $SUCCESS;
		  
			}
			else {
		  
				$retval = $PROBLEM;
	  
			}
         
		}
		else {
       
			# The node already exists, so log it and return $EXISTS
			$retval = $EXISTS;
       
		}
  
	}
	else {
	  
		$retval = $PROBLEM;
  
    }    
    
    return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^


=head2 vpo_message_groups()

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Description:  Calls the database query to get a list of message groups
	#
	# Returns:      a reference to an array of message groups
	#
	# Requires:     
	#
	# -------------------------------------------------------------------
	
=cut

sub vpo_message_groups {
	my $retval;
	my $sql_script = "vpo_message_groups_raw";
	
	$retval = vpo_sql_call($sql_script);
	
	if (not $retval) {
		warn "Error running script: $retval, $!\n";
		$retval = 0;
	}
	
	return $retval;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 vpo_sql_call($sql_plus_script)

	# v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v  v
	#
	# Description:  Calls the sqlplus script defined as $sql_plus_script
	#
	# Returns:      a refernce to the array of output from the sql plus script, or 0 if fails.
	#
	# Requires:     
	#
	# -------------------------------------------------------------------
	
=cut

sub vpo_sql_call {
	# TODO: use variables from module
    my $sql_plus_script = shift;
    my  $agent_vars     = agent_variables();

    my $sql_program     = $agent_vars->{'OpC_BIN'} . "/call_sqlplus.sh";
    my $sql_scripts_dir = "/etc/opt/OV/share/conf/OpC/mgmt_sv/reports/C";
    my (@sql_output, $retval, $sql_script, $sql_extension, $sql_command);
    
    if (not -e $sql_program) {
        warn "The $sql_program program doesn't exist.  Unable to continue!\n";
        return 0;
    }
    
    ($sql_script, $sql_extension) = split /\./, $sql_plus_script;
    
    if (not $sql_extension) { $sql_extension = ".sql"; }
    
    if (not -e "${sql_scripts_dir}/${sql_script}${sql_extension}") {
        warn "The ${sql_scripts_dir}/${sql_script}${sql_extension} sql script doesn't exist. Unable to continue.\n";
        return 0;
    }
    
    $sql_command = "$sql_program $sql_script";
    
    @sql_output  = `$sql_command`;
    
    return \@sql_output;

}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_remote_agent_status_command()
    returns a scalar with the ragent command
=cut

sub get_remote_agent_status_command {
    my $server_vars = server_variables();
    
    return $server_vars->{'RAGENT'};
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_remote_agent_status( $hostname )
    returns a reference to an array with the output of the ragent command
=cut

sub get_remote_agent_status {
    my $hostname = shift;
    my $ragent_cmd = get_remote_agent_status_command();
    my @output;
    
    if (not $hostname) {
        carp "get_remote_agent_status: no hostname specified!";
        return 1;
    }
    
    @output = `$ragent_cmd $hostname 2>&1 |grep -v BBC`;
    
    return \@output;
    
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 get_vpo_node_list( $filter )
	Returns refere to array with list of nodes in vpo
		NOTE: the $filter option is not implemented, yet
=cut

sub get_vpo_node_list {
	my $filter = shift;
	
	return _vpo_node_list();
	
	
}
# ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^

=head2 ovo_server_status()
    Returns a hash of the output of the ovo server status command
    
=cut

sub ovo_server_status {
    my (@retval, $ovo_server_status_cmd);
    
    $ovo_server_status_cmd = get_ovo_server_status_cmd();
    @retval = `$ovo_server_status_cmd`;
    
    return \@retval;
    
}

=head2 get_ovo_server_status_cmd()
    returns a scalar with the full ovo server status command
    
=cut

sub get_ovo_server_status_cmd {
    my $server_vars = server_variables();
    my $cmd         = $server_vars->{'OV_BIN'};
       $cmd         = "$cmd/ovstatus -c";
       
    return $cmd;
}

##############################################################################
### End of Public Methods / Functions ########################################
##############################################################################

##############################################################################
### Private Methods / Functions ##############################################
##############################################################################

sub _vpo_node_list {
	
	our (@node_list, $node_list);
	my  $threshold = 600;
	our $node_list_cache_file = _get_vpo_node_cache_filename();
	
	if ( (not -e $node_list_cache_file) or ( not file_modified_younger($node_list_cache_file, $threshold) ) ) {
		my $status = _update_node_list_cache_file();
		if (not $status) {
			carp "There was an error reading the node list cache file: $!\n";
			return 0;
		}
	}
	
	@node_list = read_file_contents($node_list_cache_file);
	
	chomp(@node_list);
	@node_list = trim(@node_list);
	
	return \@node_list;
	
	##########################################################
	sub _update_node_list_cache_file {
                my $nl_cmd = _vpo_node_list_cmd();
		my @nl = `$nl_cmd`;
		my @node_list_trans;
		
		foreach my $node (@nl) {
			if (not $node) { next; }
			my ($nodename, $extra) = split / /, $node;
			$nodename = trim($nodename);
			push @node_list_trans, $nodename;
		}

		chomp(@node_list_trans);
		
		write_file_contents($node_list_cache_file, \@node_list_trans, 'replace');

	}
	
}

sub _get_vpo_node_cache_filename {
	
	my $dir_name = "/data/esm/nodes";
	my $file_name = "vpo_node_list_cache.txt";
	
	return "$dir_name/$file_name";
}

sub _vpo_node_list_cmd {
	
	my (@node_list);
	
	my $server_vars = server_variables();
	
	my $cmd = $server_vars->{'VPO_BIN'} . "/call_sqlplus.sh";
	my $cmd_params = "all_nodes_no_header";
	
	if (not -e $cmd) {
		carp "p _vpo_node_list_cmd: Unable to find the file $cmd: $!";
		return 1;
	}
	
	return "$cmd $cmd_params";
	
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



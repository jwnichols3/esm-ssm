###################################################################
#
#             File: add_node.pl
#         Revision: 1.0
#
#           Author: Bill Dooley
#
#    Original Date: 11/04
#
#      Description: Add a nodes to OVO and to the node group entered at the command line.
#                   
#           Usage:  add_node <file name> <node group> <node hier>
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#####################################################################

#
# Set up the standard variables
#
require "/var/opt/OV/bin/OpC/cmds/setvar.pm";   
use Net::Nslookup;

#
# Set local variables
#

$LOGFILE = "$SSM_LOGS/add_node.log";

#
# Get the machines to load from the input file
#

$node       = $ARGV[0];
$type       = $ARGV[1];
$HIER_NAME  = $ARGV[2];
$GROUP_NAME = $ARGV[3];

$ip         = nslookup $node_name;

#
# Attempt to add the node group just in case it is not there.
#

$status = system "/opt/OV/bin/OpC/utils/opcnode -add_group group_name=$GROUP_NAME group_label=$GROUP_NAME > /dev/null 2>&1";

# print "Processing ip - $ip, name - $node, type - $type, group - $GROUP_NAME, Hier - $HIER_NAME\n";

#
# Set the node variables
#

($NODE_LABEL,$rest) = split(/\./,$node);

#
# Add the node to OVO intially and the Node Group
#

`echo "Adding Node $node to OVO, Node Group $GROUP_NAME." >> $LOGFILE`;

system "$OpC_BIN/utils/opcnode -add_node node_name=\"$node\" node_label=\"$NODE_LABEL\" group_name=$GROUP_NAME node_type=MESSAGE_ALLOWED net_type=NETWORK_IP mach_type=MACH_OTHER >> $LOGFILE 2>&1";

#
# Move the objects to the passed Node Hierarchy
#

# print "Moving $node to $HIER_NAME\n";
# print "$PWC_SRC/add_node/mv_hier -p HYPertext01 -l $HIER_NAME -n $node\n";
`$PWC_SRC/add_node/mv_hier -p HYPertext01 -l $HIER_NAME -n $node`;

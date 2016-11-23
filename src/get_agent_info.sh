################################################################
#
#             File: get_agent_info.sh
#         Revision: 1.0
#
#           Author: Bill Dooley
#
#    Original Date: 11/03
#
#      Description: This job will send agent information to the
#                   VPO Server
#                   
#           Usage:  get_agent_info.sh
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  11/03      wpd             <Initial Version>
###############################################################
#
# Set up the standard variables
#

OS=`uname`
case $OS in
   AIX)
      . /var/lpp/OV/OpC/cmds/setvar
   ;;
   *)
      . /var/opt/OV/bin/OpC/cmds/setvar
   ;;
esac


$PWC_BIN/get_agent_info > $PWC_LOGS/agent.info
$PWC_BIN/send_agent_info 

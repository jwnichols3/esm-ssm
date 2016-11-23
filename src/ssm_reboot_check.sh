#!/bin/ksh
################################################################
#
#             File: ssm_reboot_check.sh
#         Revision: 1.0
#
#           Author: John Nichols
#
#    Original Date: 09-2004
#
#      Description: This program will run the ssm_uptime utility
#                   
#           Usage:  ssm_reboot_check.sh
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  09-2004   nichj             <Initial Version>
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

#
# This program will run the ssm_uptime with reboot options
#
cd $SSM_BIN
if [[ -f $SSM_CONF/ssm_reboot_check.debug ]] ; then 
   $SSM_BIN/ssm_uptime --process=reboot -d >> $SSM_LOGS/ssm_reboot_check.log 2>&1
else
   $SSM_BIN/ssm_uptime --process=reboot 
fi

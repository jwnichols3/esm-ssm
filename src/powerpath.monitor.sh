################################################################
#
#             File: powerpath.monitor.sh
#         Revision: 1.01
#
#           Author: Bill Dooley
#
#    Original Date: 04/00
#
#      Description: This job will check if the san management
#                   is working properly
#                   
#           Usage:  powerpath.monitor.sh
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  11/04      wpd             <Initial Version>
#  11-2004   nichj            Changed PWC to SSM
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
# This program will run the Power Path monitor
#
if [ "$OS" = "HP-UX" ] ; then
   export UNIX95=XPG4
fi
cd $SSM_BIN
if [[ -f $SSM_CONF/powerpath.monitor.debug ]] ; then 
   $SSM_BIN/list_conf_files powerpath >> $SSM_LOGS/powerpath.monitor.log 2>&1
   echo "*********************************************" >> $SSM_LOGS/powerpath.monitor.log
   echo "*********************************************" >> $SSM_LOGS/powerpath.monitor.log
   echo "*********************************************" >> $SSM_LOGS/powerpath.monitor.log
   $SSM_BIN/powerpath.monitor >> $SSM_LOGS/powerpath.monitor.log 2>&1
else
   $SSM_BIN/powerpath.monitor
fi
$OpC_BIN/opcmon "SSM_Powerpath_Monitor=0"

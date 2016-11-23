################################################################
#
#             File: process.monitor.sh
#         Revision: 1.0
#
#           Author: Bill Dooley
#          Company: Pepperweed Consulting, LLC
#
#    Original Date: 04/00
#
#      Description: This job will check all the process/services
#                   configured in $PWC_ETC/process.dat.* to 
#                   determine if they are running or not running
#                   according to the configuration.
#                   
#           Usage:  process.monitor.sh
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  04/00      wpd             <Initial Version>
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
# This program will run the service/process monitor
#
if [ "$OS" = "HP-UX" ] ; then
   export UNIX95=XPG4
fi
cd $PWC_BIN
$PWC_BIN/process.monitor
$OpC_BIN/opcmon "SSM_Process_Monitor=0"

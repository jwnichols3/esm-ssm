################################################################
#
#             File: fileage.monitor.sh
#         Revision: 1.0
#
#           Author: Bill Dooley
#          Company: Pepperweed Consulting, LLC
#
#    Original Date: 03/04
#
#      Description: This job will check all the files
#                   configured in $PWC_ETC/fileage.dat.* 
#                   
#           Usage:  fileage.monitor.sh
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  03/04      wpd             <Initial Version>
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
# This program will run the fileage monitor
#
cd $PWC_BIN
if [[ -f $PWC_CONF/fileage.monitor.debug ]] ; then 
   $PWC_BIN/list_conf_files fileage >> $PWC_LOGS/fileage.monitor.log 2>&1
   echo "*********************************************" >> $PWC_LOGS/fileage.monitor.log
   echo "*********************************************" >> $PWC_LOGS/fileage.monitor.log
   echo "*********************************************" >> $PWC_LOGS/fileage.monitor.log
   $PWC_BIN/fileage.monitor >> $PWC_LOGS/fileage.monitor.log 2>&1
else
   $PWC_BIN/fileage.monitor
fi

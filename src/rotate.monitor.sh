################################################################
#
#             File: rotate.monitor.sh
#         Revision: 1.0
#
#           Author: Bill Dooley
#
#    Original Date: 03/04
#
#      Description: This job will rotate the log files that
#                   configured in the rotate.dat.* files.
#                   
#           Usage:  rotate.monitor.sh
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
# This program will run the rotate.monitor
#
cd $PWC_BIN
if [[ -f $PWC_CONF/rotate.monitor.debug ]] ; then 
   date >> $PWC_LOGS/rotate.monitor.log 2>&1
   $PWC_BIN/list_conf_files rotate >> $PWC_LOGS/rotate.monitor.log 2>&1
   echo "*********************************************" >> $PWC_LOGS/rotate.monitor.log
   echo "*********************************************" >> $PWC_LOGS/rotate.monitor.log
   echo "*********************************************" >> $PWC_LOGS/rotate.monitor.log
   $PWC_BIN/rotate.monitor >> $PWC_LOGS/rotate.monitor.log 2>&1
   if [[ -e /opt/OV/bin/OpC/install/opcsvinfo ]] ; then 
      echo "Archiving Event Throttle Events" 
      echo "Archiving Event Throttle Events" >> $PWC_LOGS/rotate.monitor.log
      > /var/opt/OV/log/throttle_events
      $PWC_SRC/kill_proc.sh "throttle_events"
   fi
   echo "*********************************************" >> $PWC_LOGS/rotate.monitor.log
   echo "*********************************************" >> $PWC_LOGS/rotate.monitor.log
   echo "*********************************************" >> $PWC_LOGS/rotate.monitor.log
   cat $PWC_LOGS/process.info >> $PWC_LOGS/rotate.monitor.log 2>&1
else
   $PWC_BIN/rotate.monitor
   if [[ -e /opt/OV/bin/OpC/install/opcsvinfo ]] ; then 
      echo "Archiving Event Throttle Events" 
      > /var/opt/OV/log/throttle_events
      $PWC_SRC/kill_proc.sh "throttle_events"
   fi
fi

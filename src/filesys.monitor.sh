#!/bin/ksh
###################################################################
#
#             File: filesys.monitor.sh
#         Revision: 2.50
#
#           Author: Bill Dooley
#
#    Original Date: 04/00
#
#      Description: This program will check the file space used for
#                   a particular file system, the available inodes and
#                   optionally its' growth against the configuration in
#                   $SSM_ETC/filesys.dat* files.
#                   
#           Usage:  filesys.monitor.sh  
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  04/00      wpd           <Initial Version>
#  02/05      wpd           Add the execution of the df command to
#                           inside the perl program filesys.monitor.pl
#
#  2005-04-11 nichj   2.50: Moved all nfs error checking to perl program.
#
#####################################################################

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
# Start the filesys.monitor.pl program
#
# echo "starting the filesys.monitor.pl command"
if [[ -f $SSM_CONF/filesys.monitor.debug ]] ; then
   $SSM_BIN/list_conf_files filesys >> $SSM_LOGS/filesys.monitor.log 2>&1
   echo "*********************************************" >> $SSM_LOGS/filesys.monitor.log
   echo "*********************************************" >> $SSM_LOGS/filesys.monitor.log
   echo "*********************************************" >> $SSM_LOGS/filesys.monitor.log
   $SSM_BIN/filesys.monitor >> $SSM_LOGS/filesys.monitor.log 2>&1
else
   $SSM_BIN/filesys.monitor
fi

exit 0;
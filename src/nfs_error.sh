#!/bin/ksh
###################################################################
#
#             File: df.cmd
#         Revision: 2.50
#
#           Author: Bill Dooley
#
#    Original Date: 08/01
#
#        Arguments: file to use as nfs error check semaphore.
#
#      Description: This program touches a semaphore file 
#                   (the contents of which are the PID of this program), 
#                   runs a DF command,
#                   erases the semaphore file when completed successfully.
#
#          Options: If the file $SSM_CONF/loop.test exists then loop for
#                   a period of time.
#
#           Usage:  df.cmd <nfs_error_file>
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  08/01      wpd           <Initial Version>
#
#  09/23      jwn           updated path to setvar
#
#  2005-04-11 nichj  2.50: added check for loop testing.
#                          If the file $SSM_CONF/loop.test exists then
#                          loop for a period of time.
#                          
#####################################################################

#
# Touch a temporary file that is used by filesys.monitor.pl to
# determine if there is a NFS problem.  This file is removed upon
# successful completeion of the df command.
#

nfs_error_file=${1}

# load the setvar environment variables.
#
. /var/opt/OV/bin/OpC/cmds/setvar

# place the current program PID in the semaphore file.
#
echo "$$" > "$nfs_error_file"


# If $SSM_CONF/loop.test exists then loop 500 times with a 10 second sleep
#
if [[ -s $SSM_CONF/loop.test ]] 
	then 
	integer count=1
	integer loop_times=30
	integer sleep_time=2
	print "Loop test in progress..."
	
		until [[ $count == $loop_times ]]
		do
			print "Looped $count times of $loop_times."
			sleep $sleep_time
			count=count+1
		done
fi

#
# Either way, do not hinder the functionality of this program.  Run the $DF command.
#
$DF >/dev/null

# Remove the semaphore file.
#
rm -f $nfs_error_file

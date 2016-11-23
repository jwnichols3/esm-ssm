#!/bin/ksh
###################################################################
#
#             File: addl_notification.sh
#         Revision: 1.0
#
#           Author: Bill Dooley
#          Company: Pepperweed Consulting
#
#    Original Date: 08/02
#
#      Description: This program will perform the additional 
#                   notification requested by SSM.
#                   
#           Usage:  addl_notification.sh <action> <detail>
#
# Revision History:
#
#  Date     Initials        Description of Change
#
#  08/02      wpd           <Initial Version>
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

cd $PWC_BIN

if [[ "$1" = "email" || "$1" = "emailfyi" ]] ; then 
    msg=`chg_backslash "$3"`
    echo "Action = $1  Detail = $2  Msg = $msg"
    add=`echo $2 |cut -d ";" -f1`
    sub=`echo $2 |cut -d ";" -f2`
    echo "$msg" | /usr/bin/mailx -r "OpenView_Notification" -s "$sub" "$add"
fi

exit 0

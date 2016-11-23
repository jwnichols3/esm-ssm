REM ################################################################
REM #
REM #             File: ssm_reboot_check.bat
REM #         Revision: 1.0
REM #
REM #           Author: John Nichols
REM #
REM #    Original Date: 09-2004
REM #
REM #      Description: This program will run the ssm_uptime utility
REM #                   
REM #           Usage:  ssm_reboot_check.bat
REM #
REM # Revision History:
REM #
REM #  Date     Initials        Description of Change
REM #
REM #  09-2004   nichj             <Initial Version>
REM ###############################################################
REM #
REM # Set up the standard variables
REM #
@echo off
rem 
rem Set up the debug file name
rem 

set DEBUGFILE="%OVAgentDir%\conf\ssm_reboot_check.debug"
set LOGFILE="%OVAgentDir%\log\ssm_reboot_check.log"

if not exist %DEBUGFILE% goto notfound

rem 
rem The debug file exists so capture the information
rem 

date /t   >> %LOGFILE%
time /t   >> %LOGFILE%
echo .... >> %LOGFILE%

rem 
rem Run the uptime command with appropriate options
rem 

ssm_uptime --process=reboot -d >> %LOGFILE%

echo ****************************************** >> %LOGFILE%
echo ****************************************** >> %LOGFILE%
echo ****************************************** >> %LOGFILE%

goto continue
echo on

:notfound

echo on

rem 
rem No debug file is found
rem 

ssm_uptime --process=reboot -d

:continue

exit 0

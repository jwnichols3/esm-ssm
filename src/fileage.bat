echo off
rem 
rem Set up the debug file name
rem 

set DEBUGFILE="%OVAgentDir%\conf\fileage.debug"

if not exist %DEBUGFILE% goto notfound

rem 
rem The debug file exists so capture the information
rem 

date /t >> %OVAgentDir%\log\fileage.log
time /t >> %OVAgentDir%\log\fileage.log
echo .... >> %OVAgentDir%\log\fileage.log

rem 
rem Capture the configuration files
rem 

list_conf_files process >> %OVAgentDir%\log\fileage.log

echo ****************************************** >> %OVAgentDir%\log\fileage.log
echo ****************************************** >> %OVAgentDir%\log\fileage.log
echo ****************************************** >> %OVAgentDir%\log\fileage.log

rem 
rem Run the Process Monitor
rem 

fileage >> %OVAgentDir%\log\fileage.log

echo ****************************************** >> %OVAgentDir%\log\fileage.log
echo ****************************************** >> %OVAgentDir%\log\fileage.log
echo ****************************************** >> %OVAgentDir%\log\fileage.log

rem
rem Capture the process.info file
rem 

type %OVAgentDir%\log\process.info >> %OVAgentDir%\log\fileage.log

echo ****************************************** >> %OVAgentDir%\log\fileage.log
echo ****************************************** >> %OVAgentDir%\log\fileage.log
echo ****************************************** >> %OVAgentDir%\log\fileage.log

goto continue
echo on
:notfound
echo on

rem 
rem No debug file is found
rem 

fileage

:continue

exit 0

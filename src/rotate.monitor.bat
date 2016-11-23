echo off
rem 
rem Set up the debug file name
rem 

set DEBUGFILE="%OVAgentDir%\conf\rotate.monitor.debug"

if not exist %DEBUGFILE% goto notfound

rem 
rem The debug file exists so capture the information
rem 

date /t >> %OVAgentDir%\log\rotate.monitor.log
time /t >> %OVAgentDir%\log\rotate.monitor.log
echo .... >> %OVAgentDir%\log\rotate.monitor.log

rem 
rem Capture the configuration files
rem 

list_conf_files rotate >> %OVAgentDir%\log\rotate.monitor.log

echo ****************************************** >> %OVAgentDir%\log\rotate.monitor.log
echo ****************************************** >> %OVAgentDir%\log\rotate.monitor.log
echo ****************************************** >> %OVAgentDir%\log\rotate.monitor.log

rem 
rem Run the Process Monitor
rem 

rotate.monitor >> %OVAgentDir%\log\rotate.monitor.log

echo ****************************************** >> %OVAgentDir%\log\rotate.monitor.log
echo ****************************************** >> %OVAgentDir%\log\rotate.monitor.log
echo ****************************************** >> %OVAgentDir%\log\rotate.monitor.log

rem
rem Capture the rotate.info file
rem 

type %OVAgentDir%\log\rotate.info >> %OVAgentDir%\log\rotate.monitor.log

echo ****************************************** >> %OVAgentDir%\log\rotate.monitor.log
echo ****************************************** >> %OVAgentDir%\log\rotate.monitor.log
echo ****************************************** >> %OVAgentDir%\log\rotate.monitor.log

goto continue
echo on
:notfound
echo on

rem 
rem No debug file is found
rem 

rotate.monitor

:continue

exit 0

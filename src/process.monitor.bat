echo off
rem 
rem Set up the debug file name
rem 

set DEBUGFILE="%OVAgentDir%\conf\process.monitor.debug"

if not exist %DEBUGFILE% goto notfound

rem 
rem The debug file exists so capture the information
rem 

date /t >> %OVAgentDir%\log\process.monitor.log
time /t >> %OVAgentDir%\log\process.monitor.log
echo .... >> %OVAgentDir%\log\process.monitor.log

rem 
rem Capture the configuration files
rem 

list_conf_files process >> %OVAgentDir%\log\process.monitor.log

echo ****************************************** >> %OVAgentDir%\log\process.monitor.log
echo ****************************************** >> %OVAgentDir%\log\process.monitor.log
echo ****************************************** >> %OVAgentDir%\log\process.monitor.log

rem 
rem Run the Process Monitor
rem 

process.monitor >> %OVAgentDir%\log\process.monitor.log

echo ****************************************** >> %OVAgentDir%\log\process.monitor.log
echo ****************************************** >> %OVAgentDir%\log\process.monitor.log
echo ****************************************** >> %OVAgentDir%\log\process.monitor.log

rem
rem Capture the process.info file
rem 

type %OVAgentDir%\log\process.info >> %OVAgentDir%\log\process.monitor.log

echo ****************************************** >> %OVAgentDir%\log\process.monitor.log
echo ****************************************** >> %OVAgentDir%\log\process.monitor.log
echo ****************************************** >> %OVAgentDir%\log\process.monitor.log

goto continue
echo on
:notfound
echo on

rem 
rem No debug file is found
rem 

process.monitor

:continue

exit 0

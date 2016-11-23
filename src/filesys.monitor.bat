echo off
rem 
rem Set up the debug file name
rem 

set DEBUGFILE="%OVAgentDir%\conf\filesys.monitor.debug"

if not exist %DEBUGFILE% goto notfound

rem 
rem The debug file exists so capture the information
rem 

date /t >> %OVAgentDir%\log\filesys.monitor.log
time /t >> %OVAgentDir%\log\filesys.monitor.log
echo .... >> %OVAgentDir%\log\filesys.monitor.log

rem 
rem Capture the configuration files
rem 

list_conf_files filesys >> %OVAgentDir%\log\filesys.monitor.log

echo ****************************************** >> %OVAgentDir%\log\filesys.monitor.log
echo ****************************************** >> %OVAgentDir%\log\filesys.monitor.log
echo ****************************************** >> %OVAgentDir%\log\filesys.monitor.log

rem 
rem Run the Process Monitor
rem 

filesys.monitor >> %OVAgentDir%\log\filesys.monitor.log

echo ****************************************** >> %OVAgentDir%\log\filesys.monitor.log
echo ****************************************** >> %OVAgentDir%\log\filesys.monitor.log
echo ****************************************** >> %OVAgentDir%\log\filesys.monitor.log

rem
rem Capture the filesys.info file
rem 

type %OVAgentDir%\log\filesys.info >> %OVAgentDir%\log\filesys.monitor.log

echo ****************************************** >> %OVAgentDir%\log\filesys.monitor.log
echo ****************************************** >> %OVAgentDir%\log\filesys.monitor.log
echo ****************************************** >> %OVAgentDir%\log\filesys.monitor.log

goto continue
echo on
:notfound
echo on

rem 
rem No debug file is found
rem 

filesys.monitor

:continue

exit 0

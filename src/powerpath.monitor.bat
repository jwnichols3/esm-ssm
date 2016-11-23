echo off
rem 
rem Set up the debug file name
rem 

set DEBUGFILE="%OVAgentDir%\conf\powerpath.monitor.debug"

if not exist %DEBUGFILE% goto notfound

rem 
rem The debug file exists so capture the information
rem 

date /t >> %OVAgentDir%\log\powerpath.monitor.log
time /t >> %OVAgentDir%\log\powerpath.monitor.log
echo .... >> %OVAgentDir%\log\powerpath.monitor.log

rem 
rem Capture the configuration files
rem 

list_conf_files powerpath >> %OVAgentDir%\log\powerpath.monitor.log

echo ****************************************** >> %OVAgentDir%\log\powerpath.monitor.log
echo ****************************************** >> %OVAgentDir%\log\powerpath.monitor.log
echo ****************************************** >> %OVAgentDir%\log\powerpath.monitor.log

rem 
rem Run the Power Path Monitor
rem 

powerpath.monitor >> %OVAgentDir%\log\powerpath.monitor.log

echo ****************************************** >> %OVAgentDir%\log\powerpath.monitor.log
echo ****************************************** >> %OVAgentDir%\log\powerpath.monitor.log
echo ****************************************** >> %OVAgentDir%\log\powerpath.monitor.log

rem
rem Capture the disk.info file
rem 

type %OVAgentDir%\log\disk.info >> %OVAgentDir%\log\powerpath.monitor.log

echo ****************************************** >> %OVAgentDir%\log\powerpath.monitor.log
echo ****************************************** >> %OVAgentDir%\log\powerpath.monitor.log
echo ****************************************** >> %OVAgentDir%\log\powerpath.monitor.log

goto continue
echo on
:notfound
echo on

rem 
rem No debug file is found
rem 

powerpath.monitor

:continue

exit 0

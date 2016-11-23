echo off
rem 
rem Set up the debug file name
rem 

set DEBUGFILE="%OVAgentDir%\conf\fileage.monitor.debug"

if not exist %DEBUGFILE% goto notfound

rem 
rem The debug file exists so capture the information
rem 

date /t >> %OVAgentDir%\log\fileage.monitor.log
time /t >> %OVAgentDir%\log\fileage.monitor.log
echo .... >> %OVAgentDir%\log\fileage.monitor.log

rem 
rem Capture the configuration files
rem 

list_conf_files fileage >> %OVAgentDir%\log\fileage.monitor.log

echo ****************************************** >> %OVAgentDir%\log\fileage.monitor.log
echo ****************************************** >> %OVAgentDir%\log\fileage.monitor.log
echo ****************************************** >> %OVAgentDir%\log\fileage.monitor.log

rem 
rem Run the Fileage Monitor
rem 

fileage.monitor >> %OVAgentDir%\log\fileage.monitor.log

echo ****************************************** >> %OVAgentDir%\log\fileage.monitor.log
echo ****************************************** >> %OVAgentDir%\log\fileage.monitor.log
echo ****************************************** >> %OVAgentDir%\log\fileage.monitor.log

goto continue
echo on
:notfound
echo on

rem 
rem No debug file is found
rem 

fileage.monitor

:continue

%OVAgentDir%\bin\opc\opcmon "SSM_Windows_Fileage_Monitor=0"

exit 0

date /t > %OvAgentDir%\log\svcenter_chk.log
time /t >> %OvAgentDir%\log\svcenter_chk.log
%OvAgentDir%\bin\OpC\cmds\svcenter_chk.exe >> %OvAgentDir%\log\svcenter_chk.log
exit 0

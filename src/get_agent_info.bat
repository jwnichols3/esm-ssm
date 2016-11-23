date /t > \usr\ov\log\agent.info.log
time /t >> \usr\ov\log\agent.info.log
get_agent_info > \usr\ov\log\agent.info
send_agent_info
exit 0

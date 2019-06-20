./nco_postmsg -user root -password "" "Node='ITMhost'" "AlertGroup='Ping alert'" "Identifier='example_ITM'" "Severity=5" "Manager='nco_postmsg'" "Summary='ITM host is offline'"
sleep 1
#./nco_postmsg -user root -password "" "Node='ITMhost'" "AlertGroup='test_message_agent'" "Identifier='example_ITM_1'" "Severity=5" "Manager='nco_postmsg'" "Summary='ITM host is offline'"

./nco_postmsg -user root -password "" "Node='ITMhost'" "AlertGroup='test_message_agent'" "Identifier='example_ITM_Agent1'" "Severity=5" "Manager='nco_postmsg'" "Summary='ITM Agent is offline'"
sleep 1
./nco_postmsg -user root -password "" "Node='ITMhost'" "AlertGroup='test_message_agent'" "Identifier='example_ITM_Agent2'" "Severity=5" "Manager='nco_postmsg'" "Summary='ITM Agent is offline'"
sleep 1
./nco_postmsg -user root -password "" "Node='ITMhost'" "AlertGroup='test_message_agent'" "Identifier='example_ITM_Agent3'" "Severity=5" "Manager='nco_postmsg'" "Summary='ITM Agent is offline'"
sleep 1
./nco_postmsg -user root -password "" "Node='ITMhost'" "AlertGroup='test_message_agent'" "Identifier='example_ITM_Agent4'" "Severity=5" "Manager='nco_postmsg'" "Summary='ITM Agent is offline'"
sleep 1
./nco_postmsg -user root -password "" "Node='ITMhost'" "AlertGroup='test_message_agent'" "Identifier='example_ITM_Agent5'" "Severity=5" "Manager='nco_postmsg'" "Summary='ITM Agent is offline'"

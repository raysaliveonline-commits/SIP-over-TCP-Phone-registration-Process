## 15. Troubleshooting and recovery

| Symptom | Check next | Safe response |
|---|---|---|
| LDAP user absent | Search base, enabled user, filter, bind, DirSync | Correct scope/credentials and resync |
| Telephone Number blank | AD telephoneNumber versus ipPhone mapping | Fix source/mapping; retain manual DN |
| Wrong generated extension | Automatic line mask/pool; existing DNs | Inspect associations before changing any DN |
| Test-NetConnection 5060 fails | Routing, PUB service, ACL/firewall | Diagnose the failed layer; do not globally disable firewall |
| No configuration request | Correct capture adapter, CIPC NIC/TFTP settings | Match adapter identity and server |
| Device config returns 404 | Exact requested SEP name versus CUCM record | Correct identity; do not duplicate phones blindly |
| LdapDirectories.xml 404 | Optional client directory configuration | Distinguish from a missing device config; registration succeeded here |
| SYN but no SYN-ACK | Destination availability and path | Distinguish known SUB outage from a PUB problem |
| TCP connects, SIP rejected | Response code/reason and assigned security profile | Verify Non Secure/TCP and exact phone record |
| HTTP succeeds, no REGISTER | Client configuration/load processing | Inspect client status/logs and downloaded config |
| Registered then reconnects | FIN/RST direction, service-control, logs | Preserve trace; avoid claiming a cause from timing alone |

For rollback, exit CIPC and revert only the new device/user association or profile selection to recorded prior values. Do not delete shared partitions, CSSs, LDAP agreements, device pools or trust files. No mixed-mode reversal or certificate deletion is needed for this TCP lab.

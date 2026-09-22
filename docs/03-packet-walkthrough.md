## 9. Actual startup timeline

| Original frames | Observed event | Lesson |
|---|---|---|
| 835–837 | TCP handshake, PC2:62029 → PUB:6970 | Configuration connection precedes SIP |
| 838, 840–847 | GET `/CTLSEP020000000201.tlv`; HTTP 200 and body | Trust-list retrieval in an already mixed-mode cluster; filename anonymized |
| 849–862 | GET `/SEP020000000201.cnf.xml.sgn`; HTTP 200 and signed configuration | Device-specific configuration, including 2102 and PUB/SUB preferences |
| 870–907 and subsequent body frames | Locale manifest and locale ZIP downloads | Startup includes supporting assets |
| 1731/1734, 1736/1737 | LdapDirectories.xml and DialingRules.xml return HTTP 404 | These missing files did not prevent registration in this run |
| 1748–1996 | Further CTL/config, time-zone, locale, tones and softkey requests | Preserve the whole boot sequence rather than filtering only SIP |
| 2021, 2023, 2024 | TCP handshake PC2:62034 → PUB:5060 | First SIP transport connection |
| 2022, 2036 | SYN attempts PC2:62035 → SUB:5060; no reply | No established SUB connection |
| 2025 | REGISTER for 2102, CSeq 101 REGISTER | Application requests registration |
| 2026 | TCP acknowledgement | Bytes received; not yet proof of SIP acceptance |
| 2027 | SIP 100 Trying | Provisional response |
| 2029 | SIP 200 OK, CSeq 101 REGISTER | First confirmed registration to PUB |
| 2030–2031 | REFER containing line updates and check-version | Cisco service-control content, not evidence of failover |
| 2033 | Phone responds 200 OK to REFER | Separate SIP transaction |
| 2040–2042 | PC2 FIN/ACK, PUB FIN/ACK, PC2 ACK | First observed SIP connection closes gracefully; PC2 sends the first FIN |
| 2048–2257 | Configuration and supporting files requested again | Configuration reload follows; exact trigger not established |
| 2269, 2271, 2272 | New TCP handshake PC2:62037 → PUB:5060 | New connection, new sequence spaces |
| 2273, 2275, 2277 | REGISTER CSeq 102; 100 Trying; 200 OK | Second confirmed PUB registration |
| 2278–2281 | Service-control REFER and phone's 200 OK | Registration followed by service state exchange |
| 2270, 2284, 2286, 2292, 2299 | Repeated SYN toward SUB from port 62038 | Retry spacing approximately 1, 2, 4, 8 seconds |

All public filename examples replace the real MAC. Frame references remain references to the private original, not to a supplied public pcap.

**Observed configuration:** `deviceSecurityMode=1`, `transportLayerProtocol=1`, SIP port 5060, line 2102. In this endpoint configuration these align with the Non Secure/TCP settings and are corroborated by readable SIP over TCP. Do not confuse deviceSecurityMode=1 in phone XML with Cluster Security Mode=1 in Enterprise Parameters; those fields have different meanings.

There are no UDP 5060 packets in this capture. The configuration contains other port definitions, including 5061, but presence of a port in XML does not mean that transport was used.


## 10. TCP handshake and byte accounting

Focus on the first PUB SIP connection:

| Frame | Direction | Flags | Relative SEQ | Relative ACK | Meaning |
|---|---|---|---:|---:|---|
| 2021 | PC2 → PUB | SYN | 0 | Not valid | Opens connection and offers TCP options |
| 2023 | PUB → PC2 | SYN, ACK | 0 | 1 | Acknowledges PC2 SYN and offers server options |
| 2024 | PC2 → PUB | ACK | 1 | 1 | Completes handshake |
| 2025 | PC2 → PUB | PSH, ACK | 1 | 1 | 2,192 captured TCP payload bytes carrying REGISTER |
| 2026 | PUB → PC2 | ACK | 1 | 2193 | Acknowledges that byte range |
| 2027 | PUB → PC2 | PSH, ACK | 1 | 2193 | 321 bytes carrying 100 Trying |
| 2028 | PC2 → PUB | ACK | 2193 | 322 | Acknowledges the provisional response bytes |
| 2029 | PUB → PC2 | PSH, ACK | 322 | 2193 | 1,173 bytes carrying 200 OK |

TCP counts bytes, not SIP messages. A SYN consumes one sequence number; a pure ACK consumes none. ACK 2193 means the next expected byte is 2193. Wireshark normally displays relative numbers; the actual initial client SEQ was 3278454642 and server SEQ 3524606178. Capture-side SYN→SYN-ACK elapsed time was about 9.901 ms; REGISTER→200 OK about 172.145 ms. These are observations from this capture point, not isolated server processing times.

### TCP options actually observed

| Option | PC2 SYN | PUB SYN-ACK | Interpretation |
|---|---:|---:|---|
| MSS | 1452 | 1460 | Each advertises the largest TCP payload it wants to receive per segment |
| Window Scale shift | 8 | 7 | Multipliers 256 and 128 for subsequent window advertisements |
| SACK Permitted | Yes | Yes | Both can report selectively received ranges if needed |
| TCP timestamps | Not present | Not present | Do not invent timestamp/PAWS analysis for this handshake |

The SYN window fields themselves are unscaled. Frame 2024 advertises raw window 255: 255 × 256 = 65,280 bytes. PUB frame 2026 advertises raw 263: 263 × 128 = 33,664 bytes. These are receive-window advertisements, not throughput measurements or congestion-window values.

**Endpoint capture caveat:** The captured REGISTER records contain more payload than the negotiated MSS and have an IPv4 total-length field of zero. This is consistent with host offload/capture representation. Do not claim a 2,192-byte TCP segment crossed the physical network intact. Compare a switch/SPAN capture if physical segmentation or checksum validity matters. The server ACK confirms the aggregate byte count received.

PSH is not a SIP message delimiter. The REFER spans two captured TCP records; TCP reassembly is essential. Application message boundaries come from SIP framing, including Content-Length, rather than TCP packet boundaries.


## 11. Read the SIP registration

Check the request line, Via transport, To/From extension, Contact, CSeq and matching Call-ID. Use full messages privately, but publish only sanitized teaching excerpts:

```text
REGISTER sip:192.168.10.150 SIP/2.0
Via: SIP/2.0/TCP 192.168.20.51:62034;branch=<example-branch>
From: <sip:2102@192.168.10.150>;tag=<example-tag>
To: <sip:2102@192.168.10.150>
Call-ID: <example-registration-id>
CSeq: 101 REGISTER
Expires: 3600
```

The corresponding frame 2029 response is 200 OK, **CSeq 101 REGISTER**, and **Expires 120**. CUCM grants 120 seconds despite the requested 3600; registration is time-limited and must be refreshed. This capture ends too early after the final success to prove a refresh cycle.

There is no observed 401 challenge in these two REGISTER exchanges. That matches the digest-disabled lab setup; do not invent a digest exchange. The header advertises Cisco-SIPIPCommunicator/9.1.1 while its Reason header reports load CIPC-8-6-6-0. A protocol User-Agent token alone is not reliable proof of installer version.

**TCP ACK versus SIP 200 OK:** the ACK confirms receipt of bytes by TCP. The 200 OK with the matching REGISTER transaction confirms application-level acceptance. REGISTER does not have an INVITE-style SIP ACK request following its 200 OK.


## 12. REFER, the reconnect, and the offline SUB

The REFER in frames 2030–2031 contains `Refer-To: cid:...` and multipart bodies with call-forward state, message-waiting state, and `action=check-version`. It does not instruct a transfer to 192.168.10.151. Inspect the body before assigning a meaning to a SIP method name.

PC2 sends the first FIN at 2040; a reload and second successful registration follow. The second REGISTER reports `Last=cm-closed-tcp`, but that application diagnostic does not override the observed FIN direction. Configuration-version handling is a possible explanation; proving the cause requires correlated CIPC/CUCM logs. This is not established as a registration rejection or a PUB failure.

SUB attempts begin alongside PUB connection attempts. No SYN-ACK or successful SIP registration to SUB is observed. The known powered-off state explains the lack of response operationally, but packets alone cannot distinguish an off server from a silent firewall/drop. A SYN to SUB is not itself failover. PUB accepts both registrations.

To demonstrate real failover later, first power on and verify SUB services and replication, capture a fresh baseline, then perform a controlled PUB outage in the lab. Do not infer tested redundancy from this SUB-off capture.

## 13. Wireshark student profile and exercises

Create a configuration profile named **SIP-TCP-Lab** through Edit → Configuration Profiles. Use columns No., Time, Source, Destination, Protocol, Length and Info. Add custom columns by right-clicking these TCP fields and selecting Apply as Column: source port, destination port, stream index, sequence number, acknowledgement number, TCP length, calculated window size and delta time displayed. Keep relative sequence numbers and TCP reassembly enabled.

These are display filters, not capture filters:

```wireshark
# All client IPv4 traffic
ip.addr == 192.168.20.51

# Configuration delivery
ip.addr == 192.168.20.51 && tcp.port == 6970

# HTTP requests and responses
ip.addr == 192.168.20.51 && (http.request || http.response)

# PUB SIP transport, including handshake and pure ACKs
ip.addr == 192.168.20.51 && ip.addr == 192.168.10.150 && tcp.port == 5060

# First observed PUB connection
ip.addr == 192.168.10.150 && tcp.port == 5060 && tcp.port == 62034

# Second observed PUB connection
ip.addr == 192.168.10.150 && tcp.port == 5060 && tcp.port == 62037

# REGISTER requests and matching responses
ip.addr == 192.168.20.51 && sip.CSeq.method == "REGISTER"

# Successful REGISTER responses
sip.Status-Code == 200 && sip.CSeq.method == "REGISTER"

# Service-control REFER transaction
sip.CSeq.method == "REFER"

# Offline SUB connection attempts
ip.addr == 192.168.20.51 && ip.addr == 192.168.10.151 && tcp.port == 5060

# Initial SYNs and SYN retries
ip.addr == 192.168.20.51 && tcp.flags.syn == 1 && tcp.flags.ack == 0

# Connection closure
ip.addr == 192.168.20.51 && tcp.port == 5060 && (tcp.flags.fin == 1 || tcp.flags.reset == 1)

# Analysis indications: investigate, do not assume every flag means network loss
ip.addr == 192.168.20.51 && (tcp.analysis.retransmission || tcp.analysis.fast_retransmission || tcp.analysis.duplicate_ack || tcp.analysis.zero_window)
```

Paste one expression at a time, without the explanatory comment. If HTTP is not decoded on 6970, use Analyze → Decode As → HTTP for that port. For a selected SIP connection use Follow → TCP Stream; Wireshark supplies the actual `tcp.stream` number. Do not reuse an invented stream index from another capture.

**Exercises:**

1. Find the first HTTP handshake. Which source port differs from the SIP connection?
2. Follow frame 2021's stream. Calculate the first acknowledged REGISTER byte range.
3. Explain why 100 Trying is not final registration success.
4. Match the two REGISTER/200 OK pairs by CSeq and Call-ID.
5. Reassemble the REFER. Identify check-version and explain why it does not prove transfer to SUB.
6. Measure the SUB SYN retry intervals. Identify what evidence is absent.
7. Compare the requested and granted expiry; capture a later refresh to complete the experiment.
8. Explain why downloaded CTL and signed configuration do not imply SIP signaling encryption.


## 14. Ports and terms

| Term/port | Meaning in this workflow |
|---|---|
| TCP 5060 | Plain SIP connection to CUCM; confirmed in capture |
| UDP 5060 | Alternative SIP transport; not observed here |
| TCP 6970 | HTTP configuration/asset download served by the CUCM TFTP service; confirmed |
| UDP 69 | Initial TFTP request port when actual TFTP is used; subsequent transfer uses negotiated UDP ports |
| TCP 5061 | Conventional SIP TLS port; not required for this exercise |
| TCP 3804 | CAPF certificate enrollment, used for LSC workflows; not 3084 |
| DNS 53 | Hostname lookup, normally UDP and sometimes TCP |
| LDAP 389 / LDAPS 636 | Directory integration from CUCM to AD; separate from CIPC registration |
| HTTPS 443 | Administrative/Self Care web access; browser trust is separate from phone trust |
| RTP | Call media on negotiated UDP ports; no completed audio test is proven here |
| CTIManager | Interface for CTI applications controlling/monitoring devices; not the phone's SIP registrar |
| CTI route point | Application-controlled logical call endpoint, e.g. the separate provisioning IVR workflow |
| CAPF | Certificate Authority Proxy Function; enrolls phone certificates |
| LSC | Locally Significant Certificate; not required for this nonsecure TCP setup |
| CTL / ITL | Phone trust-list mechanisms; downloading a trust list is distinct from securing SIP transport |
| UDT / ULT | Universal Device/Line Templates for provisioning; this workflow manually creates phone and DN |
| CSS / partition | Calling permissions and destination grouping |
| MSS / SACK | Maximum Segment Size / Selective Acknowledgement capability |

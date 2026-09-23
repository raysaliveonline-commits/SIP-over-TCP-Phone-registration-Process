# Extension 2102's journey: SIP rides TCP

[Repository home](../README.md) · [Wireshark profile and filters](wireshark-filters.md)

This original teaching story follows HQ-PC2-SIP (192.168.20.51), gateway 192.168.20.1, and CUCM-PUB (192.168.10.150). Read the story first, then open the filter companion. The application stays on the PC: its messages travel.

The story explains normal protocol behavior. Numerical observations come from the existing [private-capture walkthrough](../docs/03-packet-walkthrough.md); they are not a new capture. All MAC examples are generic. No capture, certificate, credential, or original device identifier is distributed.

## 1. Layer 7: the employee reads the handbook

CIPC wakes up: “I need to know who I represent, where reception is, and which language and delivery service to use.”

Windows already has an IP address. CIPC uses its configured server to retrieve its handbook. In this lab the download is HTTP over TCP 6970, including a signed XML configuration. HTTP is the request/response language, XML represents settings, and TCP carries the bytes. A TFTP server setting does not mean every file transfer uses UDP TFTP.

The handbook tells CIPC: “You represent extension 2102. Contact PUB first; SUB is another configured server. Use SIP over TCP 5060.” It does not download CUCM's complete routing database.

CIPC writes a SIP REGISTER: “Please register this identity and its contact information.” REGISTER is not INVITE. An INVITE will request a call/session later.

CIPC acts as a User Agent Client (UAC) when sending this request; CUCM acts as its responding User Agent Server (UAS), performing the registrar function. UAC/UAS describe transaction roles. CUCM can later send a request and reverse those roles.

**Watch later:** configuration filter F1; SIP registration F9.

## 2. Layers 6 and 5: representation and conversation

The OSI model helps explain responsibilities, but this stack does not add seven independent headers. SIP supplies message syntax and transaction behavior; XML supplies configuration representation. Plain SIP over TCP in this story has no TLS encryption layer. A SIP transaction or dialog is not simply “a Layer 5 header.”

## 3. Layer 4: book a reliable delivery service

CIPC asks Windows: “Connect to 192.168.10.150, TCP port 5060.”

Windows selects an available client port, such as 62037. The two IP addresses and two TCP ports identify this connection. The source port is temporary, not extension 2102 and not a permanent CIPC identifier.

TCP answers: “I provide a reliable ordered byte stream. I track missing data and control how much I send. I do not understand your SIP request.”

Before carrying the REGISTER, TCP establishes the connection. Every handshake message also traverses IP, Ethernet and the link described below.

### SYN: the first knock

PC2 says: “I want to connect. Here is my initial sequence number and the TCP options I support.”

The SYN flag starts synchronization. Wireshark commonly shows the initial sequence number as relative **0**. The actual on-wire number is not necessarily zero.

The options can include:
- **MSS (Maximum Segment Size):** the maximum TCP data size this endpoint advertises it can receive per segment. It excludes IP/TCP headers.
- **Window Scale:** how to interpret this endpoint's later receive-window advertisements.
- **SACK Permitted:** permission to report selectively received byte ranges if gaps occur.
- **Timestamps:** an optional capability, not present in the documented first handshake here.

MSS and Window Scale are directional advertisements; the two endpoints need not advertise equal values.

### SYN/ACK: reception answers

PUB says: “I acknowledge your starting sequence, and here is mine.”

With relative numbering, PUB's SYN/ACK has SEQ 0 and ACK 1. SYN consumes one sequence number even when TCP payload length is zero. PUB also advertises its options.

### ACK: the connection is ready

PC2 says: “I acknowledge your SYN too.”

Its pure ACK has relative SEQ 1 and ACK 1. A pure ACK consumes no sequence space. This completes the ordinary handshake; it does not mean SIP registration has succeeded.

**Watch later:** F3, F4, F5; inspect the selected stream to identify the third handshake ACK. An ACK flag alone does not uniquely identify it.

## 4. TCP's loading dock: payload, sequence numbers and windows

CIPC hands its REGISTER bytes to TCP. **TCP payload** is the application data carried after the TCP header. Wireshark's `tcp.len` measures its byte length; `frame.len` measures the captured frame's reported length, including other layers. Neither is “the voice codec.”

TCP numbers bytes. If data starts at relative SEQ 1 and carries 2,192 bytes, the next expected byte is **2193**. An ACK of 2193 means “I have received the preceding bytes in sequence.” It does not mean “I approved extension 2102.”

There is a separate sequence space in each direction. A response can carry both application data and an ACK for bytes received in the opposite direction.

### “How much room is left at your receiving dock?”

Each endpoint advertises a **receive window (rwnd)**. This limits the sequence range its peer may send; already outstanding bytes use part of that allowance. It is not the size of the current message, the NIC speed, or the amount of data already sent.

The TCP header's raw window field is 16 bits. When scaling is negotiated, subsequent advertisements are interpreted as:

**Calculated window = raw window × 2^scale-shift**

From the documented first connection:

| Speaker advertising room | Shift | Multiplier | Raw window | Calculated receive window | Whose data it limits |
|---|---:|---:|---:|---:|---|
| PC2 | 8 | 256 | 255 | 65,280 bytes | PUB → PC2 |
| PUB | 7 | 128 | 263 | 33,664 bytes | PC2 → PUB |

PC2 is saying: “My current receiving dock can accommodate this advertised sequence range.” It is not asking to transmit 65,280 bytes.

The window fields in SYN/SYN-ACK are **not scaled**. Each endpoint's scale applies to that endpoint's later advertisements. Capture the handshake so Wireshark can determine the multiplier.

Wireshark fields:
- `tcp.window_size_value`: raw header value.
- `tcp.window_size_scalefactor`: interpreted multiplier.
- `tcp.window_size`: calculated window in bytes.

**Flow control** protects the receiver. **Congestion control** protects the network: the sender also maintains a congestion window (cwnd), which is not an ordinary TCP header field. Actual sending is constrained by both, outstanding data and available application data. A large receive window is not proof of high throughput.

If the receiver advertises zero, the sender cannot continue ordinary new-data delivery beyond that window; TCP uses probes to detect recovery. This is a troubleshooting scenario, not a claimed event in this lab.

**Watch later:** F6 for payload, F7 for acknowledgments, F12 for flow-control indicators.

### Damaged, delayed or missing deliveries

Sequence numbers, acknowledgments and retransmission help TCP recover from missing data. SACK can describe received ranges beyond a gap. Duplicate ACKs and Wireshark retransmission labels are clues, not automatic proof of a particular network fault.

The checksum checks integrity; it does not encrypt or authenticate the application. PSH is a delivery hint, not a SIP message boundary. SIP Content-Length and message syntax enable application framing. One message may cross several segments; one segment may contain portions of multiple messages.

At the PC capture point, offload can produce records larger than negotiated MSS or apparent checksum anomalies. The existing trace has such representation caveats. Do not equate every captured record with one physical wire segment.

## 5. Layer 3: address the destination and find the next hop

IP writes: “Source 192.168.20.51, destination 192.168.10.150.”

Windows consults its routing table. The destination is outside the PC's /24 subnet, so the next hop is 192.168.20.1. Choosing TCP did not choose this route.

The IPv4 header includes source/destination IPs, TTL, and a protocol field identifying TCP (6). TTL limits how far a packet can be forwarded. Routers use destination IP and routing information, not extension 2102, to choose the next hop.

**Watch later:** F2; inspect `ip.src`, `ip.dst`, `ip.ttl`, `ip.proto`.

## 6. Layer 2: put a local address on the envelope

Ethernet asks: “Who receives this delivery on this local network?”

If needed, ARP resolves the gateway IP to a MAC address. CIPC does not ARP for the remote CUCM address across the routed subnet.

The first Ethernet frame is addressed to the gateway, while the enclosed IP packet is addressed to CUCM.

| Ethernet component | First-hop meaning |
|---|---|
| Destination MAC | Gateway's local interface |
| Source MAC | PC2's adapter |
| Optional 802.1Q tag | VLAN identification on tagged links |
| EtherType | IPv4: 0x0800; ARP has a different EtherType |
| Payload | IP header containing TCP header and application bytes |
| FCS trailer | Ethernet error detection |

Example adapter MAC **02:00:00:00:02:01** is a placeholder only. Do not configure it on your adapter.

At the router, the incoming Ethernet envelope is removed. The router forwards the IP packet, decreases TTL and wraps it for the next link. On a directly connected server LAN, the new destination MAC is CUCM's and the source MAC is the router's outgoing interface. With no NAT in this path, endpoint IPs remain the same.

MAC addresses are local-hop addressing, not application identities. All applications sharing this adapter can use the same source MAC. A MAC filter cannot isolate CIPC from its browser.

A VM's guest capture may lack VLAN tags handled by the hypervisor. Ethernet FCS is also commonly stripped before capture. Missing those fields in Wireshark does not prove the network lacks them.

**Watch later:** F13–F15; inspect Ethernet II and ARP.

## 7. Layer 1: the envelope becomes signals

Physical links transmit signals over their medium. Inside the virtual environment, virtual NICs and switches move the traffic before or instead of crossing physical links.

Wireshark decodes captured frames; it does not directly display the electrical waveform. There is no display filter that turns this capture into a Layer 1 signal measurement.

## 8. CUCM unwraps the delivery and reads the request

CUCM processes Ethernet, IP and TCP. TCP orders/reassembles bytes and supplies them to the SIP application associated with the connection.

The TCP acknowledgment means: “Your bytes reached my TCP stack.”

SIP processes REGISTER and can respond with 100 Trying followed by 200 OK. The matching **CSeq method REGISTER**, transaction identifiers and direction distinguish that success from other 200 OK responses.

The SIP response means: “Your registration succeeded.” It is not the XML configuration download. In the documented exchange, CUCM grants 120 seconds after a requested 3600 seconds, so registration needs refreshing. The short capture does not demonstrate the later refresh.

REGISTER has no INVITE-style SIP ACK request after its 200 OK. TCP ACKs still acknowledge response bytes.

CUCM subsequently sends a Cisco service-control REFER, including line state/check-version information. It now originates a request as UAC; CIPC responds as UAS. This REFER is not evidence of redirection to SUB.

**Watch later:** F9–F11. Match the request and response rather than searching only “200.”

## 9. The alternate desk and the next chapter

SUB (192.168.10.151) is configured but powered off in this experiment. Repeated unanswered SYNs are knocks at a closed desk. They do not prove successful failover. Without knowing server state, a trace alone cannot distinguish power-off from silent filtering.

When a call is placed later, INVITE/SDP will establish session/media parameters. Codecs encode/decode audio; RTP normally carries voice separately over negotiated UDP ports. Registration success does not demonstrate a completed call or two-way audio.

A FIN means one TCP direction has finished sending; RST aborts a connection. Neither is the SIP BYE method. BYE ends an established SIP session; a TCP connection may serve more than one SIP transaction.

## Read next: reveal the filters

Open [Wireshark profile and story filters](wireshark-filters.md) and follow F1–F15. Start with the whole connection, then narrow by function so that SIP display filters do not hide the TCP handshake and acknowledgments.

## Sources

- [RFC 3261: SIP](https://www.rfc-editor.org/rfc/rfc3261.html)
- [RFC 9293: TCP](https://www.rfc-editor.org/rfc/rfc9293.html)
- [RFC 7323: Window Scale](https://www.rfc-editor.org/rfc/rfc7323.html)
- [Wireshark TCP fields](https://www.wireshark.org/docs/dfref/t/tcp.html)
- [Wireshark window scaling and relative numbers](https://wiki.wireshark.org/TCP_Relative_Sequence_Numbers)
- [Cisco Ethernet frame explanation](https://www.cisco.com/en/US/docs/internetworking/troubleshooting/guide/tr1904.html)
- [SIPsense: SIP Devices in a SIP Network](https://www.youtube.com/watch?v=uTU6-gDQL_E) — related learning resource, not a transcript or source of this original story.

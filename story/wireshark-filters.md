# Wireshark companion: reveal the TCP/SIP story

[Read the OSI story first](README.md) · [Repository home](../README.md)

## Create CIPC-TCP

Edit → Configuration Profiles → copy Default → name it **CIPC-TCP**. Under Preferences → Protocols → TCP, enable sequence analysis, relative sequence numbers, and subdissector TCP stream reassembly. Menu wording may vary with Wireshark version.

Keep No., Time, Source, Destination, Protocol and Info. Add custom columns:

| Title | Field | Question answered |
|---|---|---|
| Src port | tcp.srcport | Which sending socket? |
| Dst port | tcp.dstport | Which receiving socket? |
| Stream | tcp.stream | Which TCP connection? |
| TCP payload | tcp.len | How many application bytes in this record? |
| SEQ | tcp.seq | Where do these bytes start? |
| ACK | tcp.ack | Which byte is expected next? |
| Raw window | tcp.window_size_value | What does the header actually advertise? |
| Scale factor | tcp.window_size_scalefactor | Which multiplier applies? |
| Calculated window | tcp.window_size | What receive capacity does that represent? |
| Frame length | frame.len | How large is the reported frame? |
| Display delta | frame.time_delta_displayed | How long since the previous displayed frame? |

Display delta changes when your filter changes. Window calculations require handshake context. A negative scale-factor diagnostic is not a usable multiplier.

## Capture filter: before starting

For this lesson's HTTP configuration and SIP TCP traffic, select Ethernet0 and use:

```text
host 192.168.20.51 and (host 192.168.10.150 or host 192.168.10.151) and (tcp port 5060 or tcp port 6970)
```

This captures connections, not a process identity. It excludes normal browser HTTPS but would include any application using those same endpoints/ports. It also excludes ARP, DNS, DHCP, actual UDP TFTP and voice media.

For a local addressing lesson, use the broader capture filter below, or leave the capture filter blank:

```text
arp or host 192.168.20.51
```

That broader choice can capture browser/background traffic. Keep raw captures private. A display filter hides traffic; it does not remove it from the underlying file.

## Display filters: after capture starts

Paste these in the top display-filter bar, not the capture-filter box. Save useful expressions with the filter-bar + button.

**F1 — The configuration handbook**

```wireshark
ip.addr == 192.168.20.51 && ip.addr == 192.168.10.150 && tcp.port == 6970
```

Use Follow → TCP Stream on a relevant connection. If needed use Decode As → HTTP. To narrow further, append `&& http.request` or `&& http.response.code == 200`. Those narrower views hide TCP-only records.

**F2 — The signaling journey, including TCP**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060
```

Includes PUB and SUB attempts. For PUB alone:

```wireshark
ip.addr == 192.168.20.51 && ip.addr == 192.168.10.150 && tcp.port == 5060
```

Exact connection from the documented second registration:

```wireshark
(ip.src == 192.168.20.51 && tcp.srcport == 62037 && ip.dst == 192.168.10.150 && tcp.dstport == 5060) ||
(ip.src == 192.168.10.150 && tcp.srcport == 5060 && ip.dst == 192.168.20.51 && tcp.dstport == 62037)
```

62037 is capture-specific. For a new capture, right-click a relevant packet → Follow → TCP Stream, close the stream window and retain the generated `tcp.stream == N` filter. Substitute its actual integer for N. Append conditions below to that stream filter when you want one connection only.

**F3 — SYN: the first knock**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && tcp.flags.syn == 1 && tcp.flags.ack == 0
```

Inspect MSS, Window Scale and SACK Permitted under TCP Options. Field-presence filters for options include `tcp.options.mss_val`, `tcp.options.wscale.shift`, and `tcp.options.sack_perm`.

**F4 — SYN/ACK: reception answers**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && tcp.flags.syn == 1 && tcp.flags.ack == 1
```

The initial SYN window fields are unscaled. SYN and SYN/ACK each consume one sequence number.

**F5 — ACK-only candidates**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && tcp.flags == 0x0010 && tcp.len == 0
```

This matches ordinary ACK-only records, not uniquely the third handshake packet. Identify the third ACK by stream, order, direction and SEQ/ACK. It excludes ACKs carrying additional flags such as ECE.

**F6 — The cargo: TCP payload**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && tcp.len > 0
```

Expand TCP, inspect `tcp.len` and payload bytes, and use Follow TCP Stream for reassembled text. Do not assume a segment is one complete SIP message. PSH can be selected with `tcp.flags.push == 1`, but it does not delimit SIP messages.

**F7 — Receipt acknowledgments**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && tcp.flags.ack == 1
```

Includes both pure ACKs and payload-bearing records with ACK set. The ACK number is the next expected byte in the opposite direction.

**F8 — Delivery problems and closing**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 &&
(tcp.analysis.retransmission || tcp.analysis.fast_retransmission || tcp.analysis.duplicate_ack || tcp.analysis.out_of_order)
```

Analysis labels depend on capture completeness and location. Missing results do not prove a perfect path.

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && (tcp.flags.fin == 1 || tcp.flags.reset == 1)
```

FIN ends sending in one direction; RST aborts. Inspect the surrounding stream to establish the sequence.

**F9 — The registration request**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && sip.Method == "REGISTER"
```

Inspect Via, Contact, From/To, Call-ID, CSeq and expiry. Publicly redact original device and MAC-derived identifiers.

**F10 — The application accepts registration**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && sip.Status-Code == 200 && sip.CSeq.method == "REGISTER"
```

For provisional processing:

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && sip.Status-Code == 100
```

Match the REGISTER response by transaction identifiers; a generic 200 may answer REFER or another request.

**F11 — Roles reverse: CUCM sends REFER**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 && sip.CSeq.method == "REFER"
```

This can show request and response. Inspect reassembled bodies; the documented check-version/line-state exchange does not demonstrate SUB redirection.

**F12 — The receive dock: flow control**

```wireshark
ip.addr == 192.168.20.51 && tcp.port == 5060 &&
(tcp.analysis.zero_window || tcp.analysis.window_full || tcp.analysis.window_update)
```

These are diagnostic selectors, not claims that these events occurred. For each direction inspect the three window columns. A window update alone is normal. A zero-window problem concerns receiver flow control; it is not proof of network congestion.

**F13 — Resolve the next-hop MAC**

```wireshark
arp && (arp.src.proto_ipv4 == 192.168.20.1 || arp.dst.proto_ipv4 == 192.168.20.1)
```

Requires ARP to have been captured. A cached neighbor entry may mean no fresh ARP exchange appears.

**F14 — Local Ethernet envelope**

```wireshark
eth.addr == 02:00:00:00:02:01
```

This is a **generic placeholder**. Replace privately with your own adapter MAC; do not change the adapter itself. This selects all captured traffic to/from that MAC, not just CIPC. Use `eth.src` and `eth.dst` columns to compare directions. On PC2's off-subnet traffic, destination MAC is the next-hop gateway, while destination IP is CUCM.

**F15 — VLAN and IPv4 routing details**

```wireshark
vlan.id == 20
```

Only works where tags are visible. No match on the guest capture does not prove incorrect VLAN configuration.

```wireshark
ip.addr == 192.168.20.51 && ip.proto == 6
```

Shows IPv4 TCP traffic for the PC. Inspect TTL and source/destination addresses. This also includes other TCP applications unless further narrowed.

## Quick evidence anchors

These are original private-capture frame references, not numbers to expect in a fresh capture.

| Topic | Original frame reference |
|---|---|
| Configuration handshake | 835–837 |
| First SIP SYN / SYN-ACK / ACK | 2021 / 2023 / 2024 |
| PC2 raw 255 × 256 = 65,280 | 2024 |
| PUB raw 263 × 128 = 33,664 | 2026 |
| Second SIP SYN / SYN-ACK / ACK | 2269 / 2271 / 2272 |
| Second REGISTER / Trying / OK | 2273 / 2275 / 2277 |
| SUB unanswered SYN attempts | 2270, 2284, 2286, 2292, 2299 |

For the original second handshake only:

```wireshark
frame.number in {2269 2271 2272}
```

For SUB attempts:

```wireshark
ip.addr == 192.168.20.51 && ip.addr == 192.168.10.151 && tcp.port == 5060
```

## Sources and scope

- [Wireshark TCP fields](https://www.wireshark.org/docs/dfref/t/tcp.html)
- [Wireshark SIP fields](https://www.wireshark.org/docs/dfref/s/sip.html)
- [Wireshark TCP analysis](https://www.wireshark.org/docs/wsug_html_chunked/ChAdvTCPAnalysis.html)
- [Wireshark User's Guide](https://www.wireshark.org/docs/wsug_html/)
- [RFC 7323](https://www.rfc-editor.org/rfc/rfc7323.html)

Filter field names were checked against Wireshark documentation. This addition contains no executable profile installer and no bundled capture. Paste the filters into your installed version and confirm the filter bar accepts them.

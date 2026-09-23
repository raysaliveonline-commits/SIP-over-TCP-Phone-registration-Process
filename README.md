# SIP over TCP Phone Registration Process

Build a manually provisioned CIPC SIP-over-TCP lab on CUCM 14 and Windows 11, then follow configuration downloads, TCP handshakes, SIP REGISTER, and offline-subscriber retries in Wireshark.

## 1. What this lab proves

A Windows 11 CIPC endpoint registered extension **2102** to **CUCM-PUB 192.168.10.150 using plain SIP over TCP 5060** while CUCM-SUB was powered off. Two successful REGISTER transactions are visible. This is a lab interoperability result, not a statement that Cisco certifies legacy CIPC 8.6.6 on Windows 11/CUCM 14.

Students will learn to distinguish configuration delivery, transport establishment, SIP registration, user association, and redundancy. They will interpret actual TCP options and acknowledgements rather than treating a Registered icon as the whole result.

**Evidence boundaries:** The source capture contains 2,311 frames spanning about 139.066 seconds. Frame numbers below refer to that original private capture. Packet observations are separated from configuration instructions and inferred explanations. The capture does not prove long-term stability, successful calls, audio quality, LDAP field mappings, or a completed registration refresh cycle.

## 2. Topology and public identifiers

| Component | Value | Purpose |
|---|---|---|
| HQ-PC2-SIP | 192.168.20.51 | Windows 11 CIPC and Wireshark |
| Client gateway | 192.168.20.1 | Routing from DATA VLAN20 |
| WS2016 | 192.168.10.157 | AD DS and DNS; LDAP source |
| Domain | CCIE.COLLAB | AD/DNS namespace |
| CUCM-PUB | 192.168.10.150 | Active registrar and configuration server |
| CUCM-SUB | 192.168.10.151 | Configured secondary; powered off in this experiment |
| LDAP user | HQ-CIPC-TCP | End-user ownership and Self Care |
| Extension | 2102 | Permanent manually assigned DN |
| Example MAC | 02-00-00-00-02-01 | Documentation placeholder only |
| Example device name | SEP020000000201 | SEP plus example MAC without separators |

Use your own actual adapter MAC for your lab device record. Do not change your network adapter to the example MAC. All public device names and filename examples here are anonymized; original Ethernet addresses, SIP instance identifiers, Call-IDs, certificate data and configuration UUIDs are intentionally not reproduced.

## Learning path

1. [Cucm And Ldap](docs/01-cucm-and-ldap.md)
2. [Windows And Capture](docs/02-windows-and-capture.md)
3. [Packet Walkthrough](docs/03-packet-walkthrough.md)
4. [Tcp And Sip Exercises](docs/04-tcp-and-sip-exercises.md)
5. [Troubleshooting](docs/05-troubleshooting.md)
6. [Sources](docs/06-sources.md)
7. [OSI story: Extension 2102 rides TCP](story/README.md)
8. [Story Wireshark profile and filters](story/wireshark-filters.md)

[PowerShell inspection script](scripts/Inspect-CipcTcp.ps1) · [Sanitized SIP example](examples/register-sanitized.txt)

## Capture privacy

The original packet capture is deliberately not distributed. Frame references identify observations from the private source capture; students can reproduce the exercise with their own capture. All example device identities are generic. No original screenshots, certificates, binary configuration files, credentials or MAC-derived identifiers are included.

Use your actual adapter identity in your own CUCM record; never copy the documentation MAC into a production device.

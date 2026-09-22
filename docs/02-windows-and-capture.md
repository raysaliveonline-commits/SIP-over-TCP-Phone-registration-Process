## 7. Windows 11 preflight

Use an authorized CIPC installer. The lab package is CIPC 8.6.6. Run `CiscoIPCommunicatorSetup.exe` as administrator and complete installation. The MSI is an alternative deployment package; do not install it again after the EXE. The Admin Tool is for administrative utilities, not an additional prerequisite for launching the client. Do not redistribute installers in the repository.

Run these before the teaching capture:

```powershell
hostname
Get-NetIPConfiguration
Get-NetAdapter | Select-Object Name,Status,MacAddress
Resolve-DnsName cucm-pub.ccie.collab
Resolve-DnsName cucm-sub.ccie.collab
Test-NetConnection 192.168.10.150 -Port 5060
Test-NetConnection 192.168.10.150 -Port 6970
```

Expect PC2 192.168.20.51, gateway 192.168.20.1, DNS 192.168.10.157, PUB resolving to 192.168.10.150, and successful TCP tests. A successful test proves listener reachability, not SIP registration or a valid configuration download. Test-NetConnection creates its own TCP handshake, so keep it separate from the CIPC launch capture.

Inspect existing local TCP port usage:

```powershell
Get-NetTCPConnection -LocalPort 5060 -ErrorAction SilentlyContinue |
    Select-Object LocalAddress,LocalPort,State,OwningProcess,
        @{Name='Process';Expression={
            (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        }}
```

No output while CIPC is closed is normal. Do not create port-forwarding/portproxy rules or force a local TCP source port. A UDP 5060 listener does not establish who owns TCP 5060. The earlier MicroSIP UDP conflict belongs to the UDP lab, not proof of a TCP problem here. If another process holds a needed TCP listener, identify it before changing it; do not disable the firewall globally.

After launch, inspect the actual process connections:

```powershell
Get-Process -Name communicatork9 -ErrorAction SilentlyContinue |
    ForEach-Object {
        Get-NetTCPConnection -OwningProcess $_.Id -ErrorAction SilentlyContinue
    } |
    Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State
```

Expected: a connection to PUB's remote port 5060 in Established state. Captured local ports were 62034 and later 62037; a new run can choose different ports.


## 8. Capture the first launch

1. Open Wireshark on PC2. Select Ethernet0, the adapter with 192.168.20.51.
2. Leave the capture filter blank and start capture before launching CIPC.
3. Launch CIPC, complete Audio Tuning, then open Preferences → Network.
4. Select the correct vmxnet3 adapter and verify that its generated SEP name matches CUCM.
5. Select manual TFTP servers: Server 1 = 192.168.10.150; leave Server 2 unset for this experiment.
6. Apply and wait for registration. Keep SUB off for the intended experiment.
7. Capture at least 60 seconds after success; for registration-refresh education capture several minutes more. Save all packets, not only those displayed by a filter.

The TFTP server address locates the configuration service. It does not mean every downloaded file uses the TFTP protocol, nor does it override the CM Group inside the configuration.

# Read-only inspection. Run before capture: connectivity tests create their own TCP traffic.
# Local output includes your real adapter MAC; redact before publishing.

hostname
Get-NetIPConfiguration
Get-NetAdapter | Select-Object Name,Status,MacAddress
Resolve-DnsName cucm-pub.ccie.collab
Resolve-DnsName cucm-sub.ccie.collab
Test-NetConnection 192.168.10.150 -Port 5060
Test-NetConnection 192.168.10.150 -Port 6970


Get-NetTCPConnection -LocalPort 5060 -ErrorAction SilentlyContinue |
    Select-Object LocalAddress,LocalPort,State,OwningProcess,
        @{Name='Process';Expression={
            (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
        }}


Get-Process -Name communicatork9 -ErrorAction SilentlyContinue |
    ForEach-Object {
        Get-NetTCPConnection -OwningProcess $_.Id -ErrorAction SilentlyContinue
    } |
    Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State

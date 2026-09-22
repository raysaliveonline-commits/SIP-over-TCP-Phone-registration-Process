## 3. Prerequisites and CUCM foundation

Keep CIPC closed until capture starts. Verify PUB's Cisco CallManager and Cisco Tftp services are **Started**, not merely Activated. Cisco DirSync must be running for LDAP synchronization. A powered-off SUB cannot provide redundancy during this exercise.

If these objects already exist, inspect and reuse them. The UDP/TLS labs share them; avoid changing established objects unnecessarily.

| Menu/object | Settings | Why |
|---|---|---|
| Call Routing → Class of Control → Partition | PT-HQ-INTERNAL; time schedule None | Contains permanent extensions such as 2102 |
| Same menu | PT-HQ-SERVICES; time schedule None | Contains provisioning service 2099 if retained from the earlier lab |
| Same menu → Calling Search Space | CSS-HQ-INTERNAL: PT-HQ-INTERNAL, then PT-HQ-SERVICES | Permits internal and service destinations |
| System → Cisco Unified CM Group | CMG-HQ-LAB: PUB first, SUB second | Supplies the phone's call-processing preference list |
| System → Date/Time Group | DTG-HQ-INDIA; India UTC+05:30, day/month/year, 24-hour | Supplies endpoint date/time settings |
| System → Phone NTP Reference | Existing lab references 192.168.10.1 and 192.168.10.2 | Configured references; verify these actually serve NTP before reusing |
| System → Device Pool | DP-HQ-INDIA with CMG-HQ-LAB and DTG-HQ-INDIA; existing region | Groups common endpoint settings |

The downloaded configuration confirms those device-pool, date/time, NTP-reference and CM-group names/values. It represents PUB as priority 0 and SUB as priority 1: those are the XML equivalents of first and second preference.

**Partitions contain destinations; a CSS controls which partitions a caller can search.** Neither selects SIP's transport. The planned temporary auto-registration partition/range from the earlier lab is not used here. Manually assign 2102; do not enable auto-registration or run the self-provisioning IVR for this workflow.

**Mixed mode:** The existing cluster was already in mixed mode after the TLS lab. Leave it there: it permits both secure and nonsecure phones. Plain TCP registration does not require enabling mixed mode, creating a CTL, enrolling an LSC, or restarting cluster services. `show ctl` is useful to inspect existing trust state, not a prerequisite command that makes TCP work. `show version active` records the CUCM build; `show tls min-version` concerns TLS and is not a TCP tuning command.


## 4. Create and synchronize the AD user

1. On WS2016, open Active Directory Users and Computers.
2. Create an enabled user in the **Users** container included by the existing search base. Set the logon name to `hq-cipc-tcp` and the General tab's telephone number to `2102`.
3. In CUCM, inspect **System → LDAP → LDAP System**: Microsoft AD, User ID mapped to `sAMAccountName`.
4. Open **System → LDAP → LDAP Directory → HQ LDAP**. Existing search base: `CN=Users,DC=ccie,DC=collab`; server: `192.168.10.157`. Reuse the existing working bind credentials without publishing them.
5. Verify Phone Number maps to `telephoneNumber` if that is the AD field you populated. If it maps to `ipPhone`, filling General → Telephone Number does not populate that alternate attribute.
6. Retain **Standard CCM End Users**. Administrator privileges and Standard CTI Enabled are not required for this phone's ordinary SIP registration.
7. For this manual workflow, do not request automatic DN creation from a mask or pool. The earlier agreement showed mask `1XXX`, which does not express the intended unchanged 2102 numbering. Check the agreement before synchronization; do not delete/recreate a shared LDAP agreement just to change this workflow.
8. Save and select **Perform Full Sync Now**. Verify the user in **User Management → End User** as an active LDAP-synchronized user.

**Observed roadblock:** The user synchronized, but its Telephone Number appeared blank. This did not prevent the manually provisioned phone from registering. Correct the mapping/source attribute and resynchronize separately; do not present the blank field as a successfully verified mapping. In WS2016 PowerShell, if the AD module is installed:

```powershell
Get-ADUser -Identity 'hq-cipc-tcp' -Properties telephoneNumber,ipPhone,Enabled |
    Select-Object SamAccountName,Enabled,telephoneNumber,ipPhone
```

AD Telephone Number, CUCM Primary Extension, Owner User ID and Controlled Devices have different purposes. LDAP synchronization imports directory data; it does not by itself enable LDAP password authentication for Self Care. That is configured separately under LDAP Authentication. CIPC's device registration is not a Self Care username/password login.


## 5. Create the TCP phone security profile

Open **System → Security → Phone Security Profile → Add New → Cisco IP Communicator → SIP**.

| Field | Value |
|---|---|
| Name | SIP Profile TCP |
| Description | HQ CIPC plain SIP over TCP |
| Device Security Mode | Non Secure |
| Transport Type | TCP |
| SIP Phone Port | 5060 |
| Nonce Validity Time | Keep default 600 |
| Enable Digest Authentication | Unchecked for this exercise |
| TFTP Encrypted Config | Unchecked |
| CAPF | No certificate enrollment required |

Save. The security profile controls transport/security; **Standard SIP Profile** is a different object containing SIP behavior and timers.

TCP provides ordered delivery, retransmission and flow control. Its three-way handshake does not cryptographically authenticate CUCM or encrypt SIP. CUCM Authenticated/Encrypted security modes use TLS; they are not required to obtain a TCP connection. UDP 5060 and TCP 5060 are separate transport endpoints sharing a numeric port. A client may connect from an ephemeral source port to server port 5060.


## 6. Manually create the phone and line

Go to **Device → Phone → Find**. Search for your own SEP device name first to avoid duplicates. If absent, **Add New → Cisco IP Communicator → SIP**.

| Field | Example value |
|---|---|
| Device Name | SEP020000000201 — replace with your actual lab identity |
| Description | HQ-PC2-SIP - SIP TCP - 2102 |
| Device Pool | DP-HQ-INDIA |
| Phone Button Template | Standard CIPC SIP |
| Common Phone Profile | Standard Common Phone Profile |
| Calling Search Space | CSS-HQ-INTERNAL |
| Location | Hub_None |
| Owner | User |
| Owner User ID | HQ-CIPC-TCP |
| Device Security Profile | SIP Profile TCP |
| SIP Profile | Standard SIP Profile |
| Digest User | None |
| CAPF Certificate Operation | No Pending Operation |

Save. Open **Line [1] → Add a new DN** and set:

| Field | Value |
|---|---|
| Directory Number | 2102; first check whether the exact DN/partition already exists |
| Route Partition | PT-HQ-INTERNAL |
| Calling Search Space | CSS-HQ-INTERNAL |
| Line Text Label | SIP TCP — observed in downloaded configuration |
| Display / ASCII Display | Optional descriptive caller name; blank in captured configuration |
| Line 2 | Unassigned |

Save. Associate the line with the user using **Users Associated with Line → Associate End Users**, if offered. Under **User Management → End User → HQ-CIPC-TCP → Device Association**, select the phone and save. Confirm Controlled Devices, select **Primary Extension 2102 / PT-HQ-INTERNAL**, then save.

Ownership, device association and Primary Extension support user management and Self Care. Successful SIP registration alone does not verify every association. The supplied copied form included all dropdown options rather than selected values, so it is not treated as independent proof of every GUI selection.

# Active Directory

Domain `home.lan`, NetBIOS name `HOMENET`. Forest and domain functional level Windows2016.

| | DC01 | DC02 |
|---|---|---|
| Address | 10.10.1.105 (static) | 10.10.1.106 (static) |
| Guest | VM 101 on pve | VM 123 on pve2 |
| OS | Windows Server 2022 Datacenter | Windows Server 2022 Datacenter |
| Roles | all FSMO, GC, DNS | GC, DNS |
| DNS client order | .106, then 127.0.0.1 | .105, then 127.0.0.1 |

Each DC points at its partner first and itself second.

Last health check: `repadmin /replsummary` 0 failures in both directions. `dcdiag` on DC02 passes Advertising, KnowsOfRoleHolders, NetLogons, RidManager and Services. SYSVOL and NETLOGON are shared on DC02 and DFSR logged event 4604 (initial sync done). No new errors or warnings in System or Directory Service logs on either DC.

## Building DC02

```
qm create 123 --name DC02 --bios ovmf --machine q35 --tpmstate0 ... \
  --cores 4 --memory 8192 --scsihw virtio-scsi-single --scsi0 local-lvm:60 \
  --ide2 <windows iso>,media=cdrom --ide0 <virtio-win iso>,media=cdrom --agent 1
```

1. During Windows setup, load the VirtIO SCSI driver from `vioscsi\2k22\amd64`.
2. After install, run `virtio-win-gt-x64.msi` and `virtio-win-guest-tools.exe`.
3. Static IP, DNS pointed at DC01, hostname, time zone.
4. Join the domain, sign out, sign back in as the domain administrator.
5. Promote:

```powershell
Install-ADDSDomainController -DomainName home.lan -InstallDns:$true
```

No `-Credential` parameter. The session's own domain identity does the work.

virtio-win 0.1.285 triggers a Proxmox warning about known issues. Install worked fine anyway.

## Promotion failures

Five attempts failed with error 1825 ("a security package specific error"), then 1908 ("could not enable the optional features that are enabled on the remote AD DC").

The cause was credentials. I used `DOMAIN\Administrator` with a guessed NetBIOS name that wasn't the real one, from a session signed in as the server's local Administrator. That session had no domain identity at all; `klist` failed with 0x8009030e. Signing in as the real `HOMENET\Administrator` and running the cmdlet without `-Credential` worked first try.

Run `whoami` on an existing DC to get the NetBIOS name before typing any `DOMAIN\user`.

A failed promotion rolls back to a plain member server. Before retrying, confirm DomainRole is 3, `C:\Windows\NTDS` doesn't exist, and there's no nTDSDSA object for the new server.

## Tailscale on a DC

DC01 had Tailscale installed. Two separate problems:

- It registered its 100.x address in the AD DNS zone.
- MagicDNS wrote NRPT rules and hosts file entries, which produced DNS client events 0x3F4 and 0x3FF.

Fixes:

```powershell
tailscale set --accept-dns=false
Set-DnsClient -InterfaceAlias Tailscale -RegisterThisConnectionsAddress $false
```

Then removed the 100.x records from the zone and limited the DNS server's listen addresses to the LAN IP. NRPT is empty now. `Get-ADDomainController` on DC01 can still show the Tailscale address because it resolves locally; that's cosmetic.

Keep Tailscale off domain controllers.

## Other lessons

- Don't set the partner-first DNS order on DC01 until DC02 is actually a DC. Before promotion it sent DC01's lookups to a server with no zones.
- `Resolve-DnsName` for a machine's own name returns local data. Use `-DnsOnly` and run the test from the other server to prove a DNS server answered.

## To do

- Activate Windows on DC02 once the license arrives.
- Eject the install and VirtIO ISOs from both DCs:

```
qm set 101 --ide2 none,media=cdrom
qm set 123 --ide0 none,media=cdrom
qm set 123 --ide2 none,media=cdrom
```

- Decide whether DHCP should hand out a DC as a DNS server. Probably not, since both AdGuards forward `home.lan` to both DCs.

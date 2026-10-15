# AdGuard Home

Two instances on different Proxmox nodes, so DNS survives losing either one.

| Role | Address | Guest | Node | Disk |
|---|---|---|---|---|
| Primary | 10.10.1.122 | LXC 113 `adguard` | pve2 | 10 GB |
| Secondary | 10.10.1.100 | LXC 118 `adguard2` | pve | 6 GB |

Version v0.107.79. Web UI on port 80. Upstream is Quad9 over DoH.

DHCP on both Default and IoT hands out .122 then .100. 1.1.1.1 used to be the third server and was removed; clients fell back to it silently when the primary died, which hid the outage for two days.

## Sync

adguardhome-sync v0.9.2 runs on the secondary.

- Install path `/opt/adguardhome-sync`, config `adguardhome-sync.yaml`
- systemd unit `adguardhome-sync.service`, enabled
- Runs every 10 minutes; status page on port 8080
- DHCP and TLS settings excluded

Make every change on the primary. The secondary gets overwritten.

## Local domain forwarding

Both instances have this upstream above the Quad9 line (Settings > DNS settings):

```
[/home.lan/]10.10.1.105 10.10.1.106
```

Before that, queries for the AD domain went to Quad9 and failed. Verified from a Windows client with `Resolve-DnsName -Server <adguard> -DnsOnly` for both DC A records and `_ldap._tcp.dc._msdcs.home.lan`.

## Retention

Query log and statistics: 7 days on both.

## Incident: primary down for two days

Found 2026-09-26. LXC 113's root disk (2 GB) was 100% full. AdGuardHome crash-looped about 16,900 times. `querylog.json` had grown to nearly 1 GB with unlimited retention. Clients fell back to 1.1.1.1, so nobody noticed.

Fix: grew the disk to 10 GB, restarted the service, capped retention at 7 days, removed the public fallback from DHCP, and added the secondary.

## Secondary's own DNS

The secondary's `resolv.conf` pointed at Tailscale MagicDNS (100.100.100.100) even though Tailscale isn't installed in it. It inherited that from the Proxmox host because the container was set to use host DNS. That made the backup DNS server depend on the host's tailnet. Fixed with:

```
pct set 118 --nameserver 1.1.1.1
```

## Possible next steps

- Set private reverse DNS servers (the router) so query logs show hostnames instead of IPs.

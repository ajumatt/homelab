# Changelog

## 2026-10-13

- IoT SSID encryption changed from Auto (TKIP+AES) to AES only while troubleshooting a smart plug that wouldn't join.
- Splunk Enterprise LXC added on pve3 at .50.

## 2026-10-12

- Turned off AI Roaming and Non-Stick Roaming at the site level. AI Roaming was putting AP 3's 2.4 GHz radio into client admission restriction and refusing IoT joins.
- Main SSID confirmed 5/6 GHz only.

## 2026-10-02

- DC02 promoted. Replication and dcdiag clean in both directions.
- Removed Tailscale's DNS integration on DC01 and its records from the AD zone.
- Both AdGuard instances forward the AD domain to both DCs.

## 2026-10-01

- pve3 joined the cluster. Three nodes, quorate.
- All nodes updated to PVE 9.2.21.
- Second cloudflared connector on pve3.
- Deleted the Pterodactyl panel and wings LXCs.

## 2026-09-28

- Guest agents working on DC01 and Escapepod after a Proxmox-side stop/start.
- pve2 vmbr0 made VLAN aware.

## 2026-09-27

- Proxmox: first backup job (all guests, weekly, HS-Storage). "Storage" set to `shared=0`. Nextcloud data disk excluded from backup. Old Pi-hole LXC destroyed. Escapepod disk moved to `local-lvm`.
- Secondary AdGuard: renamed to `adguard2`, own nameserver set so it no longer depends on host Tailscale DNS.
- AdGuard query log and statistics retention set to 7 days on both.
- Nextcloud: guest agent installed, AIO switched to reverse-proxy mode on 11000, tunnel route moved to plain HTTP, `trusted_proxies` set.
- Cloudflare: login rate-limiting rule; root A and `www` records deleted; SPF and DMARC reject records added.
- Omada: Device Management Hostname/IP corrected, Early Access Program off, weekly backups to SFTPGo working, SFTPGo given a reservation outside the pool, one-off config export taken.
- Blocked two unidentified clients to see what breaks.
- Doorbell connectivity: AP 2 2.4 GHz moved from ch 11 back to ch 1.

## 2026-09-26

- Found the primary AdGuard down for two days with a full disk. Disk grown, service restored.
- Secondary AdGuard added; adguardhome-sync installed. DHCP DNS set to the two AdGuards on both networks, 1.1.1.1 removed.
- Fixed the empty "AdGuard DNS" IP-port group used by the IoT permit rule.
- AP 1 uplink port changed from Block All to Allow All VLANs.
- mDNS rule for Google Cast from IoT to Default.
- IoT isolation ACL limited to New and Invalid states. New permit rule for IoT to Home Assistant and escapepod.
- 2.4 GHz Tx power 18 dBm per AP; 5 GHz narrowed from 160 to 80 MHz with separate channels.
- RSSI thresholds: 2.4 GHz off, -78 dBm on 5 and 6 GHz.
- DHCP pool collapsed to .150 to .239. Network gear moved to .1 to .19. Reservations added for servers; stale randomized-MAC reservations deleted.
- Nextcloud port forwards (80, 443) deleted; Cloudflare Tunnel created and the Nextcloud hostname routed through it.
- Controller DST set to Auto.
- Deleted an unused IP-port group left over from Pi-hole.

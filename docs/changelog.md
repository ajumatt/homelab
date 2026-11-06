# Changelog

## 2026-11-05

- glance-helper replaces the calendar-only helper on the Glance container; adds homelab endpoints for alerts, temperatures, storage, backups, Home Assistant, Wazuh, the tunnel, Omada and certificate expiry.

## 2026-11-01

- Weekly backup: DC01, Escapepod and iventoy failed with zstd write errors to the CIFS share. DC01, DC02 and iventoy backed up on manual retries. Escapepod failed again alone with an I/O error from the share.
- Splunk cleared for deletion after pve3's backup was confirmed good.

## 2026-10-31

- Wazuh watchdog on pve2: daily health check, pruning, agent report, snapshot-protected patching with rollback. First run upgraded Wazuh 4.14.8 to 4.14.9 and freed disk from 47% to 33%.
- Omada syslog to Wazuh with custom decoders and rules for DHCP leases to known, unknown and randomized MACs. "More Detail Logs" turned off on the controller.

## 2026-10-28

- pve lost its network while still running; rebooted from the console. NIC offloads turned off on pve as a precaution against an e1000e hang.
- journald on pve set to volatile so the Wazuh agent reads it correctly under log2ram.
- Wazuh agents on all three nodes, DC02 and a workstation. Agent group `proxmox` streams node journals; rule 100100 alerts on the NIC hang.
- Prometheus and Alertmanager in CT 125 with node, blackbox, pve and Windows exporters and ten alert rules, pushing to ntfy. Healthchecks.io heartbeat. Backup failures notify through a Proxmox webhook.
- Grafana started and provisioned with three dashboards.
- ProxCenter: duplicate cluster connections removed.
- Homepage stopped for retirement. Glance's Home Assistant check fixed.

## 2026-10-23

- Linkwarden joined to Tailscale (TUN passthrough on its LXC).
- Linkwarden published at `links.example.com` through the existing tunnel.
- Cloudflare Zero Trust Free set up; Access application with a one-email allow policy and one-time PIN login in front of Linkwarden.

## 2026-10-19

- AP 1 found to have never served an IoT client. Moved its 2.4 GHz channel twice and removed Wi-Fi 7 elements from its 2.4 GHz beacons; neither helped.
- IoT SSID turned off on AP 1 only. A stuck smart plug joined AP 2 within a minute. Later disabled AP 1's 2.4 GHz radio entirely.
- AP 4 (EAP653) adopted on switch port 3 as an IoT-only AP: 2.4 GHz ch 1, 18 dBm, main SSID overridden off, reservation at .14.
- Client event logging turned on in Omada (connection failed, roaming, offline, online).
- AdGuard DNS rewrite `escapepod.local` to 10.10.1.110 so Vector on the IoT VLAN can find wire-pod.

## 2026-10-18

- Vector moved to the IoT SSID at 10.10.100.50. Updated the cached robot IP in wire-pod's `botSdkInfo.json`.

## 2026-10-13

- IoT SSID encryption changed from Auto (TKIP+AES) to AES only while troubleshooting a smart plug that wouldn't join.
- Splunk Enterprise on pve3 (LXC 108) with a manual fix for the helper script's systemd unit name. Moved its reservation out of the DHCP pool to .50.

## 2026-10-12

- Turned off AI Roaming and Non-Stick Roaming at the site level. AI Roaming was putting AP 3's 2.4 GHz radio into client admission restriction and refusing IoT joins.
- Main SSID confirmed 5/6 GHz only.

## 2026-10-09

- Entra Cloud Sync device sync turned on. Domain PCs hybrid joined.
- Nextcloud registered as an Entra app for OIDC; `user_oidc` installed.

## 2026-10-08

- Entra ID tenant created with cloud-only admin and break-glass accounts. Public domain verified, UPN suffix added in AD.
- Removed a failed Entra Connect install from DC01. Cloud Sync agent installed on DC02, group-scoped, password hash sync. Pilot account first, then real users.

## 2026-10-06 to 2026-10-07

- SavaPage on pve3 (LXC 124) with PostgreSQL, localhost-only CUPS, and LDAP sync from a security group. Service account and DNS record created on DC01.

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

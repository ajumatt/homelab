# Omada controller

OC220 hardware controller at 10.10.1.5 (DHCP client with a reservation). Factory fallback address is 192.168.0.253 if it ever loses its lease.

## Firmware

Stable channel only. The controller once offered 1.7.22, which turned out to come from the Early Access Program, so that program is now turned off. Current versions:

| Device | Firmware |
|---|---|
| OC220 | 1.7.11 |
| ER707-M2 | 1.4.5 |
| SG3218XP-M2 | 1.0.27 |
| EAP787 | 1.4.3 |
| EAP650-Desktop | 1.5.6 |
| EAP775-Wall | 1.5.3 |

## Settings that were wrong

Device Management Hostname/IP (System Settings > Device Management Access) pointed at an old address in the DHCP pool. That's where a stale Inform URL came from. It now matches the controller's own address, and all five devices stayed connected through the change. The separate Controller Hostname/IP field was already right; check both.

Daylight Saving Time was disabled, so the controller clock ran an hour behind and every log timestamp was off. Set to Auto (US rules).

## "Incompatible" configuration results

Devices > Configuration Result shows Incompatible on the router and all three APs. This is informational. It lists site features a given model can't apply (SNMPv3 extensions and wireless ACL on the router; Enhanced IoT Connectivity, Conditional SSID Broadcast Control, ETH PoE Out and some management frame options on the APs). Failed count is zero. Turning off Enhanced IoT Connectivity on the IoT SSID clears most of the AP entries.

## Backups

Weekly scheduled backup: Global > Settings > Maintenance > Backup Schedule. Monday 12:00, all configuration and data items, 30 days of retained data, saved to a file server over SFTP.

The target is SFTPGo in an LXC on pve2 (10.10.1.115), listening on port 2022. Port 22 in that container is plain sshd, not SFTPGo, and backups fail if you point Omada there.

The settings page warns that scheduled backups need a USB drive on the OC220. That only applies to local backups. File-server backups work without one.

### Setup problems

Omada reports "Failed to connect to the file server" for several different causes. The one that bit here was a missing home directory for the SFTPGo user. The SFTPGo log (`journalctl -u sftpgo`) showed an invalid root path error. Fix:

```
mkdir -p /backup/omada
chown <sftpgo service user>: /backup/omada
```

The OC220's SFTP client negotiates curve25519, ed25519 and aes128-gcm, so no legacy algorithms need enabling on the server.

Take a one-off manual export (.cfg) before any firmware work regardless of the schedule.

# Wazuh

All-in-one Wazuh (manager, indexer, dashboard) in CT 117 on pve2, 10.10.1.90, installed with the community-scripts helper. Raised to 8 GB RAM and 50 GB disk. Version 4.14.9 since 2026-10-31.

## Agents

| Agent | Group | Notes |
|---|---|---|
| pve, pve2, pve3 | proxmox | Debian package, held with `apt-mark hold` |
| DC01, DC02 | default | MSI |
| one Windows workstation | default | |

Agents must never be newer than the manager. Upgrade the manager first, then on each node:

```
apt-mark unhold wazuh-agent
apt-get install wazuh-agent
apt-mark hold wazuh-agent
```

## Proxmox node journals

Group `proxmox` has a shared `agent.conf` (`/var/ossec/etc/shared/proxmox/agent.conf` on the manager) with a journald `localfile`. Every node in the group streams its systemd journal, kernel messages included, to Wazuh in real time.

Custom rule 100100 (level 10, groups `local,proxmox`) in `/var/ossec/etc/rules/local_rules.xml` matches `Detected Hardware Unit Hang` from the e1000e NIC driver. That's the message behind an earlier outage on pve (see [cluster](../proxmox/cluster.md#pve-network-outage)). Tested with `wazuh-logtest`, then end to end from pve and pve2.

### pve sent nothing at first

The agent on pve delivered zero events while pve2 and pve3 worked. `journalctl` on pve showed an old boot's last line as the newest entry.

pve runs log2ram, which keeps `/var/log` on a RAM disk and copies the journal to disk at shutdown. That copy leaves the journal files out of order. An agent that seeks to the newest entry lands on the old boot's last line and never sees anything after it.

Fix on pve only: journald set to volatile with a drop-in, `/etc/systemd/journald.conf.d/volatile.conf`:

```
[Journal]
Storage=volatile
RuntimeMaxUse=200M
```

The local journal no longer survives a reboot on pve. That's intended, since Wazuh holds the history now. Undo by deleting the drop-in and restarting systemd-journald.

## Watchdog

`/usr/local/sbin/wazuh-watch.sh` on pve2, run by `wazuh-watch.timer` every day at 07:00. Settings in `/etc/wazuh-watch.conf` (container ID, 90-day retention, 80% disk warning, 3 snapshots kept, ntfy URL, indexer password). Log at `/var/log/wazuh-watch.log`. Sends a low-priority push when everything is fine and a high-priority one on any warning or failure.

Each run:

1. Starts the container if it's stopped. Restarts the indexer, manager or dashboard if any is down.
2. Prunes alert and archive logs and indices older than 90 days. Prunes harder when the disk is over 80%.
3. Reports agents that are disconnected or never connected.
4. Takes a snapshot named `prepatch<timestamp>`, applies Debian updates and Wazuh patch releases within the same minor version, and runs `apt-get clean`.
5. Checks the services five minutes later and rolls back to the snapshot if they aren't healthy.

Minor and major Wazuh upgrades are reported, never applied automatically.

First run on 2026-10-31: 6 agents active, indexer green, 17 Debian packages and Wazuh 4.14.8 to 4.14.9 applied cleanly.

### Disk use

Before the first run the disk was at 47%. Biggest items: `/var/ossec/queue` at 11 GB (mostly the vulnerability detection feed), the apt cache at 3.3 GB, indexer data at 644 MB. Cleaning the apt cache brought it to 33%. `logall` is off.

## Omada syslog

The controller forwards syslog from the router, switch and APs to the manager on UDP 514. Controller setting: Logs > Setting > Advanced, Remote Logging on.

"More Detail Logs" on the same page is off. With it on, the APs sent per-packet client traffic lines several times a second.

### Decoders and rules

`omada_decoders.xml`, `omada_rules.xml` and a CDB list of known MACs. Rule IDs 100200 to 100220.

| Rule | Level | Meaning |
|---|---|---|
| 100201 | 0 | DHCP lease to a known MAC |
| 100202 | 8 | DHCP lease to an unknown MAC |
| 100203 | 4 | DHCP lease to a randomized (private) MAC |

The syslog header gives the device's hostname as `program_name` (for example `ER707-M2`), so the parent decoder matches on model prefixes:

```xml
<program_name>^ER|^OC|^EAP|^SG|^ES</program_name>
```

Rename a device and this line needs updating.

A real gateway line looks like this:

```
<13>Oct 31 15:05:31 ER707-M2: 2026-10-31 15:05:31 dhcp_server<5>: [OMADA]DHCP Server allocated IP address ... for the [client:xx:xx:xx:xx:xx:xx].
```

MACs arrive lowercase with colons. The decoders accept both colon and dash forms, and the known-MAC list holds both (colon keys quoted).

### Notes

- Gateway ACL rules have logging off, so no firewall hits arrive yet.
- AP 4 logs an hour behind. Site time is Eastern with DST on Auto, and the controller offers no online firmware update for that model. Low impact: Wazuh stamps alerts on receipt.
- One IoT device renewed its DHCP lease 121 times in 20 hours. Found through these rules.

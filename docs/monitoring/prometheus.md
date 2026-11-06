# Prometheus and alerting

CT 125 `prometheus` on pve2: Debian 13, unprivileged, 1 core, 1 GB RAM, 10 GB on `local-lvm`, start on boot, 10.10.1.150. Prometheus 2.53 with 90 days of retention, plus Alertmanager, node_exporter and blackbox_exporter from the Debian packages.

The first build used the arm64 template by mistake. It was destroyed and rebuilt from amd64.

## Config

Inside the container: `/etc/prometheus/prometheus.yml` and rule files in `/etc/prometheus/rules/`. Working copies live in `/root` on pve2 and get pushed in:

```
pct push 125 /root/prometheus.yml /etc/prometheus/prometheus.yml
pct exec 125 -- chmod 644 /etc/prometheus/prometheus.yml
pct exec 125 -- systemctl reload prometheus
```

Lessons from the build:

- Files in the container must be world-readable. A `umask 077` copy left the config unreadable and Prometheus refused to start (about five minutes of downtime).
- `scrape_config_files` includes didn't load on this build, so every job sits in `prometheus.yml`.
- curl treats braces in a URL as a glob. Query PromQL with `curl -G --data-urlencode 'query=...'`.

## Scrape jobs

| Job | Targets | Port |
|---|---|---|
| nodes | node_exporter on pve, pve2, pve3 and the container itself | 9100 |
| probe_tcp | Proxmox UI on all three nodes (8006), both AdGuards (53), LDAP on both DCs (389), Wazuh API (55000) | via blackbox |
| probe_http | Home Assistant, ProxCenter | via blackbox |
| pve | prometheus-pve-exporter on 127.0.0.1:9221, reading the cluster through pve2 | 9221 |
| windows | windows_exporter 0.31.9 on DC01 and DC02 | 9182 |

### pve-exporter

Runs in a venv at `/opt/pve-exporter` as the `pve-exporter` service. It uses a read-only API token (user `monitoring@pve`, token name `exporter`, role PVEAuditor at `/`, privilege separation off). The secret sits only in `/etc/pve.yml` inside the container (owner root, group pve-exporter, mode 0640).

pve-exporter can't see backup job results. Backup failures come from Proxmox's own notifications instead (below).

### windows_exporter on the DCs

Collectors: `cpu, logical_disk, memory, net, os, service, system, time, ad, dns`. The Windows firewall rule for port 9182 only allows the Prometheus host.

The `cs` collector no longer exists in 0.31.x. Listing it makes the service fail to start, and the fix is editing the service's ImagePath in the registry to drop it.

Service names in alert rules are case-sensitive: `NTDS`, `DNS`, `Kdc`, `Netlogon`, `DFSR`, `W32Time`.

## Alert rules

| File | Rule | Fires when |
|---|---|---|
| homelab.yml | NodeDown | a node_exporter target is down |
| homelab.yml | ProbeFailed | a TCP or HTTP probe fails |
| homelab.yml | DiskAlmostFull | a filesystem is over 85% |
| homelab.yml | CpuTempHigh | a CPU sensor is over 90 C |
| pve.yml | GuestStopped | a guest set to start on boot isn't running for 5 minutes |
| pve.yml | StorageAlmostFull | a Proxmox storage is over 85% |
| windows.yml | WindowsExporterDown | a DC's exporter is unreachable |
| windows.yml | DcServiceStopped | one of the six AD services above is stopped |
| windows.yml | WindowsDiskLow | under 15% free |
| windows.yml | WindowsMemoryHigh | over 90% used |

GuestStopped fires for any stopped guest that still has `onboot` set. Clear the flag on anything you stop on purpose.

## Alertmanager to ntfy

Alertmanager posts to the ntfy topic through a webhook with an ntfy message template. Repeat interval 4 hours, resolved messages on.

Tested end to end twice: stopping node_exporter on pve3 sent NodeDown and then the resolved message, and stopping W32Time on DC02 did the same for DcServiceStopped.

## Backup notifications

Proxmox can't be scraped for backup results, so it sends them itself. Under Datacenter > Notifications:

- Webhook target `ntfy`: POST to the topic, body template `{{ title }}: {{ message }}` (base64 in the config), headers Title and Priority.
- Matcher `backup-problems`: type vzdump, severity warning or error, to target `ntfy`.

The backup job uses the default notification mode, which routes through this. Tested with `pvesh` sending a test notification.

## Heartbeat

A systemd timer `hc-heartbeat.timer` in CT 125 pings a healthchecks.io check every 2 minutes, but only when Prometheus reports itself healthy. The check is set to a 5-minute period and 5-minute grace with the ntfy integration, so a power or internet outage at home still pushes an alert from outside. The ping URL is a secret and lives only in the unit file.

## Grafana

CT 100 on pve2, 10.10.1.60, Grafana 13.2.0, raised to 1 GB RAM and set to start on boot. Everything is provisioned from files:

- `/etc/grafana/provisioning/datasources/prometheus.yml`: uid `prometheus`, default data source.
- `/etc/grafana/provisioning/dashboards/homelab.yml`: folder Homelab, path `/var/lib/grafana/dashboards`.
- Dashboards 1860 (Node Exporter Full), 10347 (Proxmox via Prometheus) and 7587 (Blackbox Exporter). The `${DS_PROMETHEUS}` placeholder in each JSON file was replaced with the data source uid.

Grafana covers what ProxCenter can't see: probes, CPU temperatures, and the DCs' Windows metrics.

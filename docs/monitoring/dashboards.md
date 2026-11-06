# Dashboards

Three dashboards, each covering something the others don't. None of them sends alerts; that's Prometheus's job.

## Glance

CT 120 on pve3, 10.10.1.196, port 8080. Glance 0.8.7. Config at `/opt/glance_data/glance.yml`, with secrets in `/opt/glance_data/.env` loaded by a systemd drop-in (`/etc/systemd/system/glance.service.d/env.conf`). Login is required (auth block in `glance.yml`).

Pages:

- Home: personal feeds, calendar, news and weather.
- Homelab: Prometheus alerts and probe count, Proxmox nodes, storage with a growth forecast for the backup share, backups, guests, uptime checks, Wazuh level 10+ alerts, node temperatures, both AdGuards, the Omada network, Home Assistant, the Cloudflare tunnel, certificate expiry, and release tracking.
- Links: grouped bookmark tiles.
- Today: a one-column phone view.

### glance-helper

A small local service in the same container on 127.0.0.1:8091 (`/opt/glance-helper`) that turns other APIs into simple JSON for Glance widgets. It replaced an earlier calendar-only helper on 2026-11-05. Installed and updated with a setup script that's safe to re-run and keeps existing config.

Homelab endpoints: alerts, temps, storage, backups, ha, wazuh, tunnel, omada, certs, plus a few that feed the Home page. Each returns `ok`, `setup` or `error`, so one missing token only breaks its own widget.

Credentials (Home Assistant token, Wazuh indexer password, Cloudflare API token, Omada Open API app, private calendar addresses) sit in two config files with mode 600. Proxmox calls reuse the API token from `.env`. Temperatures, alerts and the storage growth rate come from Prometheus.

### Gotchas

- Glance substitutes `${VAR}` everywhere in the config, comments included, and refuses to start if a variable is missing from `.env`.
- Glance inserts page content with `innerHTML`, so `<script>` tags inside widgets never run. Shared JavaScript goes in `document.head`, and widgets use inline `onclick` handlers.
- YouTube channel and playlist RSS feeds return 404 on and off. Playlist feeds were 404 for every playlist tested.
- Large pastes into the Proxmox web console drop lines. Copy files to the node with `scp`, then `pct push 120`.

### Remote access

Planned at `home.example.com` through the Cloudflare tunnel. Not set up yet.

## ProxCenter

CT 119 on pve3, 10.10.1.202, port 3000. Proxmox management dashboard: 1-hour to 30-day history, inventory, topology, storage, backups, events and an audit log. Its CPU, memory and storage thresholds (80% warning, 90% critical) only color the dashboard; nothing is pushed.

It had the same cluster added three times, once per node. Two were deleted, leaving one connection through pve2. That connection is the cluster entry, so if pve2 is down ProxCenter loses the whole cluster until a connection to another node is added.

## Grafana

See [Prometheus](prometheus.md#grafana). Node Exporter Full, Proxmox via Prometheus, and Blackbox Exporter dashboards in a Homelab folder.

## Homepage (retired)

CT 112 on pve2. Glance does everything it did. Stopped on 2026-10-28 and cleared for deletion after the 2026-11-01 backup.

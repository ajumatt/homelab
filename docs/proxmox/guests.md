# Guest inventory

Default pattern is an unprivileged Debian LXC. VMs only where the OS demands it (Windows, Home Assistant OS) or for Docker hosts.

## pve

| ID | Name | Type | CPU / RAM | Disk | Address | Notes |
|---|---|---|---|---|---|---|
| 101 | DC01 | VM, OVMF, q35, TPM 2.0 | 4c / 8 GB | 100 GB | .105 | Windows Server 2022, holds all FSMO roles |
| 102 | HomeAssistant | VM, HAOS, OVMF | 2c / 4 GB | 32 GB | .56 | |
| 103 | Escapepod | VM, SeaBIOS, Ubuntu | 1c / 2 GB | 10 GB | .110 | wire-pod server for Vector ([notes](../apps/escapepod.md)) |
| 104 | Nextcloud | VM, Debian 13 | 4c / 8 GB | 32 GB + 1 TB data on HS-Storage | .251 | Nextcloud AIO in Docker |
| 105 | cloudflare-ddns | LXC | 2c / 1 GB | 3 GB | .108 | |
| 106 | cloudflared | LXC | 1c / 512 MB | 2 GB | .109 | Tunnel connector 1 |
| 118 | adguard2 | LXC | 1c / 512 MB | 6 GB | .100 | AdGuard Home secondary |

## pve2

| ID | Name | Type | CPU / RAM | Disk | Address | Notes |
|---|---|---|---|---|---|---|
| 100 | grafana | LXC | 1c / 1 GB | 4 GB | .60 | Grafana 13.2, provisioned from files ([notes](../monitoring/prometheus.md#grafana)) |
| 107 | docker | VM, Debian 13, cloud-init | 2c / 4 GB | 10 GB | .112 | Portainer |
| 109 | omnitools | LXC | 2c / 2 GB | 8 GB | .114 | |
| 110 | linkwarden | LXC, Ubuntu | 2c / 4 GB | 12 GB | .81 | on Tailscale and behind Cloudflare Access ([notes](../apps/linkwarden.md)) |
| 111 | rustdeskserver | LXC | 1c / 512 MB | 2 GB | .120 | TUN passthrough for Tailscale |
| 112 | homepage | LXC | 2c / 4 GB | 6 GB | .74 | Retired, replaced by Glance |
| 113 | adguard | LXC | 1c / 512 MB | 10 GB | .122 | AdGuard Home primary |
| 114 | iventoy | LXC, privileged | 1c / 512 MB | about 21 GB reported | .73 | full device access for PXE/USB; disk growth not yet explained |
| 115 | hermesagent | LXC | 2c / 4 GB | 20 GB | .63 | |
| 116 | ubuntu | LXC, Ubuntu | 1c / 512 MB | 2 GB | .79 | scratch box |
| 117 | wazuh | LXC | 4c / 8 GB | 50 GB | .90 | Wazuh all-in-one, daily watchdog ([notes](../monitoring/wazuh.md)) |
| 121 | sftpgo | LXC | 2c / 2 GB | 4 GB | .115 | Omada backup target |
| 123 | DC02 | VM, OVMF, q35, TPM 2.0 | 4c / 8 GB | 60 GB | .106 | second domain controller |
| 125 | prometheus | LXC, Debian 13 | 1c / 1 GB | 10 GB | .150 | Prometheus, Alertmanager, exporters ([notes](../monitoring/prometheus.md)) |

## pve3

| ID | Name | Type | CPU / RAM | Disk | Address | Notes |
|---|---|---|---|---|---|---|
| 108 | splunk | LXC | 4c / 8 GB | about 39 GB | .50 | Retired, Wazuh replaces it ([notes](../apps/splunk.md)) |
| 119 | proxcenter | LXC | 2c / 6 GB | about 9 GB | .202 | Proxmox dashboard ([notes](../monitoring/dashboards.md#proxcenter)) |
| 120 | glance | LXC | 1c / 512 MB | about 1 GB | .196 | Glance dashboard ([notes](../monitoring/dashboards.md#glance)) |
| 122 | cloudflared2 | LXC | 1c / 512 MB | 2 GB | .140 | Tunnel connector 2, restored from 106's backup |
| 124 | savapage | LXC, Debian 13 | 2c / 4 GB | 16 GB | .135 | SavaPage print management ([notes](../apps/savapage.md)) |

## Notes

- Load leans toward pve (about 22 of 31 GB RAM used versus 7 on pve2 at one count). pve3 has room, but it's the smallest node at 15.3 GB of RAM.
- pve3's guests are allocated about 19 GB against its 15.3 GB. LXC memory limits are caps, not reservations, and real use was about 28%. Retiring Splunk frees 8 GB of that allocation.
- VMIDs 119 and 120 were reused on pve3 after the Pterodactyl containers were deleted.
- iventoy is privileged with `devices.allow a` and cleared `cap.drop`. It works, but it's the least isolated guest here and an open item.
- LXCs that run Tailscale need the TUN device passed through in `/etc/pve/lxc/<id>.conf`.
- QEMU guest agent is on for every VM. Without it Proxmox can't shut a VM down cleanly or report its IPs.
- Pterodactyl panel and wings were built for a game server and later deleted.

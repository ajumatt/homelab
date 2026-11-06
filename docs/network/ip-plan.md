# IP plan

## Default network (VLAN 1, 10.10.1.0/24)

| Range | Use |
|---|---|
| .1 to .19 | Network gear: router .1, switch .2, Omada controller .5, AP 1 .11, AP 2 .12, AP 3 .13, AP 4 .14 |
| .20 to .49 | Physical hosts and fixed hardware (pve .20, pve2 .21, pve3 .22) |
| .50 to .149 | Reserved servers, VMs and fixed home devices |
| .150 to .239 | DHCP pool, single range, 90 addresses |
| .240 to .254 | Older high reservations kept where they were (desktop .240, file server .250, Nextcloud .251) |

The pool used to be split (.50 to .100 plus .150 to .200). Collapsing it to one range above .150 freed the .50 to .149 block for reservations, so every server gets a predictable address outside the pool. One camera NVR still holds a reservation at .195 inside the pool. It isn't in use, so it stays.

Network gear was moved into .1 to .19 from scattered addresses in the .50s and .60s. All four devices picked up the new reservations without re-adoption. AP 4 came up on a pool address when it was adopted and got its reservation at .14 the same evening.

## IoT network (VLAN 100, 10.10.100.0/24)

DHCP pool .10 to .100. No reservations yet. Vector sits at .50 inside the pool and needs one first, since wire-pod talks to it by IP.

## Server reservations in .50 to .149

| Address | Host |
|---|---|
| .50 | splunk (retired) |
| .52 | network printer (behind SavaPage) |
| .56 | Home Assistant (VM) |
| .60 | grafana |
| .63 | hermesagent |
| .73 | iventoy |
| .74 | homepage (retired) |
| .79 | ubuntu (test LXC) |
| .81 | linkwarden |
| .90 | wazuh |
| .100 | AdGuard Home secondary |
| .105 | DC01 |
| .106 | DC02 |
| .108 | cloudflare-ddns |
| .109 | cloudflared (tunnel connector 1) |
| .110 | escapepod |
| .112 | docker / Portainer |
| .114 | omnitools |
| .115 | sftpgo (controller backups) |
| .120 | rustdeskserver |
| .122 | AdGuard Home primary |
| .135 | savapage |
| .140 | cloudflared2 (tunnel connector 2) |

## Reservations that broke the rule

Three monitoring guests got reservations at the addresses they already had, which are inside the pool:

| Address | Host |
|---|---|
| .150 | prometheus |
| .196 | glance |
| .202 | proxcenter |

They work, but they shrink the pool and break the plan. All three should move into .50 to .149. Prometheus is the one to move carefully: blackbox probes, the DCs' firewall rules for windows_exporter, Grafana's data source and Glance all point at .150.

## Rules I follow

- Anything another device points at by IP (DNS, backup target, tunnel origin) gets a reservation outside the pool before it goes into a config. The SFTP backup target sat on a pool address for a day and had to be moved and re-pointed.
- Randomized MACs (phones with private Wi-Fi addresses) don't get reservations. Three stale ones were deleted during cleanup.

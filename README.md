# Homelab

Process documentation for a self-hosted home network and a three-node Proxmox VE cluster. These are working notes: what was built, how it's configured, what broke, and how it got fixed.

All hostnames, domains, SSIDs and addresses in this repo are placeholders. The address scheme is remapped (10.10.x.x), public domains are `example.com` / `example.net`, and the Active Directory domain is `home.lan`. No credentials, MAC addresses, public IPs or account identifiers are published.

## Stack

| Layer | What runs |
|---|---|
| Router, switch, Wi-Fi | TP-Link Omada: ER707-M2 router, SG3218XP-M2 switch, three EAPs, OC220 hardware controller |
| Hypervisor | Proxmox VE 9.2, three nodes, quorate cluster |
| DNS | Two AdGuard Home instances kept in sync with adguardhome-sync |
| Directory | Active Directory on two Windows Server 2022 domain controllers |
| Remote access | Cloudflare Tunnel with two connectors; no inbound web ports open |
| Apps | Nextcloud AIO, Home Assistant, Escapepod (wire-pod) and a handful of LXC services |

## Layout

```
docs/
  network/            IP plan, VLANs and firewall rules, Wi-Fi tuning, Omada controller
  proxmox/            cluster build, storage and backups, guest inventory, host firmware
  dns/                AdGuard Home primary/secondary and sync
  active-directory/   domain controllers, DC02 build, promotion failures
  remote-access/      Cloudflare Tunnel, Nextcloud AIO behind the tunnel
  apps/               Escapepod / wire-pod
  changelog.md        dated change log
  open-items.md       what's still unresolved
scripts/
  check-sensitive.sh  pre-push scan for anything that shouldn't be public
```

## Before pushing changes

Run `scripts/check-sensitive.sh` from the repo root. It flags real-looking private and Tailscale addresses, MAC addresses, email addresses and secrets, plus any personal terms listed in a local `.sensitive-patterns` file (that file is gitignored and never committed).

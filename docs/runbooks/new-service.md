# Adding a service

Checklist for putting a new LXC or VM into the cluster.

## Build

1. Pick a node. pve carries the most load; prefer pve2 or pve3.
2. Pick the next free VMID (`pvesh get /cluster/nextid`).
3. Unprivileged Debian LXC unless the service needs a VM. Disk on `local-lvm`.
4. If you use a community-scripts helper and it fails near the end, choose "Keep container for debugging" instead of letting it remove the container. The fix is usually one command.
5. LXC that runs Tailscale: pass the TUN device through in `/etc/pve/lxc/<id>.conf`.
6. VM: enable the QEMU guest agent in Proxmox and install it in the guest, then do a Proxmox-side stop and start. A reboot from inside the guest doesn't apply the change.

## Address and DNS

1. Find a free address in 10.10.1.50 to .149. Check the Omada client list, not just the docs.
2. Add the DHCP reservation in Omada. Never use a pool address (.150 to .239) for anything another device points at.
3. If the guest has a static IP in its Proxmox network config, the reservation does nothing. Set it with `pct set <id> --net0 ...` (keep the MAC and bridge, change `ip=` and `gw=`).
4. `pct reboot <id>` and confirm with `pct exec <id> -- ip -4 addr show eth0`.
5. If it needs a name in `home.lan`, add an A record on DC01. Both AdGuards forward the zone to the DCs.
6. If the container must resolve DNS on its own, set its nameserver explicitly. "Use host settings" inherits the host's Tailscale MagicDNS.

## Access

- Internal only: nothing more.
- Public web: add a public hostname on the Cloudflare tunnel pointing at `http://10.10.1.<x>:<port>`. Cloudflare creates the DNS record. No port forward.
- Public web, owner only: also add a Cloudflare Access application for the hostname with an allow policy, like Linkwarden. Update any base-URL setting in the app (for example `NEXTAUTH_URL`) to the public hostname.
- Remote admin only: put it on Tailscale instead. Unprivileged LXCs need the TUN passthrough lines from [Linkwarden](../apps/linkwarden.md#tailscale).
- IoT devices need to reach it: add its IP to the IP group in the "IoT to Home Assistant and escapepod" permit rule, which sits above the isolation deny.

## Credentials

Anything a helper script or installer generates (`*.creds` files, first-run admin passwords) goes into the password manager, and the file gets deleted.

## Backup

The weekly job covers all guests automatically. Exclude large data disks that live on the backup share itself with `backup=0` on that disk.

## Document

- Add the guest to [guests.md](../proxmox/guests.md) and the address to [ip-plan.md](../network/ip-plan.md).
- Add a changelog line.
- Run `scripts/check-sensitive.sh` before pushing.

## Pasting into shells

`pct enter`, `pct restore`, `su` and `exit` all consume whatever comes after them in a pasted block. Paste one shell's worth at a time. When a command prompts for input (passwords), paste only up to that command.

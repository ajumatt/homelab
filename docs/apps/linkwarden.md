# Linkwarden

Bookmark manager. LXC 110 on pve2, Ubuntu, 10.10.1.81, app on port 3000 in Docker Compose.

Two ways in from outside the house, both set up on 2026-10-23.

## Tailscale

The container is on the tailnet itself, the same way the old Pi-hole box was. It's unprivileged, so the TUN device has to be passed through first. On the Proxmox host, add to `/etc/pve/lxc/110.conf`:

```
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net dev/net none bind,create=dir
```

Then:

```
pct reboot 110
pct enter 110
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
```

Run the last two lines one at a time; `pct enter` swallows the rest of a pasted block.

The install script first failed with "could not resolve host" for tailscale.com. The container's resolver was the problem, not the container: the primary DNS server wasn't answering at that moment. Pointing the container at a public resolver got the install through:

```
echo "nameserver 1.1.1.1" > /etc/resolv.conf
```

That edit doesn't survive a container restart if Proxmox manages the file. For a permanent setting use `pct set 110 --nameserver <ip>`.

Reachable on the tailnet at its Tailscale address, port 3000.

## Cloudflare Tunnel and Access

Public hostname `links.example.com` on the existing tunnel, pointing at `http://10.10.1.81:3000`. Cloudflare created the DNS record. No port forward.

A Cloudflare Access application sits in front of it with a single allow policy for one email address, using one-time PIN login. Visiting the hostname goes to the Access login page first, and Linkwarden never sees an unauthenticated request. Details in [Cloudflare Tunnel](../remote-access/cloudflare-tunnel.md#cloudflare-access).

## Still open

`NEXTAUTH_URL` in the container's `.env` still holds the original LAN address. It was never updated for the Tailscale address either. Logins through the public hostname will likely fail until it's changed:

```
NEXTAUTH_URL=https://links.example.com/api/v1/auth
```

then, in the compose directory:

```
docker compose down && docker compose up -d
```

# VLANs and firewall rules

Two networks today: Default (VLAN 1) for trusted clients and servers, and IoT (VLAN 100) for smart-home gear. Cameras and servers are planned as their own VLANs later.

## Gateway ACLs (Omada, evaluated top-down)

| Order | Name | Source | Destination | Action | Notes |
|---|---|---|---|---|---|
| 1 | IoT to AdGuard | IoT | IP-port group "AdGuard DNS" (.122/32, .100/32, port 53) | Permit | TCP and UDP |
| 2 | IoT to Home Assistant and escapepod | IoT | IP group (.56, .110) | Permit | Home Assistant and the Vector server need to reach IoT devices and be reached by them |
| 3 | IoT isolation | IoT | Default | Deny | States type set to Manual, New and Invalid only |

Omada evaluates ACLs top-down and stops at the first match, so every permit has to sit above the deny.

The isolation rule originally blocked all states, which also dropped reply traffic for connections started from Default (Home Assistant polling a plug, a phone casting to a TV). Limiting the deny to New and Invalid lets Established and Related replies through while still stopping IoT devices from opening connections into Default.

The "AdGuard DNS" group was a leftover named after an old address. It held no IPs at all, only port 53, so the permit rule matched nothing. It now holds both AdGuard addresses.

## mDNS reflection

One rule: `_googlecast._tcp.local`, service VLAN 100, client VLAN 1. Chromecast and Google TV devices live on IoT and phones on Default still see them.

The Vector robot may need a similar rule (or an IP-based server address) to find escapepod across VLANs once it moves to IoT. See [Escapepod](../apps/escapepod.md).

## Switch trunk ports

AP uplinks must carry every VLAN. AP 1's switch port had VLAN tags set to Block All, so IoT clients associated to AP 1 never got DHCP leases. Changing it to Allow All fixed it. Check this first whenever clients on one AP get no address and clients on the others do.

## Port forwards

Only one remains: a media server port forwarded to the file server. The old Nextcloud forwards (80 and 443) were deleted after the Cloudflare Tunnel went in.

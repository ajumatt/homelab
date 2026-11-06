# Design decisions

Choices that shape the rest of the setup.

## AdGuard Home over Pi-hole

Pi-hole ran first and was retired. AdGuard Home now handles filtering with Quad9 over DoH upstream and a per-domain rule that forwards `home.lan` to the DCs. Two instances on different nodes with adguardhome-sync, changes made on the primary only.

No public resolver goes out in DHCP. With 1.1.1.1 as a fallback, the primary sat dead for two days and nobody noticed.

## Cloudflare Tunnel instead of port forwards

Web services go out through a tunnel, so the home IP isn't in public DNS and no web ports are open on the router. Two connectors on different nodes. Trade-off: Nextcloud sees every client as the connector's IP, still unsolved.

## Weekly backups, not nightly

Every guest gets a weekly snapshot backup to the SMB share, keeping 4 weekly and 3 monthly copies. Weekly was a deliberate choice over nightly.

## No ZFS replication; HA waits for a NAS

All guest disks are on node-local LVM-thin. HA can't restart a guest whose only disk is on a dead node, so HA is off. ZFS replication is the usual fix and I'm not going that route. Shared storage on a NAS comes first, then HA.

## Three nodes for quorum

Two nodes lose quorum when either goes down. pve3 fixed that, and gives room to move guests off pve.

## HA before SSO

An identity provider on a cluster without HA becomes a bigger single point of failure than the passwords it replaces. Authentik waits until HA is live.

## Break-glass access stays local

Proxmox, AdGuard and other infrastructure admin UIs keep local accounts, even after SSO. If the IdP is down, the things needed to fix it still accept a login. Same idea in Entra: one cloud-only break-glass Global Admin that doesn't depend on AD sync.

## Entra Cloud Sync over Entra Connect

Classic Connect was tried on DC01, didn't work, and was removed. Cloud Sync covers what's needed here, including hybrid join, and more than one agent can serve the same configuration for failover.

## Entra for app SSO, Authentik undecided

Entra ID Free can do OIDC and SAML for self-hosted apps, so Nextcloud SSO goes through Entra directly. Authentik might still sit in front of apps that only speak LDAP or forward-auth, with Entra as its upstream. Not decided.

## Unprivileged LXC by default

Services run as unprivileged Debian LXCs unless something forces otherwise. VMs only for Windows, Home Assistant OS, and Docker hosts. iventoy is the one privileged container, because it needs raw device access, and it's flagged as an open item.

## Reservations outside the pool

Servers get addresses in .50 to .149, almost all through Omada DHCP reservations. The two AdGuards are static; the primary drifted between leases before it was pinned. The pool (.150 to .239) is only for dynamic clients. Splunk and the SFTP backup target both landed in the pool first and had to be moved.

## Tailscale stays off domain controllers

It registers its addresses in AD DNS and rewrites name resolution with NRPT rules. See [Active Directory](active-directory/domain-controllers.md#tailscale-on-a-dc).

## A separate IoT AP instead of fixing AP 1

AP 1 rejects IoT clients for a reason that wasn't found after ruling out channel, beacon contents and the switch port. Rather than keep testing on the AP the main SSID depends on, the IoT SSID is off on AP 1 and an EAP653 nearby carries IoT only.

## Cloudflare Access in front of apps that aren't hardened for the internet

Linkwarden sits behind an Access policy, so Cloudflare blocks every request without a valid sign-in before it reaches the app. Nextcloud stays without Access and keeps the one rate-limiting rule the free plan allows.

## Prometheus for alerts, Grafana optional

Nothing else here keeps metrics over time or sends a push. Alert rules live in Prometheus and go out through Alertmanager, so they keep working with Grafana stopped. ProxCenter already charts per-guest Proxmox history; Grafana covers probes, temperatures and the DCs.

## Public ntfy.sh with a private topic

No push server to run or keep up. The random topic name is the only secret. The trade-off is that alerts need the internet, so a healthchecks.io heartbeat covers the case where the house itself goes offline.

## Wazuh as the log destination; Splunk and Homepage retired

Wazuh already collects from the nodes, the DCs and the Omada gear, and adds security rules. Splunk had no job left. Glance already showed everything Homepage did.

## Wazuh patches itself, but only patch releases

The daily watchdog snapshots the container, applies Debian updates and same-minor Wazuh releases, and rolls back if services aren't healthy five minutes later. Minor and major upgrades only get reported, because agents can't be newer than the manager and every agent is pinned.


# Cloudflare Tunnel

One tunnel, two connectors, no inbound web ports on the router.

| Connector | Guest | Node | Address |
|---|---|---|---|
| 1 | LXC 106 `cloudflared` | pve | 10.10.1.109 |
| 2 | LXC 122 `cloudflared2` | pve3 | 10.10.1.140 |

Both show Healthy in Zero Trust. cloudflared runs as a systemd service in each container.

## Second connector

Built by restoring connector 1's backup on pve3:

```
pct restore 122 <vzdump-lxc-106-...tar.zst> --storage local-lvm --unique 1
pct set 122 --hostname cloudflared2
```

`--unique 1` gives the restored container a new MAC so it doesn't collide with the original on the LAN. Both containers carry the same tunnel credentials, which is how Cloudflare treats them as replicas of one tunnel.

## Public hostnames

| Hostname | Service |
|---|---|
| cloud.example.com | `http://10.10.1.251:11000` (Nextcloud AIO, plain HTTP, no TLS options) |

New web services get a public hostname on this tunnel. Cloudflare creates the proxied DNS record. No port forwards.

Non-web services (game server, WireGuard) would need the home IP and DDNS. Nothing uses that today.

## DNS records on the zone

- The tunnel CNAME for `cloud`.
- `TXT @ "v=spf1 -all"` and `TXT _dmarc "v=DMARC1; p=reject"`. The domain sends no mail, so receiving servers reject anything spoofing it. Update SPF and relax DMARC before ever sending mail from this domain.

The root A record (pointed straight at the home IP, DNS only) and a `www` CNAME were deleted. The home IP no longer appears in public DNS.

If the root A record reappears, the cloudflare-ddns container recreated it. Remove the zone from its config or stop it.

## Rate limiting

Free plan allows one rate-limiting rule with 10-second windows:

```
(http.host eq "cloud.example.com"
 and http.request.uri.path eq "/login"
 and http.request.method eq "POST")
```

Per IP, more than 3 requests in 10 seconds blocks for 10 seconds. It covers the web login form only, not WebDAV or the desktop and mobile apps.

# Architecture

## Network and traffic paths

```mermaid
flowchart LR
  internet((Internet))
  cf[Cloudflare edge<br/>rate limit on /login]
  router[ER707-M2 router<br/>10.10.1.1]
  switch[SG3218XP-M2 switch]
  aps[AP 1 to AP 3<br/>Main SSID 5/6 GHz<br/>IoT SSID 2.4 GHz on AP 2, AP 3]
  ap4[AP 4<br/>IoT SSID only]

  subgraph default[VLAN 1 Default 10.10.1.0/24]
    pve[pve .20]
    pve2[pve2 .21]
    pve3[pve3 .22]
    clients[PCs and phones]
  end

  subgraph iot[VLAN 100 IoT 10.10.100.0/24]
    iotdev[Plugs, TVs, hubs, robot]
  end

  internet --- cf
  internet --- router
  router --- switch
  switch --- pve & pve2 & pve3
  switch --- aps
  switch --- ap4
  aps --- clients
  aps --- iotdev
  ap4 --- iotdev
  cf -. outbound tunnel .- pve
  cf -. outbound tunnel .- pve3
```

No inbound web ports are open. Both cloudflared connectors dial out to Cloudflare, and Cloudflare sends requests for public hostnames down those connections. `links.example.com` passes through Cloudflare Access first; `cloud.example.com` goes straight to Nextcloud's own login.

## DNS resolution

```mermaid
flowchart LR
  client[Client on VLAN 1 or 100] -->|DHCP DNS 1| ag1[AdGuard primary .122<br/>pve2]
  client -->|DHCP DNS 2| ag2[AdGuard secondary .100<br/>pve]
  ag1 -->|home.lan| dcs[DC01 .105 / DC02 .106]
  ag2 -->|home.lan| dcs
  ag1 -->|everything else| q9[Quad9 DoH]
  ag2 -->|everything else| q9
  ag1 -. config sync every 10 min .-> ag2
```

The two AdGuards sit on different nodes. Either node can go down and DNS keeps working.

## IoT firewall

```mermaid
flowchart TB
  iot[IoT VLAN] -->|1 permit, port 53| dns[AdGuard .122 / .100]
  iot -->|2 permit| ha[Home Assistant .56 / escapepod .110]
  iot -->|3 deny New and Invalid| def[Default VLAN]
  def -->|allowed, replies pass| iot
```

## Remote access path to Nextcloud

```mermaid
sequenceDiagram
  participant U as User
  participant CF as Cloudflare
  participant T as cloudflared (.109 or .140)
  participant C as AIO Caddy :11000
  participant A as Apache :8000
  participant P as php-fpm
  U->>CF: https://cloud.example.com
  CF->>T: over the tunnel
  T->>C: http://10.10.1.251:11000
  C->>A: localhost
  A->>P: FastCGI
```

## Monitoring

See [monitoring overview](monitoring/overview.md#how-an-alert-reaches-the-phone).

## Identity

```mermaid
flowchart LR
  ad[AD home.lan<br/>DC01 + DC02] -->|Cloud Sync agent on DC02<br/>group-scoped, password hash sync| entra[Entra ID tenant]
  pcs[Domain PCs] -->|hybrid join| entra
  entra -->|OIDC, in progress| nc[Nextcloud]
```

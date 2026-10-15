# Nextcloud

VM 104 on pve, Debian 13, 10.10.1.251. Nextcloud AIO 34.0.4 in Docker. Public name `cloud.example.com` through the Cloudflare Tunnel. Data on a 1 TB disk image stored on the file server's SMB share.

## Reverse-proxy mode

AIO originally published 80, 8080 and 8443 and managed its own Let's Encrypt certificate. After the tunnel went in, Let's Encrypt couldn't reach it and renewals started failing. Switched AIO to reverse-proxy mode so the tunnel talks plain HTTP to it.

Recreate the mastercontainer:

```
docker run -d --init --name nextcloud-aio-mastercontainer --restart always \
  -p 8080:8080 \
  -e APACHE_PORT=11000 \
  -e APACHE_IP_BINDING=0.0.0.0 \
  -e NEXTCLOUD_MOUNT=/mnt/nextcloud-data \
  --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
  --volume /var/run/docker.sock:/var/run/docker.sock:ro \
  nextcloud/all-in-one:latest
```

The old `nextcloud-aio-apache` container had to be stopped and removed by hand before AIO rebuilt it on 11000. About 15 minutes of downtime total.

Request path now: tunnel, then Caddy in `nextcloud-aio-apache` on 11000, then Apache on 127.0.0.1:8000, then php-fpm in `nextcloud-aio-nextcloud`. The web server trusts private ranges and 100.64.0.0/10 as proxies.

Consequences:

- `https://10.10.1.251` no longer works on the LAN. Use the public name everywhere.
- AIO admin interface is still `https://10.10.1.251:8080`.

## Config

- `trusted_domains`: localhost, cloud.example.com
- `trusted_proxies`: the cloudflared connector, `::1`, `172.18.0.0/16` (AIO Docker network), `127.0.0.1`

Setting slot 0 overwrote the 127.0.0.1 entry that was already there. Re-added it in slot 3. Check existing slots before setting one by index.

occ pattern:

```
docker exec --user www-data nextcloud-aio-nextcloud php occ <command>
```

Log: `/var/www/html/data/nextcloud.log` inside the container.

## Guest agent

The noVNC console doesn't support paste. With the QEMU guest agent installed and enabled (`qm set 104 --agent enabled=1`, then a cold restart), commands can run from the pve shell instead:

```
qm guest exec 104 -- <command>
```

## Unresolved: every login logs as the tunnel connector's IP

Nextcloud records every remote login as coming from the cloudflared container, in both the old 443 mode and reverse-proxy mode. Tested with deliberate failed WebDAV logins and grepping the log for "Login failed".

- Adding `HTTP_CF_CONNECTING_IP` and `HTTP_X_FORWARDED_FOR` to `forwarded_for_headers` changed nothing; removed again.
- A fake `CF-Connecting-IP` header sent directly to the origin was ignored too, which puts the loss somewhere between Caddy/Apache and PHP.

Parked in favor of the Cloudflare rate-limiting rule. Next step if I come back to it: find AIO Apache's access log (`grep CustomLog /usr/local/apache2/conf/nextcloud.conf` in `nextcloud-aio-apache`) and see what X-Forwarded-For actually arrives.

## Recovery note

Root password on this VM was reset through GRUB with `init=/bin/bash`. Same procedure as [Escapepod](../apps/escapepod.md#lost-password).

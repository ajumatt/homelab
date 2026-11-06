# Open items

## Network

- Confirm Monday's scheduled controller backup lands in `/backup/omada` on the SFTPGo container.
- Watch the doorbell. It sees about -75 dBm from every AP, so if drops continue the answer is an AP closer to the front door, not more settings.
- Finish the IoT migration ([list](network/iot-migration.md)). Power-cycle IoT devices near AP 1 so they move to AP 4.
- IoT DHCP reservation for Vector at .50.
- Check for an EAP653 firmware update.
- Consider bringing AP 2 and AP 3 to 18 dBm on 2.4 GHz.
- AP 1: find out why it rejects IoT clients (reboot, newer EAP787 firmware), or leave it as is now that AP 4 covers the area.
- A game console flapped on and off AP 1 on DFS channel 100 before settling on AP 2. Watch for other drops on AP 1.
- Optional: turn off Enhanced IoT Connectivity on the IoT SSID to clear the Incompatible flags.
- Future VLANs: cameras, then servers.

## DNS

- Check the Proxmox hosts' own DNS (Tailscale MagicDNS) and make sure the tailnet's DNS settings don't rely on only one AdGuard.
- Private reverse DNS on the primary AdGuard.

## Proxmox

- Backups to the CIFS share keep failing ([details](proxmox/storage-and-backups.md#backup-failures-on-the-cifs-share)). Get Escapepod a backup, split the job per node, and find out why the file server returns I/O errors.
- Pick a storage option ([options](proxmox/storage-and-backups.md#storage-plan-not-decided)). Nextcloud's data disk has no backup until then.
- Clear `onboot` on anything stopped on purpose so GuestStopped stays quiet.
- Find out why iventoy reports about 21 GB of disk.
- Confirm the e1000e offload fix holds on pve. Delete the old journal copy in `/root` when no longer needed.
- Decide what the `ubuntu` scratch container (116) is for, or retire it.
- Rebalance load from pve onto pve3.
- NAS for shared storage, then HA.
- Nextcloud data still lives on the file server's SMB share.
- iventoy runs privileged with full device access.

## Monitoring

- Move the six reservations that sit in the DHCP pool (prometheus, glance, proxcenter, it-tools, syncthing, vaultwarden) into the server range ([details](network/ip-plan.md#reservations-that-broke-the-rule)).
- Check the cloudflared connectors from outside (an HTTP probe of a public hostname, or the tunnel's metrics port).
- Forward Wazuh level 10 alerts to ntfy so rule 100100 pages the phone.
- Omada syslog: confirm the AP traffic flood stopped and gateway DHCP lines still arrive; add rules for controller site events, admin logins and WAN events.
- Prometheus `predict_linear` alert on the backup share, to warn well before the 85% rule.
- Optional: a Grafana dashboard for the DCs.
- Glance remote access at `home.example.com`.

## Active Directory

- Activate Windows on DC02.
- Eject ISOs from both DCs.

## Identity

- Second Cloud Sync agent on DC01.
- Retire the pilot sync account.
- Finish Nextcloud SSO through Entra (username mapping, then provider config).
- Decide whether Authentik is still needed.

## Apps

- Clean up SavaPage leftovers in AD (service account, security group, DNS record) if it isn't coming back.
- Escapepod: confirm the DNS rewrite lets Vector reach wire-pod from the IoT VLAN; fall back to a hidden Default SSID on AP 4 if not.
- Escapepod: build and test the recognition patch on a real robot.
- Linkwarden: update `NEXTAUTH_URL` to the public hostname and restart the stack.

## Remote access

- Nextcloud logs every login as the tunnel connector's IP ([details](remote-access/nextcloud.md#unresolved-every-login-logs-as-the-tunnel-connectors-ip)).
- Confirm what the cloudflare-ddns container updates, and stop it if nothing needs the home IP.
- SPF and DMARC reject records on the second domain if it doesn't send mail.

## Later

- Authentik, if still wanted after Entra SSO, only after HA is live. Proxmox and AdGuard admin stay on local auth so they still work if SSO breaks.

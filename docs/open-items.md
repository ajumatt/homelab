# Open items

## Network

- Confirm Monday's scheduled controller backup lands in `/backup/omada` on the SFTPGo container.
- Watch the doorbell after the AP 2 channel fix. It sees about -75 dBm from every AP, so if drops continue the answer is an AP closer to the front door, not more settings. Re-check every AP's 2.4 GHz channel and power against the plan.
- Finish the IoT migration ([list](network/iot-migration.md)). Vector and one smart plug still can't join.
- Turn on client event logging in Omada.
- Optional: turn off Enhanced IoT Connectivity on the IoT SSID to clear the Incompatible flags.
- Future VLANs: cameras, then servers.

## DNS

- Check the Proxmox hosts' own DNS (Tailscale MagicDNS) and make sure the tailnet's DNS settings don't rely on only one AdGuard.
- Private reverse DNS on the primary AdGuard.

## Proxmox

- Watch the Sunday backup run for the CIFS write error Escapepod hit once.
- Rebalance load from pve onto pve3.
- NAS for shared storage, then HA.
- Nextcloud data still lives on the file server's SMB share.
- iventoy runs privileged with full device access.

## Active Directory

- Activate Windows on DC02.
- Eject ISOs from both DCs.

## Remote access

- Nextcloud logs every login as the tunnel connector's IP ([details](remote-access/nextcloud.md#unresolved-every-login-logs-as-the-tunnel-connectors-ip)).
- Confirm what the cloudflare-ddns container updates, and stop it if nothing needs the home IP.
- SPF and DMARC reject records on the second domain if it doesn't send mail.

## Later

- Authentik for SSO, only after HA is live. Proxmox and AdGuard admin stay on local auth so they still work if SSO breaks.

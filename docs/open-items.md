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

- Watch the Sunday backup run for the CIFS write error Escapepod hit once.
- Rebalance load from pve onto pve3.
- NAS for shared storage, then HA.
- Nextcloud data still lives on the file server's SMB share.
- iventoy runs privileged with full device access.

## Active Directory

- Activate Windows on DC02.
- Eject ISOs from both DCs.

## Identity

- Second Cloud Sync agent on DC01.
- Retire the pilot sync account.
- Finish Nextcloud SSO through Entra (username mapping, then provider config).
- Decide whether Authentik is still needed.

## Apps

- SavaPage: Windows test, key backup, certificate by GPO, block direct printing, client rollout script ([details](apps/savapage.md#still-to-do)).
- Splunk: check container resources against its requirements.
- Escapepod: confirm the DNS rewrite lets Vector reach wire-pod from the IoT VLAN; fall back to a hidden Default SSID on AP 4 if not.
- Escapepod: build and test the recognition patch on a real robot.
- Linkwarden: update `NEXTAUTH_URL` to the public hostname and restart the stack.

## Remote access

- Nextcloud logs every login as the tunnel connector's IP ([details](remote-access/nextcloud.md#unresolved-every-login-logs-as-the-tunnel-connectors-ip)).
- Confirm what the cloudflare-ddns container updates, and stop it if nothing needs the home IP.
- SPF and DMARC reject records on the second domain if it doesn't send mail.

## Later

- Authentik, if still wanted after Entra SSO, only after HA is live. Proxmox and AdGuard admin stay on local auth so they still work if SSO breaks.

# SavaPage print management (deleted)

The container was deleted in early November 2026 before the Windows rollout. These notes stay as a record of the install and its problems. If it comes back, the AD service account, security group and DNS record may need cleaning up or reusing.

[SavaPage](https://www.savapage.org) 1.7.0 on pve3. Windows PCs print to a SavaPage queue instead of straight to the printer. Jobs land in each user's web inbox and get released from there.

## Container

| | |
|---|---|
| Guest | LXC 124 `savapage`, unprivileged, Debian 13 |
| Resources | 2 cores, 4 GB RAM, 16 GB disk |
| Database | PostgreSQL in the same container (instead of the bundled Derby) |
| Printer | network MFP at 10.10.1.52, IPP Everywhere |
| User app | `https://savapage.home.lan:8632/user` |
| Admin app | `https://savapage.home.lan:8632/admin` |
| IPP queues | `http://savapage.home.lan:8631/printers/<queue>` |

## CUPS

CUPS inside the container only serves SavaPage. It listens on localhost and the socket, with browsing off, so nothing else on the LAN can see the printer through it.

```
cupsctl --no-share-printers --no-remote-any --no-remote-admin
cupsctl MaxJobs=500 PreserveJobHistory=Yes PreserveJobFiles=No
sed -i 's/^Browsing Yes/Browsing No/' /etc/cups/cupsd.conf
sed -i 's/^#\?\s*BrowseRemoteProtocols.*/BrowseRemoteProtocols none/' /etc/cups/cups-browsed.conf
systemctl restart cups cups-browsed

lpadmin -p MFP -E -v ipp://10.10.1.52/ipp/print -m everywhere
lpadmin -p MFP -o printer-is-shared=true
lp -d MFP /usr/share/cups/data/testprint
```

Debian's default is `Browsing Yes`, not `Browsing On`. A sed written for `On` silently does nothing.

`printer-is-shared=true` only lets the local savapage account use the queue. With CUPS bound to localhost it doesn't expose anything.

`-m everywhere` queries the printer live. If it fails, check the printer answers IPP:

```
ipptool -tv ipp://10.10.1.52/ipp/print get-printer-attributes.test | head
```

## Install

As root:

```
runuser -u postgres -- createuser -P savapage
runuser -u postgres -- createdb -O savapage savapage
useradd -r savapage
mkdir -p /opt/savapage && chown savapage:savapage /opt/savapage
usermod -s /bin/bash -d /opt/savapage savapage
su - savapage
```

Paste up to `createuser` first and answer its password prompts, or the following lines get typed into the prompt.

As savapage:

```
cd /opt/savapage
wget https://www.savapage.org/download/installer/savapage-setup-1.7.0-final-linux-x64.bin
wget https://www.savapage.org/download/sha512sums.txt
grep 1.7.0-final-linux sha512sums.txt | sed 's#installer/##' | sha512sum -c
sh ./savapage-setup-1.7.0-final-linux-x64.bin
```

The checksum file lists paths with an `installer/` prefix, hence the sed. Decline the installer's offer to run root tasks (there's no sudo), then `exit` and run the `MUST-RUN-AS-ROOT` script it names. Switch the database to PostgreSQL in `server.properties` before the first login.

## Active Directory

- Service account `svc-savapage` for the LDAP bind. Not synced to Entra.
- User sync limited to a `SavaPage-Users` security group.
- DNS A record for `savapage.home.lan` on the DCs.
- Users sign in to the web app with their plain username, not `DOMAIN\user` or a UPN.

## Queues

Planned layout. Admin login and LDAP sync work; queues are the next step.

| Queue | Auth | For |
|---|---|---|
| trusted | None, restricted to 10.10.1.0/24 | domain-joined PCs; jobs land on the Windows username |
| basic | Basic | non-domain PCs; Windows prompts for AD credentials |

Never put non-domain machines on the trusted queue. On a trusted queue, a job whose username doesn't match a synced user is dropped, and the admin Log page says so.

## Windows client

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Printing-Foundation-InternetPrinting-Client
```

Settings > Printers & scanners > Add device > Add manually > by IP address or hostname. Type IPP Device, address `http://savapage.home.lan:8631/printers/trusted`, driver Microsoft PS Class Driver.

Before releasing the first test job, download its PDF from the inbox and copy some text out to confirm the PS driver isn't producing garbled text.

## Problems hit

- The template name passed to `pveam download` didn't match what `pveam available` listed. Copy the exact name.
- Commands meant for the container ran on the pve3 host after a paste crossed a `pct enter` boundary. The host had to be cleaned up (packages and users removed). Paste one shell's worth at a time; anything after `su`, `exit` or `pct enter` goes to whichever shell reads next.
- DHCP handed the container `lan` as its search domain instead of `home.lan`.
- HTTPS failed with "Invalid SNI" because the generated certificate didn't cover `savapage.home.lan`. Regenerated it with SavaPage's `create-ssl-keystore` tool, listing the DNS name and IP explicitly.

## Still to do

- First end-to-end Windows test.
- Back up SavaPage's encryption keys with its bundled key-export tool.
- Push the new certificate to domain PCs by GPO.
- Block direct printing to the MFP so jobs have to go through SavaPage.
- Script the client setup for the rest of the PCs.

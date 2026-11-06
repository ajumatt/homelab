# Splunk Enterprise (deleted)

Retired in favor of Wazuh, which now collects the logs ([Wazuh](../monitoring/wazuh.md)). Splunk used about 1.4 GB of its 8 GB allocation and had no other job. Deleted after pve3's 2026-11-01 backup was confirmed good. These notes stay for the install bug.

LXC 108 on pve3, 10.10.1.50, web UI on port 8000. Installed with the [community-scripts ProxmoxVE](https://github.com/community-scripts/ProxmoxVE) Splunk Enterprise helper.

## Install bug

With Splunk 10.6, the helper script failed at the end. Splunk creates its unit as `splunkd.service` (lowercase) and the script runs `systemctl enable --now Splunkd`. systemd unit names are case-sensitive, so the enable fails.

When the script offers to remove the container, choose "Keep container for debugging", then inside it:

```
systemctl daemon-reload
systemctl enable --now splunkd
systemctl status splunkd
```

If the unit still isn't found, `ls /etc/systemd/system/ | grep -i splunk` shows the real name.

The steps the script skips after that point (MOTD and package cleanup) aren't needed. `apt autoremove && apt clean` covers the cleanup.

`pct enter` swallows the rest of a pasted block, same as `pct restore`. Run commands one at a time after entering a container.

## Credentials

The helper writes the generated admin credentials to `~/splunk.creds` in the container. Move them to the password manager and delete the file.

## Address

It first got .201, then .200. Both are inside the DHCP pool. Moved to .50, the first free address in the server range. If a container has a static IP in its Proxmox config, an Omada reservation does nothing; change `net0` with `pct set` instead.

## To check

Resources (`pct config 108`). Splunk wants at least 4 GB RAM and room for indexes, and pve3's thin pool is 348 GiB.

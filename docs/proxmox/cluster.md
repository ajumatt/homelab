# Proxmox cluster

Three nodes, Proxmox VE 9.2.21, kernel 7.0.14-20-pve on all of them. Quorate (expected votes 3, quorum 2). No subscription; pve-no-subscription repo enabled, enterprise, test and ceph repos disabled.

| | pve | pve2 | pve3 |
|---|---|---|---|
| Address | 10.10.1.20 | 10.10.1.21 | 10.10.1.22 |
| CPU | 6 cores / 12 threads | 6 cores / 12 threads | 12 threads |
| RAM | 32 GB | 32 GB | 16 GB |
| Boot disk | 1 TB NVMe | 1 TB NVMe | |
| local-lvm | 816 GB thin | 816 GB thin | 348 GiB thin |
| Bridge | vmbr0 on nic0, VLAN aware | same | same |

## Adding the third node

Two nodes meant losing either one dropped the survivor out of quorum. pve3 fixed that.

- Installed with ext4 and LVM-thin so the cluster-wide `local-lvm` storage definition works on it too.
- Copied the repo configuration from pve before the first update.
- Joining by IP failed with "hostname verification failed". pve serves a certificate that doesn't include its IP. Passing the fingerprint explicitly worked:

```
pvecm add 10.10.1.20 --link0 10.10.1.22 --fingerprint <sha256 of pve's certificate>
```

- Made vmbr0 VLAN aware (`bridge-vids 2-4094`) to match the other two.

vmbr0 VLAN awareness had drifted between pve and pve2 before this. Keep it identical on every node or migrated guests with VLAN tags break.

## HA is deferred

Every guest disk sits on node-local `local-lvm`. HA can't restart a guest on another node if its disk only exists on the dead one. Replication with ZFS would solve it, but I'd rather add a NAS for shared storage and turn HA on after that.

Migration is a one-time copy of the disk, not a mirror. Don't treat a migrated guest as protected.

## Gotchas

- Pending hardware changes (enabling the guest agent, adding a CD drive) only apply after a Proxmox-side stop/start or `qm reboot`. Rebooting from inside the guest doesn't pick them up.
- `pct restore` reads stdin, so any commands pasted after it in the same block get swallowed. Run them separately.
- Host DNS on all nodes goes through Tailscale MagicDNS. LXCs set to "use host settings" inherit that, including the tailnet search domain, even when Tailscale isn't installed in the container. Set the nameserver explicitly on any container that must resolve on its own (`pct set <id> --nameserver <ip>`).

## pve network outage

On 2026-10-28 the pve2 web UI showed `Connection error 595: No route to host` for pve. From pve2, pve didn't answer ARP or its Tailscale address. pve2 and pve3 stayed quorate (2 of 3) the whole time. pve itself was running and its local console worked; a reboot from the console brought everything back.

The most likely cause is a transmit queue hang in the onboard NIC's e1000e driver. A surviving journal from September shows repeated `e1000e nic0: Detected Hardware Unit Hang` lines alongside the backup share going offline, with the same symptom: box alive, network dead. The October journal for the outage window couldn't be read, so this one isn't proven.

Why the logs were missing: pve runs log2ram, which keeps `/var/log` in RAM and writes it to disk only at a clean shutdown. A hard reset loses it. Journal files left over from an unclean boot get renamed to `*.journal~` and can still be read with `journalctl --file`.

Applied on pve only, since pve2 and pve3 weren't affected:

```
ethtool -K nic0 tso off gso off gro off
```

Made permanent in `/etc/network/interfaces`:

```
iface nic0 inet manual
    post-up /usr/sbin/ethtool -K nic0 tso off gso off gro off
```

journald on pve was also switched to volatile storage so the Wazuh agent could read it (see [Wazuh](../monitoring/wazuh.md#pve-sent-nothing-at-first)). Wazuh rule 100100 now alerts on the hang message, and Prometheus alerts on NodeDown within minutes.

If the hang returns with offloads off, the next steps are a newer kernel, turning off EEE (`ethtool --set-eee nic0 eee off`), or moving `vmbr0` to a second NIC.

What stayed up while pve was down: AD on DC02, the tunnel through cloudflared2 on pve3, and the primary AdGuard on pve2. What went down with it: DC01, Home Assistant, Escapepod, Nextcloud, cloudflare-ddns, connector 1 and the secondary AdGuard.

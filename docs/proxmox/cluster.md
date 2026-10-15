# Proxmox cluster

Three nodes, Proxmox VE 9.2.21, kernel 7.0.14-20-pve on all of them. Quorate (expected votes 3, quorum 2). No subscription; pve-no-subscription repo enabled, enterprise, test and ceph repos disabled.

| | pve | pve2 | pve3 |
|---|---|---|---|
| Address | 10.10.1.20 | 10.10.1.21 | 10.10.1.22 |
| CPU | 6 cores / 12 threads | 6 cores / 12 threads | |
| RAM | 32 GB | 32 GB | |
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

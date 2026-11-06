# Storage and backups

## Storage definitions

| ID | Type | Content | Shared | Backing |
|---|---|---|---|---|
| local | dir `/var/lib/vz` | backup, ISO, templates, import | no | node root filesystem |
| local-lvm | LVM-thin `pve/data` | VM and CT disks | no | node NVMe |
| Storage | dir `/storage` | ISO, import, images | no | node root filesystem |
| HS-Storage | CIFS share on the file server (10.10.1.250) | images, backup | yes | about 8.4 TB, 4.7 TB used (2026-10-28) |

"Storage" was marked shared even though it's a plain directory on each node. Proxmox trusted the flag and assumed every node saw the same files. Set to `shared=0`. ISOs live in `/storage/template/iso` and get copied to whichever node needs them.

## Backup job

| Setting | Value |
|---|---|
| Scope | all guests |
| Schedule | Sunday 02:00 |
| Target | HS-Storage |
| Mode | snapshot |
| Compression | zstd |
| Retention | keep-weekly 4, keep-monthly 3 |
| Notes template | `{{guestname}}` |

Weekly instead of nightly was a deliberate choice; nothing here changes fast enough to need more.

No backup job existed before 2026-09-27. The first manual run covered every guest. Escapepod failed once with a zstd write I/O error to the CIFS share and succeeded on retry.

Failures go to the phone through a Proxmox notification webhook ([details](../monitoring/prometheus.md#backup-notifications)).

## Backup failures on the CIFS share

The share has failed the backup job three different ways.

| Date | What happened |
|---|---|
| 2026-10-18 | HS-Storage offline on all three nodes at 02:00. pve2 logged `HS-Storage is not online` 14 seconds in and backed up nothing that week. |
| 2026-10-25 | pve's run took about 4 hours instead of the usual 50 minutes. |
| 2026-11-01 | DC01 and Escapepod on pve and iventoy on pve2 failed with `zstd ... failed - wrong exit status 1`, all between 02:13 and 02:20. |

Retried one at a time that evening, DC01 and iventoy succeeded. DC02 failed once on a manual run, at the final flush after reading all 60 GB, then succeeded on a second try. Escapepod failed again, alone, with `zstd: /*stdout*\: Input/output error`. That's the CIFS mount returning EIO on a write near the end of the archive, which points at the share rather than at Proxmox or zstd. The kernel log for DC02's failure window was empty, and the failed run left no partial archive behind.

Finding which guest failed in a run (vzdump's per-guest status hides zstd's real error):

```
grep -l ERROR /mnt/pve/HS-Storage/dump/*<YYYY_MM_DD>-02_*.log
pvesh get /nodes/$(hostname)/tasks --typefilter vzdump --limit 3
journalctl -k --since "<start>" --until "<end>" | grep -iE 'cifs|smb|i/o'
```

Quote the UPID in single quotes when reading one task's log with `pvesh get .../tasks/'<UPID>'/log`, or bash reads the angle brackets and colons wrong.

Workaround for a guest that keeps failing: back up to local disk, then copy it over. If the copy fails too, the SMB service on the file server is the problem.

```
vzdump 103 --storage local --mode snapshot --compress zstd
cp /var/lib/vz/dump/vzdump-qemu-103-*.vma.zst /mnt/pve/HS-Storage/dump/
```

Recommended but not yet confirmed in place: split the single 02:00 job into one per node (pve 02:00, pve2 03:30, pve3 05:00) so three nodes don't write to the file server at once, with a bandwidth limit as a second step if failures continue. Staggering won't fix Escapepod's EIO, which happened with nothing else writing.

## Capacity

HS-Storage grew from 4,446 GB to 4,705 GB between 2026-09-27 and 2026-10-28, about 8.4 GB a day. At that rate the remaining 3.7 TB lasts about 14 months. Glance shows a growth forecast from Prometheus.

## Storage plan (not decided)

Options under consideration as of early November:

- A USB drive on pve3 with Proxmox Backup Server in a container, as a second backup copy. PBS gives deduplicated incremental backups that every node can reach over the network, which plain directory storage on one node can't. ext4 rather than ZFS because of pve3's RAM. Mounted by UUID with `nofail`, USB autosuspend off, and never used for guest disks.
- A 5-bay USB-C DAS with 4 TB CMR drives on pve as a RAIDZ2 pool. That would hold PBS (replacing the weekly full vzdumps that drive the growth above) and Nextcloud's data disk, moved with `qm disk move`. RAIDZ2 over RAIDZ1 plus a hot spare: similar usable space, but RAIDZ2 keeps parity during a rebuild. The file server would stay as a second copy.

Either one is local storage on one node. Neither gives HA.

## Disks excluded from backup

Nextcloud's 1 TB data disk is a raw image on HS-Storage, attached as `scsi1` with `backup=0`. Backing it up to the same share it lives on would double the space for no protection. It has no backup at all right now; the storage plan above would fix that.

That disk also means Nextcloud depends on the file server and its SMB share being up. It's a known weak point until there's a NAS.

## Cleanup done

- Escapepod's disk was on a file-based storage; moved live to `local-lvm` and the old file deleted.
- Retired Pi-hole LXC destroyed after a final backup to HS-Storage.
- Ejected a leftover install ISO from the Nextcloud VM.

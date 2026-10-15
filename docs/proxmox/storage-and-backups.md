# Storage and backups

## Storage definitions

| ID | Type | Content | Shared | Backing |
|---|---|---|---|---|
| local | dir `/var/lib/vz` | backup, ISO, templates, import | no | node root filesystem |
| local-lvm | LVM-thin `pve/data` | VM and CT disks | no | node NVMe |
| Storage | dir `/storage` | ISO, import, images | no | node root filesystem |
| HS-Storage | CIFS share on the file server (10.10.1.250) | images, backup | yes | about 8.4 TB |

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

No backup job existed before 2026-09-27. The first manual run covered every guest. Escapepod failed once with a zstd write I/O error to the CIFS share and succeeded on retry. If that repeats, look at the SMB share on the file server before anything else.

## Disks excluded from backup

Nextcloud's 1 TB data disk is a raw image on HS-Storage, attached as `scsi1` with `backup=0`. Backing it up to the same share it lives on would double the space for no protection. It needs a separate plan.

That disk also means Nextcloud depends on the file server and its SMB share being up. It's a known weak point until there's a NAS.

## Cleanup done

- Escapepod's disk was on a file-based storage; moved live to `local-lvm` and the old file deleted.
- Retired Pi-hole LXC destroyed after a final backup to HS-Storage.
- Ejected a leftover install ISO from the Nextcloud VM.

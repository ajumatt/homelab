# Host firmware (fwupd)

Checked on pve. PVE 9 is Debian trixie based and ships fwupd with a Proxmox-signed EFI binary for Secure Boot.

```
apt install fwupd
fwupdmgr refresh
fwupdmgr get-devices    # CPU, SPI/BIOS, NVMe, TPM, UEFI keys
fwupdmgr get-updates
fwupdmgr update
```

`fwupd-refresh.timer` is enabled on install, so LVFS metadata refreshes itself. Updates still get checked and applied by hand.

Proxmox leaves `udisks2` out of fwupd's dependencies on purpose for hypervisor hosts.

Last run: nothing pending. System firmware matched the vendor's latest published release.

## "UEFI ESP partition not detected or configured"

Prints on every fwupdmgr command. It's a PVE 9 issue (Proxmox Bugzilla #6654), not this machine.

On PVE 8, `EspLocation=/boot/efi` in `/etc/fwupd/daemon.conf` fixed it. Upstream fwupd dropped that option, and PVE 9 ships `/etc/fwupd` empty.

fwupd can still list devices and check for updates. It can't write a UEFI capsule (BIOS flash) until it can find the ESP.

Unofficial workaround, not applied here:

```
apt install udisks2
fwupdtool esp-list --verbose
```

Fallback for a BIOS update before this is fixed: download it from the hardware vendor, copy to a FAT32 USB stick, flash from the one-time boot menu.

## Firmware fwupd doesn't manage

- CPU microcode: install the microcode package for the CPU vendor (`intel-microcode` or `amd64-microcode`), reboot. Updates ride along with `apt upgrade` after that.
- Wi-Fi, GPU and other kernel-loaded blobs: the `pve-firmware` package, updated with normal upgrades.

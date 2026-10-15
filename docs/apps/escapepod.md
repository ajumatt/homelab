# Escapepod (wire-pod for Vector)

VM 103 on pve, Ubuntu 26.04 LTS, hostname `escapepod.local`, 10.10.1.110. Runs [wire-pod](https://github.com/kercre123/wire-pod), the self-hosted replacement for the Vector robot's cloud server.

1 core, 2 GB RAM, 10 GB disk on `local-lvm`. QEMU guest agent enabled.

## Vector on the IoT VLAN

Vector is moving from the main SSID to IoT. Two problems to solve:

1. It currently fails to join the IoT SSID at all and never shows up as a client, which points at Wi-Fi association rather than DHCP. The AI Roaming admission restriction described in [Wi-Fi](../network/wifi.md#roaming-features) was one cause of IoT join failures.
2. Once it's on VLAN 100, it has to find escapepod on VLAN 1. The firewall side is done (IoT is allowed to reach .110). Discovery may need an mDNS rule, or the server address set by IP in wire-pod's bot setup.

## Recognition feature (local patch)

A small wire-pod addition that makes Vector speak when it sees a known face or one of its own objects.

- New package `chipper/pkg/wirepod/recognition`. Opens a persistent SDK connection and event stream per activated bot.
- Faces: when an enrolled (named) face is recognized, Vector says a greeting picked at random. Per-face cooldown.
- Objects: its light cube, its charger, or a custom marker defined through the SDK. Vector has no general object recognition, so cups and chairs are out of reach regardless of software.
- Config in `apiConfig.json` under `Recognition` (`Enable`, `AnnounceFaces`, `AnnounceObjects`, `CooldownSeconds`). Defaults to off; older config files load fine without the key.
- Settings tab added to the wire-pod web UI.

Status: syntax-checked and written against the actual vector-go-sdk sources, but not yet compiled or tested on a robot. The patch itself isn't in this repo yet. To finish:

```
git apply recognition-feature.patch
cd chipper && go build .    # with the usual STT build tag
```

Then pair with a real Vector and tune the cooldown.

## Lost password

No Cloud-Init drive is attached to this VM, so the password can't be reset from the Proxmox Cloud-Init tab. Recovery goes through GRUB:

1. Start the VM from Proxmox and tap Shift or Esc immediately. The GRUB timeout is very short.
2. Press `e` on the default entry and append `init=/bin/bash` to the `linux` line.
3. Boot with Ctrl+X.
4. `mount -o remount,rw /`
5. `passwd <user>`
6. `reboot -f`

The login user is a regular account, so package management needs `sudo`. Without it apt fails with permission denied on the dpkg lock.

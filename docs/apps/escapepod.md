# Escapepod (wire-pod for Vector)

VM 103 on pve, Ubuntu 26.04 LTS, hostname `escapepod.local`, 10.10.1.110. Runs [wire-pod](https://github.com/kercre123/wire-pod), the self-hosted replacement for the Vector robot's cloud server.

1 core, 2 GB RAM, 10 GB disk on `local-lvm`. QEMU guest agent enabled.

## Vector on the IoT VLAN

Vector joined the IoT SSID on 2026-10-18 and sits at 10.10.100.50 (previously 10.10.1.72 on Default). Earlier join attempts never got as far as showing up as a client; that cleared up around the time AI Roaming was turned off and the IoT SSID went AES-only. It's on AP 4 now.

Moving it broke wire-pod in two separate ways.

### Stale bot IP

wire-pod caches each paired robot's address in `chipper/jdocs/botSdkInfo.json`. After the move, every outbound call to the robot (TTS, event stream) failed with `dial tcp 10.10.1.72:443: connect: no route to host`.

```
sudo systemctl stop wire-pod
# edit chipper/jdocs/botSdkInfo.json: set the bot's ip_address to 10.10.100.50
sudo systemctl start wire-pod
sudo journalctl -u wire-pod -f
```

After that, escapepod reaches the robot on TCP 443 (`nc` connects; ping doesn't answer, which is normal for Vector).

Vector's address is still an unreserved lease inside the IoT pool. If it changes, this breaks again the same way. It needs an IoT DHCP reservation.

### Robot can't find the server

wire-pod announces `escapepod.local` by mDNS, and mDNS doesn't cross VLANs. The firewall already lets IoT reach .110, but the robot never resolves the name, so the wire-pod log shows only its own outbound connection loop and nothing inbound from the robot.

Options considered:

- A second NIC on VM 103 tagged for VLAN 100, so wire-pod announces itself on the IoT side too. Decided against it.
- An AdGuard DNS rewrite, `escapepod.local` to 10.10.1.110, added on the primary (syncs to the secondary). Works only if Vector falls back to unicast DNS for `.local` names. In place, not yet confirmed working.
- Fallback if the rewrite doesn't work: a hidden 2.4 GHz SSID on the Default network on AP 4, MAC-filtered to the robot.

Still unverified end to end: voice commands and SDK features after both fixes.

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

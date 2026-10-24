# IoT migration

Moving smart-home devices from the main SSID to the IoT SSID (VLAN 100). Most were already moved; the main SSID went 5/6 GHz only partway through, which knocked anything 2.4 GHz-only offline until it's re-paired.

| Device | Status |
|---|---|
| Smart plug 1 | Moved. Couldn't join until AP 1 stopped broadcasting the IoT SSID (see [Wi-Fi](wifi.md#ap-1-and-the-iot-ssid)). Now on AP 4. |
| Smart plug 2 | Re-pair through the vendor app. |
| Garage door opener | Move through the vendor app. |
| Video doorbell | Cloud-managed, move through the vendor app. |
| SmartThings hub | Wire it to a switch port with the IoT VLAN as native instead of changing its Wi-Fi. Changing Wi-Fi on this hub can force a reset that wipes Zigbee and Z-Wave pairings. |
| Vector robot | Moved, at 10.10.100.50. Needed fixes on the wire-pod side; see [Escapepod](../apps/escapepod.md#vector-on-the-iot-vlan). |
| Two unidentified clients | Blocked in Omada (Clients > Blocked) to see what stops working. Unblock if something breaks. |

Phones and tablets stay on the main SSID.

## After a device moves

1. Add an IoT DHCP reservation for it. A device that another host talks to by IP (Vector, anything Home Assistant polls) breaks quietly when its lease changes.
2. Update any Home Assistant integration that talks to it by IP.
3. Update anything that cached its old address. wire-pod keeps each robot's IP in its own config file and doesn't notice a move.

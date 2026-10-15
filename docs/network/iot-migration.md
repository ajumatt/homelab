# IoT migration

Moving smart-home devices from the main SSID to the IoT SSID (VLAN 100). Most were already moved; the main SSID went 5/6 GHz only partway through, which knocked anything 2.4 GHz-only offline until it's re-paired.

| Device | Status |
|---|---|
| Smart plugs (two) | Re-pair through the vendor app. One in progress. |
| Garage door opener | Move through the vendor app. |
| Video doorbell | Cloud-managed, move through the vendor app. |
| SmartThings hub | Wire it to a switch port with the IoT VLAN as native instead of changing its Wi-Fi. Changing Wi-Fi on this hub can force a reset that wipes Zigbee and Z-Wave pairings. |
| Vector robot | Join to IoT failing; it never shows up as a client, so the problem is Wi-Fi association, not DHCP. See [Escapepod](../apps/escapepod.md). |
| Two unidentified clients | Blocked in Omada (Clients > Blocked) to see what stops working. Unblock if something breaks. |

Phones and tablets stay on the main SSID.

## After a device moves

1. Add an IoT DHCP reservation for it.
2. Update any Home Assistant integration that talks to it by IP.

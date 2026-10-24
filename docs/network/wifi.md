# Wi-Fi

Four access points, two SSIDs.

| AP | Model | 6 GHz | SSIDs |
|---|---|---|---|
| AP 1 | EAP787 | yes | main only (5/6 GHz); 2.4 GHz radio off |
| AP 2 | EAP650-Desktop | no | main and IoT |
| AP 3 | EAP775-Wall | yes | main and IoT |
| AP 4 | EAP653 | no | IoT only, covers the area around AP 1 |

The main SSID is 5 and 6 GHz only. The IoT SSID is 2.4 GHz only, VLAN 100, WPA2-PSK with AES (changed from Auto/TKIP+AES while chasing a smart plug that wouldn't join), PMF off, 802.11r off.

## Channel plan

| AP | 2.4 GHz | 5 GHz |
|---|---|---|
| AP 1 | off | ch 100 (DFS), 80 MHz |
| AP 2 | ch 6, 26 dBm | Auto, 80 MHz |
| AP 3 | ch 11, 19 dBm | ch 36, 80 MHz |
| AP 4 | ch 1, 18 dBm, 20 MHz | not used |

All three original 5 GHz radios were on 160 MHz and overlapping. Dropping to 80 MHz gave each AP its own channel.

AP 2's 5 GHz is left on Auto. It was fixed at 149 in the plan, but radar on 104 has moved it around and Auto handles that better.

The 2.4 GHz plan has drifted from what was written down more than once. AP 2 was once found on channel 11 at 26 dBm, the same channel as AP 3, when the plan said channel 1. Moving it back fixed a Wi-Fi doorbell that sat on AP 2 at -77 dBm with the radio 87% utilized. Later AP 2 turned up on channel 6 instead, and a change to AP 1 based on the old plan briefly put two APs on the same channel. Read the actual radio settings off every AP before changing any of them.

## AP 1 and the IoT SSID

AP 1 never had a single IoT client in a month of Omada client history, even though it broadcast the IoT SSID and devices next to it saw it about 15 dB stronger than any other AP.

Ruled out:

- Channel. Moved it twice; no change.
- Wi-Fi 7 beacons. AP 1 advertised EHT elements on 2.4 GHz that AP 2 didn't. Changing its 2.4 GHz mode to b/g/n/ax removed them. A test plug still never joined.
- Switch port and VLAN. The uplink is a trunk carrying VLAN 100, and the same port serves the main SSID fine.

With the IoT SSID turned off on AP 1 alone (an AP-level override under AP 1 > Config > Wireless > WLANs), the test plug joined AP 2 within a minute. So AP 1 rejects IoT clients before authentication, and devices near it keep retrying the strongest BSSID instead of falling back to a weaker AP. No log entry is ever written for those failures. The root cause on AP 1 wasn't found.

Fix: leave the IoT SSID off on AP 1, disable AP 1's 2.4 GHz radio entirely, and add AP 4 nearby as an IoT-only AP. AP 4 is on switch port 3 (trunk), reserved at 10.10.1.14, with the main SSID overridden off. A test plug roamed onto it within minutes of setup.

Other IoT devices that were stuck retrying AP 1 may need a power cycle to land on AP 4.

## RSSI thresholds

Set per AP under Devices > AP > Config > Wireless > Advanced.

| AP | 2.4 GHz | 5 GHz | 6 GHz |
|---|---|---|---|
| AP 1 | radio off | -78 dBm | -78 dBm |
| AP 2 | off (was -68) | -78 dBm (was -68) | n/a |
| AP 3 | off (was -68) | -78 dBm (was -68) | -78 dBm (was -68) |

-68 dBm on 2.4 GHz was kicking distant IoT devices off the IoT SSID. 2.4 GHz is off on purpose now.

Omada drops unsaved values when you switch between band tabs on that page. Save each band before moving to the next.

## Roaming features

Fast Roaming (802.11r) and Band Steering (prefer 5/6 GHz) are on at the site level. 802.11r is off on the IoT SSID because older IoT radios don't handle it.

Non-Stick Roaming and AI Roaming are off. AI Roaming was making AP 3 turn on client admission restriction on 2.4 GHz for ten minutes or more at a time. The event log listed the reason as load balance algorithm processing. While it was on, new devices could not join the IoT SSID at all, and the failures didn't show in the client list because they never associated.

## Client event logging

On since 2026-10-19 (Logs > Setting > Events > Client): connection failed, roaming, offline and online, wireless only. Log only, no alerts. It's off by default, and without it a device that fails to join leaves no trace anywhere in the controller.

Omada's client list is slow to mark a device offline (about seven minutes in one test), so a missing offline event in the first few minutes doesn't mean the device stayed connected.

## Debugging IoT joins

1. Confirm the SSID settings (band, VLAN, security, PMF, 802.11r, MAC filter, minimum rate).
2. Confirm IoT DHCP is handing out leases to devices that do connect.
3. Check the AP's radio: channel, width, power, wireless mode, client limit, RSSI threshold.
4. Read Events for admission restriction, load balancing, and connection-failed entries.
5. Check which AP the device is trying. If every failure is on one AP, turn the SSID off on that AP and see whether the device lands somewhere else.
6. As a last resort, set 2.4 GHz wireless mode to b/g/n for very old radios.

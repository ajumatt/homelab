# Wi-Fi

Three access points, two SSIDs.

| AP | Model | 6 GHz |
|---|---|---|
| AP 1 | EAP787 | yes |
| AP 2 | EAP650-Desktop | no |
| AP 3 | EAP775-Wall | yes |

The main SSID is 5 and 6 GHz only. The IoT SSID is 2.4 GHz only, VLAN 100, WPA2-PSK with AES (changed from Auto/TKIP+AES while chasing a smart plug that wouldn't join), PMF off, 802.11r off.

## Channel plan

| AP | 2.4 GHz | 5 GHz |
|---|---|---|
| AP 1 | ch 6, 18 dBm | ch 100 (DFS), 80 MHz |
| AP 2 | ch 1 | Auto, 80 MHz |
| AP 3 | ch 11, 19 dBm | ch 36, 80 MHz |

All three 5 GHz radios were on 160 MHz and overlapping. Dropping to 80 MHz gave each AP its own channel.

AP 2's 5 GHz is left on Auto. It was fixed at 149 in the plan, but radar on 104 has moved it around and Auto handles that better.

AP 2's 2.4 GHz was later found on channel 11 at 26 dBm, the same channel as AP 3, even though the plan said channel 1. A Wi-Fi doorbell sitting on AP 2 at -77 dBm with the radio 87% utilized moved to AP 1 on 5 GHz a minute after AP 2 went back to channel 1. Lesson: re-check the actual radio settings against the plan, because the plan isn't proof.

## RSSI thresholds

Set per AP under Devices > AP > Config > Wireless > Advanced.

| AP | 2.4 GHz | 5 GHz | 6 GHz |
|---|---|---|---|
| AP 1 | off | -78 dBm | -78 dBm |
| AP 2 | off (was -68) | -78 dBm (was -68) | n/a |
| AP 3 | off (was -68) | -78 dBm (was -68) | -78 dBm (was -68) |

-68 dBm on 2.4 GHz was kicking distant IoT devices off the IoT SSID. 2.4 GHz is off on purpose now.

Omada drops unsaved values when you switch between band tabs on that page. Save each band before moving to the next.

## Roaming features

Fast Roaming (802.11r) and Band Steering (prefer 5/6 GHz) are on at the site level. 802.11r is off on the IoT SSID because older IoT radios don't handle it.

Non-Stick Roaming and AI Roaming are off. AI Roaming was making AP 3 turn on client admission restriction on 2.4 GHz for ten minutes or more at a time. The event log listed the reason as load balance algorithm processing. While it was on, new devices could not join the IoT SSID at all, and the failures didn't show in the client list because they never associated.

## Debugging IoT joins

1. Confirm the SSID settings (band, VLAN, security, PMF, 802.11r, MAC filter, minimum rate).
2. Confirm IoT DHCP is handing out leases to devices that do connect.
3. Check the AP's radio: channel, width, power, wireless mode, client limit, RSSI threshold.
4. Read Events for admission restriction or load balancing entries.
5. Turn on client event logging (Logs > Setting) so failed joins show up. It's off by default, and without it the Events view shows nothing for clients.
6. As a last resort, set 2.4 GHz wireless mode to b/g/n for very old radios.

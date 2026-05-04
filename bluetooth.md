# Bluetooth

This config enables two Bluetooth compatibility tweaks that help with flaky reconnects and host-side pairing problems:

- `CONFIG_ZMK_BLE_EXPERIMENTAL_FEATURES=y` to enable ZMK's experimental connection and security settings
- `CONFIG_BT_CTLR_TX_PWR_PLUS_8=y` to raise BLE transmit power for host and split-half links

## Layer 3 Bluetooth bindings

Layer 3 includes Bluetooth management bindings for recovering from stuck or stale connections:

| Key      | Action                                            |
| -------- | ------------------------------------------------- |
| `BT PRV` | Select previous Bluetooth profile                 |
| `BT NXT` | Select next Bluetooth profile                     |
| `BT CLR` | Clear bond for currently selected profile         |
| `BT 0`   | Select Bluetooth profile 0                        |
| `BT 1`   | Select Bluetooth profile 1                        |
| `DISC 0` | Disconnect profile 0 after switching away from it |

## Quick reconnect flow

If the keyboard stops working after you come back into range but you do **not** want to re-pair:

1. Switch to layer 3.
2. Press `BT 1` to switch away from your Mac profile.
3. Press `DISC 0`.
4. Press `BT 0` to switch back to your Mac profile.
5. Wait a few seconds for macOS to reconnect.

## Re-pair macOS

If macOS shows the keyboard as connected but it still does not type:

1. Switch to layer 3.
2. Press `BT 0` to make sure profile 0 is selected.
3. Press `BT CLR`.
4. Forget the keyboard in macOS Bluetooth settings.
5. Pair the keyboard again.

## Full reset for wedged state

If things are fully wedged and the above does not recover them, do a full settings reset on **both** halves:

1. Build or download `settings_reset-nice_nano_v2.uf2`.
2. Put the left half into bootloader mode and flash `settings_reset-nice_nano_v2.uf2`.
3. Put the right half into bootloader mode and flash the same `settings_reset-nice_nano_v2.uf2`.
4. Flash the normal firmware back onto both halves:
    - `cradio_left-nice_nano_v2.uf2` on the left
    - `cradio_right-nice_nano_v2.uf2` on the right
    - or use `scripts/reset_left.sh` and `scripts/reset_right.sh`
5. Forget the keyboard in macOS Bluetooth settings and pair again.

## USB logging for hard failures

If pairing still fails after profile clearing and a full settings reset, build a logging image so you can inspect the exact Bluetooth failure from ZMK:

```sh
./scripts/build-zmk.sh left-log
```

That produces:

- `firmware/cradio_left-nice_nano_v2-logging.uf2`

Flash that onto the left half, connect it over USB, then watch the CDC ACM serial device on macOS while you attempt pairing. This is the fastest way to confirm whether the failure is advertising, security, or host negotiation related.

The logging build also forces ZMK and Bluetooth debug logs and delays log startup briefly so boot messages are easier to catch after the serial device appears.

## The "normal" failure mode

Connect with a wire.
Select BT_1
Select BT_Clear
Forget device
Reconnect

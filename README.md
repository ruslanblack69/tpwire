# tpwire

Force an Apple Magic Trackpad onto its **wired USB-HID** transport on macOS by
removing its Bluetooth pairing — automatically, every time macOS silently
re-routes it back to Bluetooth.

## The problem

The Magic Trackpad's Bluetooth radio lives in the crowded 2.4 GHz band. Even
with Wi-Fi on 5 GHz and no USB 3.0 devices nearby, the input feels jittery and
laggy: small finger movements stutter or jump. Plugged in via cable it is
perfectly smooth — because over the cable it enumerates as a plain USB-HID
device and Bluetooth is out of the path.

The catch: **macOS keeps using the Bluetooth link while the device stays
paired, even when the cable is attached.** The cable only charges; input still
flows over Bluetooth, so the lag returns. It comes back especially after lock /
unlock, sleep/wake, or re-plugging, when macOS re-pairs the device.

The only reliable way to pin the trackpad to USB-HID is to remove its Bluetooth
pairing. The GUI's *Forget This Device* is frequently greyed out, and the
pairing reappears on its own. `tpwire` solves both: it unpairs via `blueutil`,
and a LaunchAgent watching the Bluetooth pairing database re-runs it the moment
the trackpad gets paired again.

Multitouch gestures keep working over USB-HID — nothing is lost except the
wireless mode, which is the whole point.

## Requirements

- macOS
- [`blueutil`](https://github.com/toy/blueutil): `brew install blueutil`
- The trackpad connected by cable (it works as USB-HID once unpaired)

## Install

```sh
brew install blueutil
git clone https://github.com/ruslanblack69/tpwire.git
cd tpwire
./install.sh
```

This copies `tpwire` to `~/.local/bin`, renders the LaunchAgent into
`~/Library/LaunchAgents/black.ruslan.tpwire.plist`, and loads it. The installer
also offers to pin the trackpad by its Bluetooth MAC (auto-detected from
`blueutil`, or entered by hand) and writes it to the config below. Re-running
`install.sh` is safe — an existing config is left untouched.

## Configuration

By default `tpwire` matches paired devices named `Magic Trackpad`. A trackpad's
Bluetooth MAC never changes, so you can pin to it directly — faster and immune
to name quirks. Set `TPWIRE_MAC` in `~/.config/tpwire/config`:

```sh
mkdir -p ~/.config/tpwire
echo 'TPWIRE_MAC=60-fb-42-d5-ca-50' > ~/.config/tpwire/config   # blueutil --paired
```

When set, `tpwire` unpairs that address directly; when unset, it falls back to
matching by name. See [`config.example`](config.example). The same variable also
works as a one-off env override: `TPWIRE_MAC=60-fb-42-d5-ca-50 ~/.local/bin/tpwire`.

## How it works

- `bin/tpwire` unpairs the configured `TPWIRE_MAC`, or — if unset — lists paired
  devices, matches `Magic Trackpad`, and unpairs each match. With nothing to
  unpair it is a no-op.
- The LaunchAgent uses `WatchPaths` on
  `/Library/Preferences/com.apple.Bluetooth.plist`. Any pairing change (the
  trackpad coming back over Bluetooth writes to this file) triggers the script
  event-driven — no polling, and nothing touches Wi-Fi or AWDL.

## Manual use

```sh
~/.local/bin/tpwire          # unpair the trackpad right now
blueutil --paired            # verify it is gone
tail -f ~/Library/Logs/tpwire.log
```

## Troubleshooting

If a rare re-pair slips through (macOS sometimes coalesces writes to the
pairing database), add a periodic safety net to the plist — it runs the same
no-op-safe script on an interval:

```xml
<key>StartInterval</key><integer>10</integer>
```

Reload after editing:

```sh
launchctl bootout gui/$(id -u)/black.ruslan.tpwire
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/black.ruslan.tpwire.plist
```

## Uninstall

```sh
./uninstall.sh
```

Previously unpaired trackpads stay unpaired; re-pair them via System Settings if
you want wireless back.

## License

[MIT](LICENSE) © Ruslan Black

## Author

[Ruslan Black](https://ruslan.black/) 🖤

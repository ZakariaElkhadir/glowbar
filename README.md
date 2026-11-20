# LED Strip

![LED Strip](docs/screenshot.png)

Control a Bluetooth LED strip from the Omarchy desktop: switch it on and off,
pick a color, set the brightness, or match the current Omarchy theme.

It talks to `LEDBLE-01-xxxx` strip controllers (sold under many names, such
as the BJ-AP104 "LED Mood Lights" kit, with the MohuanLED app) over Bluetooth
LE. The protocol comes from
[8none1/ledble-ledlamp](https://github.com/8none1/ledble-ledlamp).

The controller accepts one connection at a time, so close the phone app (or
turn off the phone's Bluetooth) while the window is open. The controller
never reports its state, so the window remembers the last light it set.

## Keyboard

| Key | Action |
|-----|--------|
| Space | Turn on or off |
| 1 – 9, 0 | Color presets |
| ← → | Change color |
| ↑ ↓ | Brightness |
| T | Use the theme color |
| R | Search for the strip again |
| ? | Show or hide the shortcuts |
| Q | Quit |

## Build

```sh
bin/build      # build/ledstrip
bin/test       # unit tests, offscreen
bin/install    # makepkg -fsi; then find "LED Strip" with Super + Space
```

Needs `qt6-base`, `qt6-declarative`, `qt6-connectivity`, `qt6-wayland` and
`bluez`.

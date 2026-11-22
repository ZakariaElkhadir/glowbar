# Contributing to Glowbar

Thanks for helping. Bug reports, translations and support for new strip
controllers are the most useful contributions.

## Build and test

You need Qt 6 (see the Requirements table in the README).

```sh
bin/build    # → build/glowbar
bin/test     # unit tests, run offscreen
```

Please run `bin/test` before opening a pull request.

## Supporting another strip controller

Each family of controllers is one class behind the `StripProtocol` interface
in [`src/stripprotocol.h`](src/stripprotocol.h).
[`src/ledbleprotocol.cpp`](src/ledbleprotocol.cpp) is a short, complete
example.

1. Find out how the controller talks. You need:
   - how to recognise it (usually the start of its Bluetooth name),
   - the GATT service and characteristic it accepts writes on,
   - the bytes for on, off and set color.

   Existing Home Assistant integrations or a Bluetooth capture from the
   phone app are good sources. Credit them in your pull request.
2. Add `src/<name>protocol.h` and `.cpp` with a subclass that implements every
   pure-virtual method. If the controller has no brightness command, use
   `StripProtocol::scaled()` to dim the color.
3. Register it in `StripProtocol::all()` in
   [`src/stripprotocol.cpp`](src/stripprotocol.cpp).
4. Add the files to `glowbar.pro` and `tests/glowbar_tests.pro`, and add a test
   that checks the packets it produces.
5. Add the controller to the README's list of supported strips.

## Translations

Strings live in [`src/i18n/`](src/i18n/) as JSON, keyed by the English text.
To add a language, copy `fr.json` to `<code>.json`, translate the values, and
add the file to [`src/resources.qrc`](src/resources.qrc). Glowbar picks the
language Omarchy is set to.

## Pull requests

- Keep each pull request to one change.
- Match the style of the surrounding code.
- Describe how you tested it, especially on real hardware.

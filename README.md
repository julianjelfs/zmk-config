# zmk-config

Personal ZMK config for a wireless Cradio using `nice_nano_v2` controllers.

## Layout files

- `config/cradio.keymap` - main key layout
- `config/cradio.conf` - extra Kconfig settings, including Bluetooth stability tweaks
- `build.yaml` - GitHub Actions build matrix for left/right halves plus reset firmware
- `bluetooth.md` - Bluetooth reconnect, re-pair, and reset instructions

## Local build

This repo has a local build script so you do not need to commit, push, wait for GitHub Actions, and download artifacts just to test a layout change.

Build both halves:

```sh
cd ~/work/zmk-config
./scripts/build-zmk.sh
```

Build a single half:

```sh
./scripts/build-zmk.sh left
./scripts/build-zmk.sh right
```

Build the settings reset firmware:

```sh
./scripts/build-zmk.sh reset
```

Refresh the cached ZMK/Zephyr workspace first:

```sh
./scripts/build-zmk.sh --update
```

Build outputs are written to:

- `firmware/cradio_left-nice_nano_v2.uf2`
- `firmware/cradio_right-nice_nano_v2.uf2`
- `firmware/settings_reset-nice_nano_v2.uf2`

## Flashing

1. Put one half into bootloader mode, usually by pressing reset twice on the nice!nano.
2. When it mounts as a USB drive, copy the matching UF2 file onto it.
3. Flash `cradio_left-nice_nano_v2.uf2` to the left half.
4. Flash `cradio_right-nice_nano_v2.uf2` to the right half.

## Bluetooth

Bluetooth reconnect, re-pair, and full reset instructions now live in [`bluetooth.md`](./bluetooth.md).

## Local tooling

The build script uses:

- a repo-local virtualenv at `.venv/`
- a repo-local cached ZMK workspace at `.zmk-workspace/`

Those paths are ignored by git, along with generated firmware in `firmware/`.

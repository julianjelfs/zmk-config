#!/bin/bash
set -e

VOLUME="/Volumes/NICENANO"
FIRMWARE="$(cd "$(dirname "$0")/.." && pwd)/firmware/cradio_right-nice_nano_v2.uf2"

if [ ! -d "$VOLUME" ]; then
  echo "NICENANO volume not found. Put the right half into bootloader mode (double-tap reset)."
  exit 1
fi

DEVICE=$(diskutil info "$VOLUME" | grep "Device Node" | awk '{print $3}')
echo "Flashing to $DEVICE..."
diskutil unmountDisk "$DEVICE"
sudo dd if="$FIRMWARE" of="$DEVICE" bs=4096
echo "Right half flashed successfully."

#!/usr/bin/env bash
set -euo pipefail

# Headless emulator for working over SSH: ./emulator.sh start|stop
AVD="whatseat"
IMAGE="system-images;android-36;google_apis_playstore;x86_64"

cd "$(dirname "$0")"
emu() { nix develop path:.#emulator -c "$@"; }

case "${1:-}" in
  start)
    if pgrep -u "$USER" -f "qemu-system.*-avd $AVD" > /dev/null; then
      echo "already running"
      exit 0
    fi
    if ! emu avdmanager list avd -c | grep -qx "$AVD"; then
      echo no | emu avdmanager create avd -n "$AVD" -k "$IMAGE" -d pixel_7
    fi
    mkdir -p build
    # setsid: keeps running after the SSH session ends.
    setsid nix develop path:.#emulator -c emulator -avd "$AVD" -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect \
      > build/emulator.log 2>&1 < /dev/null &
    emu adb wait-for-device shell 'while [ "$(getprop sys.boot_completed)" != 1 ]; do sleep 1; done'
    emu adb devices
    ;;
  stop)
    for serial in $(emu adb devices | awk '/^emulator-/ {print $1}'); do
      emu adb -s "$serial" emu kill
    done
    ;;
  *)
    echo "usage: $0 start|stop" >&2
    exit 1
    ;;
esac

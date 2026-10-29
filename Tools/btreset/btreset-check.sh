#!/bin/bash
# Runs once at boot (LaunchDaemon). If macOS has no Bluetooth controller address ~30 s after boot,
# the module is running foreign firmware: reset it to its bootloader, let IntelBTUnified upload its
# own firmware, then restart bluetoothd.
LOG=/var/log/btreset.log
exec >>"$LOG" 2>&1
echo "=== $(date) ==="
sleep 30
addr() { system_profiler SPBluetoothDataType 2>/dev/null | awk -F': ' '/Address:/{print $2; exit}'; }
a=$(addr); echo "controller address: ${a:-none}"
if [ -n "$a" ] && [ "$a" != "NULL" ]; then echo "Bluetooth OK, nothing to do"; exit 0; fi
/usr/local/libexec/btreset || { echo "btreset failed"; exit 1; }
sleep 8                                   # re-enumeration + firmware upload (~2 s) + device boot
pkill -x bluetoothd                       # launchd restarts it with the fresh controller
sleep 10
echo "after reset: $(addr)"

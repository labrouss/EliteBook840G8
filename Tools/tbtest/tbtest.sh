#!/bin/bash
# tbtest.sh — read-only Thunderbolt check for the HP EliteBook 840 G8 (Tiger Lake TB4).
#
# Tiger Lake's Thunderbolt is built into the CPU:
#   00:07.0 / 00:07.1  TB PCIe root ports (TRP0/TRP1)  -> PCIe tunnels appear BEHIND these
#   00:0d.0            TCSS xHCI                         -> USB on the Type-C ports (NOT Thunderbolt)
#   00:0d.2 / 00:0d.3  TB controllers (NHI)              -> macOS has no driver for these
# A device is really running over Thunderbolt only if it shows up behind 00:07.x.
#
# Usage:
#   ./tbtest.sh snap before        # nothing plugged into the Type-C ports
#   (plug in the Thunderbolt device, wait ~15 s)
#   ./tbtest.sh snap after
#   ./tbtest.sh diff before after
#   ./tbtest.sh summary after      # quick verdict for one snapshot
# Snapshots go to ~/tbtest/<name>/. Nothing is changed on the system.

set -u
BASE="$HOME/tbtest"

snap() {
  local d="$BASE/$1"; rm -rf "$d"; mkdir -p "$d"
  sw_vers > "$d/sw_vers.txt"
  # PCI tree: everything under the TB root ports and the TCSS block
  ioreg -p IOService -w0 -l -r -c IOPCIDevice > "$d/ioreg-pci-full.txt" 2>/dev/null
  ioreg -p IOService -w0 -t > "$d/ioreg-tree.txt" 2>/dev/null
  awk '/\+-o /{name=$0} /"pcidebug"/{print name; print}' "$d/ioreg-pci-full.txt" \
      | sed 's/^[ |]*//' > "$d/pci-devices.txt"
  # Profiler views
  for t in SPThunderboltDataType SPPCIDataType SPNVMeDataType SPUSBHostDataType SPUSBDataType SPEthernetDataType SPDisplaysDataType; do
    system_profiler -listDataTypes 2>/dev/null | grep -qx "$t" && system_profiler "$t" > "$d/$t.txt" 2>/dev/null
  done
  # Drivers that matter
  kmutil showloaded 2>/dev/null | grep -iE "thunderbolt|pcie|IOPCI|AppleUSBXHCI|nvme" > "$d/kexts.txt"
  # Recent kernel messages about PCI hot-plug / Thunderbolt
  log show --last 3m --predicate 'sender CONTAINS "IOPCIFamily" OR sender CONTAINS "IOThunderbolt" OR eventMessage CONTAINS[c] "hotplug" OR eventMessage CONTAINS[c] "thunderbolt"' \
      --style compact > "$d/log-3m.txt" 2>/dev/null
  echo "Snapshot saved: $d"
  summary "$1"
}

summary() {
  local d="$BASE/$1"
  echo "=== Summary: $1 ($(sw_vers -productVersion))"
  echo "-- Thunderbolt root ports and anything behind them (pcidebug bus:dev.fn):"
  grep -A1 -E 'TRP[0-9]|pci-bridge@7' "$d/pci-devices.txt" 2>/dev/null | grep -v '^--' | sed 's/^/   /'
  local behind; behind=$(awk -F'"pcidebug" = "' '/pcidebug/{split($2,a,":"); b=a[1]+0; if (b>0) print $2}' "$d/pci-devices.txt" | tr -d '"' | sort -u)
  echo "-- PCI devices on non-zero buses (bridges, tunnels, NVMe, Wi-Fi ...):"
  echo "${behind:-   (none)}" | sed 's/^/   /'
  echo "-- Thunderbolt controller (NHI) 00:0d.2/0d.3 — driver attached?"
  grep -B1 -E '"pcidebug" = "0:13:[23]"' "$d/pci-devices.txt" | grep '+-o' | sed 's/^/   /' || echo "   not listed"
  echo "-- System Information > Thunderbolt/USB4:"
  sed -n '1,15p' "$d/SPThunderboltDataType.txt" 2>/dev/null | sed 's/^/   /'
  echo "-- Thunderbolt-related kexts loaded:"
  sed 's/^/   /' "$d/kexts.txt"
}

diffsnaps() {
  local a="$BASE/$1" b="$BASE/$2"
  echo "=== PCI devices added/removed ($1 -> $2)"
  diff <(grep pcidebug "$a/pci-devices.txt" | sort) <(grep pcidebug "$b/pci-devices.txt" | sort) || true
  for f in SPPCIDataType SPNVMeDataType SPUSBHostDataType SPUSBDataType SPEthernetDataType SPDisplaysDataType SPThunderboltDataType; do
    [ -f "$a/$f.txt" ] && [ -f "$b/$f.txt" ] || continue
    if ! cmp -s "$a/$f.txt" "$b/$f.txt"; then echo "=== $f changed:"; diff "$a/$f.txt" "$b/$f.txt" | head -60; fi
  done
  echo "=== Hot-plug / Thunderbolt log lines in '$2':"
  grep -iE "hotplug|thunderbolt|link up|probe" "$b/log-3m.txt" | tail -30
}

case "${1:-}" in
  snap)    snap "${2:?name}";;
  summary) summary "${2:?name}";;
  diff)    diffsnaps "${2:?before}" "${3:?after}";;
  *) sed -n '2,20p' "$0";;
esac

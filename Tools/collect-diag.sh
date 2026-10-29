#!/bin/bash
# EliteBook 840 G8 hackintosh diagnostics collector
# Run on macOS:  bash collect-diag.sh   -> produces ~/Desktop/840g8-diag-<date>.zip
set -u
OUT="$HOME/Desktop/840g8-diag-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT/acpi"
cd "$OUT" || exit 1
echo "[*] Collecting into $OUT"

sw_vers > sw_vers.txt
uname -a >> sw_vers.txt
nvram boot-args > bootargs.txt 2>&1

# ---- ACPI tables (as macOS sees them, after OpenCore patches) ----
ioreg -a -l -w0 -c AppleACPIPlatformExpert > acpi/ioreg-acpi.plist 2>/dev/null
if command -v python3 >/dev/null 2>&1; then
python3 - "$OUT/acpi" <<'PY'
import plistlib, sys, os
d = sys.argv[1]
root = plistlib.load(open(os.path.join(d, 'ioreg-acpi.plist'), 'rb'))
def walk(n):
    if isinstance(n, dict):
        if 'ACPI Tables' in n:
            for k, v in n['ACPI Tables'].items():
                open(os.path.join(d, k + '.aml'), 'wb').write(v)
                print('   table', k, len(v))
        for v in n.values(): walk(v)
    elif isinstance(n, list):
        for v in n: walk(v)
walk(root)
PY
else
  echo "   python3 missing (install Xcode CLT) - send acpi/ioreg-acpi.plist instead"
fi

# ---- Sleep / wake ----
pmset -g > pmset-settings.txt
pmset -g assertions > pmset-assertions.txt
pmset -g log | grep -E "Sleep  |Wake  |DarkWake|Wake Requests|Failure" | tail -200 > pmset-sleepwake.txt
log show --last 1d --style syslog --predicate 'eventMessage CONTAINS[c] "wake reason"' 2>/dev/null | tail -100 > wake-reasons.txt
sysctl kern.sleeptime kern.waketime machdep.wake_abstime 2>/dev/null > sysctl-sleep.txt
ioreg -l -w0 -p IOPower > ioreg-power.txt

# ---- Display / backlight (WhateverXe receipts) ----
ioreg -l -w0 | grep -E 'TGLBacklightPWM|WhateverXeBacklight|ApplePanel"|AppleBacklightDisplay|"brightness"|PNLF|DisplayProductID|DisplayVendorID' > backlight.txt
echo "--- move the brightness slider a few times, then press Enter ---"; read -r _
ioreg -l -w0 | grep -E 'TGLBacklightPWM|WhateverXeBacklight' > backlight-after-slider.txt

# ---- Bluetooth ----
system_profiler SPBluetoothDataType > bt-profile.txt 2>&1
log show --last boot --style syslog --predicate 'eventMessage CONTAINS[c] "IntelBluetooth" OR eventMessage CONTAINS[c] "IntelBT" OR eventMessage CONTAINS[c] "BlueTool" OR sender == "IntelBTUnified"' 2>/dev/null > bt-log.txt
ioreg -l -w0 -p IOUSB > ioreg-usb.txt
ioreg -l -w0 -c AppleUSBHostPort | grep -E '"name"|UsbConnector|"port"|locationID' > usb-ports.txt

# ---- Audio ----
ioreg -l -w0 -c IOHDACodecDevice > hda-codec.txt
system_profiler SPAudioDataType > audio-profile.txt 2>&1

# ---- Kexts ----
kextstat 2>/dev/null | grep -v com.apple > kexts.txt || kmutil showloaded --no-kernel-components 2>/dev/null | grep -v com.apple > kexts.txt

cd .. && zip -qr "$(basename "$OUT").zip" "$(basename "$OUT")" && echo "[+] Done: $OUT.zip"

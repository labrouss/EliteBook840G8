#!/bin/bash
# EliteBook 840 G8 - Linux live-USB diagnostics (Ubuntu/Fedora live, no installs needed)
# Usage:  sudo bash collect-linux.sh     -> ./840g8-linux-<date>.tar.gz
[ "$(id -u)" = 0 ] || { echo "Run with sudo"; exit 1; }
OUT="840g8-linux-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"/{acpi,dpcd,audio,usb,gpu}
cd "$OUT" || exit 1
echo "[*] Collecting into $PWD"

# ---- System ----
uname -a > uname.txt
cat /sys/class/dmi/id/{sys_vendor,product_name,product_sku,bios_version,bios_date} > dmi.txt 2>/dev/null
cat /proc/cmdline > cmdline.txt
lspci -nnk > lspci.txt
lspci -vvv -s 00:1f.3 > audio/lspci-hda.txt 2>/dev/null
dmesg > dmesg.txt

# ---- Raw OEM ACPI tables (unpatched) ----
for t in /sys/firmware/acpi/tables/*; do
  [ -f "$t" ] && cp "$t" "acpi/$(basename "$t").aml"
done
for t in /sys/firmware/acpi/tables/dynamic/*; do
  [ -f "$t" ] && cp "$t" "acpi/dyn-$(basename "$t").aml"
done
command -v acpidump >/dev/null && acpidump > acpi/acpidump.txt 2>/dev/null

# ---- Sleep ----
{ echo "mem_sleep: $(cat /sys/power/mem_sleep)"; echo "state: $(cat /sys/power/state)"; } > sleep.txt
cat /proc/acpi/wakeup > wakeup-devices.txt 2>/dev/null
grep -r . /sys/firmware/acpi/interrupts/ 2>/dev/null | grep -v ' 0 *disabled\| 0 *enabled *unmasked' > gpe-counters.txt
cat /sys/kernel/debug/pmc_core/slp_s0_residency_usec > pmc-slp_s0.txt 2>/dev/null
cat /sys/kernel/debug/pmc_core/substate_requirements > pmc-substates.txt 2>/dev/null

# ---- Backlight / panel ----
for b in /sys/class/backlight/*; do
  echo "$b: type=$(cat "$b/type") max=$(cat "$b/max_brightness") cur=$(cat "$b/brightness")"
done > backlight.txt 2>/dev/null
grep -iE 'backlight|dpcd|edp|vbt|panel' dmesg.txt > backlight-dmesg.txt
mount | grep -q debugfs || mount -t debugfs none /sys/kernel/debug 2>/dev/null
cp /sys/kernel/debug/dri/0/i915_vbt gpu/vbt.bin 2>/dev/null
cat /sys/kernel/debug/dri/0/i915_display_info > gpu/display_info.txt 2>/dev/null
for c in /sys/class/drm/card*-eDP-*; do
  [ -f "$c/edid" ] && cp "$c/edid" "gpu/$(basename "$c").edid"
done
# eDP DPCD: 0x000-0x00F caps, 0x700-0x72F eDP backlight caps/control (0x701/0x702 = AUX backlight support)
for a in /dev/drm_dp_aux*; do
  n=$(basename "$a"); nm=$(cat /sys/class/drm_dp_aux_dev/"$n"/name 2>/dev/null)
  echo "$n -> $nm" >> dpcd/index.txt
  dd if="$a" bs=1 skip=$((0x000)) count=16 2>/dev/null | xxd > "dpcd/$n-000.txt"
  dd if="$a" bs=1 skip=$((0x700)) count=48 2>/dev/null | xxd > "dpcd/$n-700.txt"
done

# ---- Audio / mic ----
cat /proc/asound/cards > audio/cards.txt 2>/dev/null
cp /proc/asound/card*/codec#* audio/ 2>/dev/null
arecord -l > audio/arecord-l.txt 2>&1
aplay -l > audio/aplay-l.txt 2>&1
grep -iE 'sof|snd|hda|dmic|nhlt|intel-dsp' dmesg.txt > audio/dmesg-audio.txt
lsmod | grep -iE 'snd|sof' > audio/lsmod.txt
cp /sys/firmware/acpi/tables/NHLT audio/NHLT.aml 2>/dev/null   # mic array descriptor
cat /sys/module/snd_intel_dspcfg/parameters/dsp_driver > audio/dsp_driver.txt 2>/dev/null

# ---- USB / Bluetooth ----
lsusb > usb/lsusb.txt
lsusb -t > usb/lsusb-tree.txt
lsusb -v -d 8087: > usb/intel-bt.txt 2>/dev/null
for d in /sys/bus/usb/devices/*; do
  [ -f "$d/idVendor" ] || continue
  printf '%s %s:%s %s | port: %s\n' "$(basename "$d")" "$(cat "$d/idVendor")" "$(cat "$d/idProduct")" \
    "$(cat "$d/product" 2>/dev/null)" "$(readlink -f "$d/port" 2>/dev/null)"
done > usb/devices-ports.txt
for p in /sys/bus/usb/devices/usb*/*-0:1.0/usb*-port*; do
  printf '%s connect_type=%s location=%s\n' "$(basename "$p")" "$(cat "$p/connect_type" 2>/dev/null)" \
    "$(cat "$p/location" 2>/dev/null)"
done > usb/port-types.txt
grep -iE 'bluetooth|btintel|btusb' dmesg.txt > usb/dmesg-bt.txt

cd .. && tar czf "$OUT.tar.gz" "$OUT" && echo "[+] Done: $PWD/$OUT.tar.gz"

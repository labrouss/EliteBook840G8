# btreset: Bluetooth after Linux/Windows (Intel AX201 CNVi)

> **Superseded by SSDT-BTEN + the NVRAM entries in config.plist.** Intel's hard reset (0xFC01) re-enumerates the
> module but keeps the running image, so btreset alone does not fix it. Kept as a diagnostic tool; do not install
> the LaunchDaemon.

**Symptom:** Bluetooth sometimes missing in macOS (`system_profiler SPBluetoothDataType` → `Address: NULL`,
chipset placeholder `BCM_4350C2`); `log show` shows bluetoothd `Transport layer initialization failed`.

**Cause:** the module keeps the firmware that ran last (Linux, Windows, another macOS session) across
restarts and shutdowns on AC power. IntelBTUnified then reports `fw_name = (already running)` and attaches
only once (no upload), and macOS's Bluetooth stack does not accept that firmware.

**Fix:** at boot, if there is no controller address after ~30 s, `btreset` sends Intel's
"reset to bootloader" HCI command (0xFC01, as Linux `btintel` does). The module re-enumerates without
firmware, IntelBTUnified uploads its own, bluetoothd is restarted.

## NVRAM (in config.plist)
As BrcmPatchRAM's README requires for Intel Bluetooth on macOS 12+, OpenCore resets two variables that
bluetoothd writes itself (a failed start would otherwise stick across boots):

| `7C436110-AB2A-4BBB-A880-FE41995C9F82` | Value | Also in `NVRAM > Delete` |
|---|---|---|
| `bluetoothExternalDongleFailed` | `00` | yes |
| `bluetoothInternalControllerInfo` | `0000000000000000000000000000` (14 bytes) | yes |

## Install (once per macOS)
```bash
cd Tools/btreset && sudo ./install.sh      # needs the Xcode command line tools (clang)
```
## Test by hand
```bash
sudo /usr/local/libexec/btreset -n          # list the module
sudo /usr/local/libexec/btreset             # reset it; then:
sleep 8; sudo pkill -x bluetoothd; sleep 10
system_profiler SPBluetoothDataType | grep -E 'Address|State'
cat /var/log/btreset.log                    # boot-time runs
```
## Remove
```bash
sudo launchctl bootout system/com.labrouss.btreset
sudo rm /Library/LaunchDaemons/com.labrouss.btreset.plist /usr/local/libexec/btreset /usr/local/libexec/btreset-check.sh
```

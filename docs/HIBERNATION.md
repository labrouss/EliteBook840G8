# Sleep on the HP EliteBook 840 G8: use hibernation

## Why not normal sleep (S3)
S3 resume hangs **inside HP's firmware** (BIOS T37 01.19.00): F5 + F8 + power LED stay on, only an EC reset
(hold power 15 s, then Win + V for 5 s) recovers. Verified without OpenCore: Ubuntu 26.04 booted via
F9/Ventoy, `deep` sleep → the same hang, and `pm_trace` shows the kernel never resumed. HP only supports
Modern Standby (S0ix) on this model, which macOS cannot use.

Hibernation avoids S3 completely: the memory image is written to disk, the laptop **powers off**, and
waking is a normal cold boot through OpenCore, which hands the image back to macOS.

| | S3 sleep | Hibernation (`hibernatemode 25`) |
|---|---|---|
| Resume | Firmware S3 path (hangs) | Cold boot via OpenCore |
| Battery while asleep | small drain | none (fully off) |
| Sleep / wake time | ~2 s | ~10-20 s each |

## 1. EFI (already in this repo)
| Setting | Value |
|---|---|
| `Kernel > Add` | `HibernationFixup.kext` 1.5.4, right after `Lilu.kext` |
| `Misc > Boot > HibernateMode` | `Auto` |
| `Misc > Boot > HibernateSkipsPicker` | `true` (wake goes straight back to macOS) |

Reboot once after updating the EFI.

## 2. macOS (once per macOS install)
```bash
# hibernate on every sleep: write RAM to disk, then power off
sudo pmset -a hibernatemode 25

# no other sleep variants that could still use S3 or wake the machine
sudo pmset -a standby 0 autopoweroff 0 powernap 0
sudo pmset -a tcpkeepalive 0 womp 0 proximitywake 0

# make sure sleep itself is allowed (undo the old workaround)
sudo pmset -a disablesleep 0

# check
pmset -g | grep -E 'hibernatemode|standby|autopoweroff|powernap|disablesleep|hibernatefile'
```
Expected: `hibernatemode 25`, the others `0`, `hibernatefile /var/vm/sleepimage`.

The sleep image is about the size of the RAM, so keep that much free space on the system volume.

## 3. Test
1. Open an app or a document, then **Apple menu → Sleep** (or close the lid).
2. The screen goes off, the disk writes for a few seconds, then the laptop **powers off completely** (all LEDs off).
3. Press the power button. OpenCore starts, skips the picker and macOS restores the session (progress bar,
   then the login screen with your apps still open).

Check what happened:
```bash
pmset -g log | grep -iE 'hibernat|Wake from|Sleep  ' | tail -10
ls -lh /var/vm/sleepimage
```

| What you see | Means |
|---|---|
| Session restored | Working |
| Normal fresh boot, apps closed | OpenCore did not find the image: check `HibernateMode Auto` and that you rebooted once after the EFI update |
| F5/F8 LEDs again | macOS still used S3: re-check `hibernatemode 25` with `pmset -g` |
| Black screen / hang after the progress bar | Try boot-arg `-hbfx-disable-patch-pci`; for a log add `-hbfx-dump-nvram` |

After restore, the microphone (TGLDmic) boots its DSP again on the next recording; nothing to do.

## Undo
```bash
sudo pmset -a hibernatemode 3      # macOS laptop default (S3 + image) - S3 hangs on this machine!
sudo pmset -a disablesleep 1       # or: never sleep (lid only turns the display off)
```

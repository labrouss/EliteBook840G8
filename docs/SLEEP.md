# Sleep on the HP EliteBook 840 G8: sleep = clean power-off

## Summary
| | |
|---|---|
| Real S3 sleep | **Not possible.** S3 resume hangs inside HP's firmware (BIOS T37 01.19.00): F5 + F8 + power LED stay on, only an EC reset recovers |
| Modern Standby (S0ix) | What HP supports; macOS cannot use it |
| Hibernation | Tried and **dropped**: see "Why not hibernation" |
| **What this EFI does** | macOS sleep powers the laptop off cleanly. The power button boots normally. |

## How it works
`ACPI > Patch` changes `_S3` from sleep type 5 to 7 (soft off, the same as `_S5`):

| Find | Replace | Table |
|---|---|---|
| `5F53335F1207040A05` | `5F53335F1207040A07` | DSDT |

When macOS enters "S3", the chipset powers off instead. macOS has flushed the disks before that, so the
file system is safe; **open apps and unsaved work are lost**, like after a shutdown. On the next boot
`pmset -g log` shows `Failure during sleep … EFI/Bootrom Failure`, which is expected here.

## macOS settings (once per macOS install)
```bash
sudo pmset -a hibernatemode 0 standby 0             # no sleep image
sudo rm -f /var/vm/sleepimage
sudo pmset -a sleep 0                               # no idle sleep: it would power the laptop off
sudo pmset -a displaysleep 10                       # display still turns off when idle
sudo pmset -a powernap 0 tcpkeepalive 0 womp 0 proximitywake 0
sudo pmset -a disablesleep 0                        # Apple menu → Sleep / lid close = power-off
```
Prefer that closing the lid never powers off? Use `sudo pmset -a disablesleep 1` instead: no sleep at all,
the lid only turns the display off.

## Verification of the firmware hang
- macOS: every S3 resume hung (`pmset -g log`: `Failure during sleep: 0x0000001F : EFI/Bootrom Failure`)
- Ubuntu 26.04 booted **without OpenCore** (F9 → Ventoy): `deep` sleep → the same hang;
  `pm_trace` shows only a suspend-path marker (`drivers/base/power/main.c`), i.e. the kernel never resumed

## Why not hibernation
Tried with HibernationFixup 1.5.4 (`hbfx-ahbm=1`, `hibernatemode 3`, standby delay 0), RTCMemoryFixup
(`rtcfx_exclude=80-AB`), `DisableRtcChecksum` and OpenCore `HibernateMode` Auto/NVRAM:
- macOS's sleep policy only hibernates through S3 (image, S3, later wake) unless HibernationFixup forces it;
  forcing it needs standby delay 0 (otherwise it postpones and plain-sleeps).
- With the image written, every restore attempt made the HP BIOS report **Real-Time Clock Power Loss (005)**:
  the hibernation key in RTC 0x80-0xAB overlaps HP's CMOS settings, and boot.efi writes it during the
  restore, before macOS runs.
- The restore itself hung on the (distorted) preview image.

Each failed attempt reset the CMOS, so this was stopped. Possible future attempt: OpenCore
`UEFI > ProtocolOverrides > AppleRtcRam = true` with NVRAM `4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:rtc-blacklist`
= bytes 0x80-0xAB, plus `-hbfx-disable-patch-pci` for the resume hang.

## Undo
Disable the `_S3` patch in `ACPI > Patch` for real S3 (which hangs on this machine).

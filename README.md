# EliteBook840G8



EliteBook 840 G8 - Tiger Lake Hackintosh



Opencore 1.0.8 Latest Kexts as of 28 Oct 2026


[![Hits](https://hits.sh/github.com/labrouss/EliteBook840G8.svg?view=today-total&style=flat-square&label=visits)](https://hits.sh/github.com/labrouss/EliteBook840G8/)


OSX Versions Tested :



* Ventura (iGPU reports 1568MB vRAM, Metal Support: 2)
* Sonoma (iGPU reports 1568MB vRAM, Metal Support: 2)
* Seqouia (iGPU reports 1568MB vRAM, Metal not working ATM)
* Tahoe (iGPU reports 1568MB vRAM, Metal Support: 2)





Working and tested so far :



* Audio Out (Audio buttons) \* For Sequoia, Tahoe, Use HDA-Universal : https://olarila.com/files/macOS-Applications/HDA-Universal/HDAUniversal-1.0.1-Release.zip
* Bluetooth (AX201 CNVi 8087:0026, IntelBTUnified-1.0.0.-full.zip) + SSDT-BTEN (power-cycles the BT core at boot: after Linux/Windows the module kept their firmware and macOS Bluetooth failed) + NVRAM `bluetoothExternalDongleFailed`/`bluetoothInternalControllerInfo` reset on every boot (as BrcmPatchRAM's README requires for Intel BT on macOS 12+)
* WiFi AX201 (CNVi 8086:a0f0) (AirportItlwm) \* For Tahoe, Sequoia, use Laobamac AirportItlwm : https://github.com/laobamac/itlwm
* USB (ACPI Patches), USBMap.kext (ports mapped from Linux; includes the `usb-port-number`/`usb-port-type` keys macOS Tahoe requires)
* Touchpad (VoodooI2C), Use -vi2c-force-polling
* Keyboard (VoodooPS2)
* Camera (USB), In case you get photobooth crashes, try moving the following to disable VADriver :

Camera (USB, HP HD Camera 0408:5348). With WhateverXe-Graphics (Metal) installed, move its video-acceleration bundle away, otherwise the hardware MJPEG decoder crashes (Photo Booth crashes / no image in Settings):

```
sudo mkdir -p /Library/GPUBundles.disabled
sudo mv /Library/GPUBundles/AppleIntelTGLGraphicsVADriver.bundle /Library/GPUBundles.disabled/
sudo killall UVCAssistant VTDecoderXPCService
```

* Battery Icon (ACPI Patch), VoodooSMC
* Thunderbolt 4 (both Type-C ports): PCIe tunnelling, hot-plug and cold-plug work (SSDT-TBT4 + `RMVP`/`built-in` device properties on `00:07.0`/`00:07.1`). Tunnels are built by the firmware; macOS has no driver for the built-in Thunderbolt controller, so System Information > Thunderbolt/USB4 says "No hardware was found" (cosmetic). Set BIOS > Advanced > Port Options > Thunderbolt security level to "PCIe and DisplayPort - No Security". Test tool: [Tools/tbtest](Tools/tbtest/README.md)
* Graphics (WhateverXE 0.6.1, WhatEverXE-Graphics 0.3.2 pkg) :

Same fix as for camera, moving AppleIntelTGLGraphicsVADriver.bundle to /Library/GPUBundles.disabled forces system to CPU only video decoding that also helps with videos on Safari etc. 
```
sudo mkdir -p /Library/GPUBundles.disabled
sudo mv /Library/GPUBundles/AppleIntelTGLGraphicsVADriver.bundle /Library/GPUBundles.disabled/
sudo killall UVCAssistant VTDecoderXPCService
```

* Laptop Display fixed to 1980x1024
* HP Thunderbolt Dock: USB (ASMedia controller, keyboard/receiver), Ethernet (Broadcom 57762, native driver) and dock audio work, hot-plugged or attached at boot. No video out through the dock yet
* **Internal microphone** (4-mic array on the Smart Sound DSP): [TGLDmic](https://github.com/labrouss/TGLDmic) kext + boot-arg `-tgldmic`, plus the TGLDmic `.pkg` (Core Audio plug-in) installed once per macOS. Tested on Ventura (AppleALC) and Tahoe (HDAUniversal)
* TouchID using RidgeKey on https://github.com/labrouss/ridgeKey/ adds finger print reader functionality to my EliteBook 840 G8




Not Working or not tested yet :



* HDMI / HDMI Sound
* Sleep (S3): resume hangs in HP firmware (also on Linux), not fixable from the OS. This EFI turns macOS sleep into a clean power-off: see [docs/SLEEP.md](docs/SLEEP.md)


Tools Used :



OC Auxiliary Tools

SSDTTimer (Live linux image, clone repo install iasl copy iasl into Scripts directory)

Hackintool (PCIe List, Audio Codec)

MaciASL

IORegistryExplorer







&#x20;


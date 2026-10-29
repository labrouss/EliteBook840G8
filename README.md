# EliteBook840G8



EliteBook 840 G8 - Tiger Lake Hackintosh



Opencore 1.0.8 Latest Kexts as of 28 Oct 2026





OSX Versions Tested :



* Ventura (iGPU reports 1568MB vRAM, Metal Support: 2)
* Sonoma (iGPU reports 1568MB vRAM, Metal Support: 2)
* Seqouia (iGPU reports 1568MB vRAM, Metal not working ATM)
* Tahoe (iGPU reports 1568MB vRAM, Metal Support: 2)





Working and tested so far :



* Audio Out (Audio buttons) \* For Sequoia, Tahoe, Use HDA-Universal : https://olarila.com/files/macOS-Applications/HDA-Universal/HDAUniversal-1.0.1-Release.zip
* Bluetooth (AX201 CNVi 8087:0026, IntelBTUnified-1.0.0.-full.zip)
* WiFi AX201 (CNVi 8086:a0f0) (AirportItlwm) \* For Tahoe, Sequoia, use Laobamac AirportItlwm : https://github.com/laobamac/itlwm
* USB (ACPI Patches), USBMap.kext (ports mapped from Linux; includes the `usb-port-number`/`usb-port-type` keys macOS Tahoe requires)
* Touchpad (VoodooI2C), Use -vi2c-force-polling
* Keyboard (VoodooPS2)
* Camera (USB)
* Battery Icon (ACPI Patch), VoodooSMC
* Thunderbolt ports 0/1 (ACPI Patch + Device Patch)
* Graphics (WhateverXE 0.6.1, WhatEverXE-Graphics 0.3.2 pkg) : 
* Laptop Display fixed to 1980x1024
* HP Thunderbolt Docking Station (ATM, No Video out)
* **Internal microphone** (4-mic array on the Smart Sound DSP): [TGLDmic](https://github.com/labrouss/TGLDmic) kext + boot-arg `-tgldmic`, plus the TGLDmic `.pkg` (Core Audio plug-in) installed once per macOS. Tested on Ventura (AppleALC) and Tahoe (HDAUniversal)



Not Working or not tested yet :



* HDMI / HDMI Sound
* Sleep (S3): resume hangs in HP firmware (also on Linux), not fixable from the OS. This EFI turns macOS sleep into a clean power-off: see [docs/SLEEP.md](docs/SLEEP.md)
* TouchID Might work (https://github.com/hackintosh-user/hack-touchid, https://github.com/MarcelineVPQ/elitebook840-fingerprint)



Tools Used :



OC Auxiliary Tools

SSDTTimer (Live linux image, clone repo install iasl copy iasl into Scripts directory)

Hackintool (PCIe List, Audio Codec)

MaciASL

IORegistryExplorer







&#x20;


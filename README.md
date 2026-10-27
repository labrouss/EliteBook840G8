# EliteBook840G8



EliteBook 840 G8 - Tiger Lake Hackintosh



Opencore 1.0.8 Latest Kexts as of 26 Oct 2026





OSX Versions Tested :



* Ventura (iGPU reports 1568MB vRAM, Metal Support: 2)
* Sonoma (iGPU reports 1568MB vRAM, Metal Support: 2)
* Seqouia (iGPU reports 1568MB vRAM, Metal not working ATM)
* Tahoe (iGPU reports 1568MB vRAM, Metal Support: 2)





Working and tested so far :



* Audio Out (Audio buttons)
* Bluetooth (AX210, IntelBTUnified-1.0.0.-full.zip)
* WiFI AX210 (AirportItlwm)
* USB (ACPI Patches)
* Touchpad (VoodooI2C)
* Keyboard (VoodooPS2)
* Camera (USB)
* Battery Icon (ACPI Patch), VoodooSMC
* Thunderbolt ports 0/1 (ACPI Patch + Device Patch)
* Graphics (WhateverXE 0.6.0, WhatEverXE-Graphics 0.3.1 pkg)
* Laptop Display fixed to 1980x1024
* HP Thunderbolt Docking Station (ATM, No Video out)



Not Working or not tested yet :



* Microphone
* HDMI / HDMI Sound
* Metal
* Sleep/Wake
* TouchID Might work (https://github.com/hackintosh-user/hack-touchid, https://github.com/MarcelineVPQ/elitebook840-fingerprint)



Tools Used :



OpenCore Configurator

SSDTTimer (Live linux image, clone repo install iasl copy iasl into Scripts directory)

Hackintool (PCIe List, Audio Codec)

MaciASL

IORegistryExplorer







&#x20;


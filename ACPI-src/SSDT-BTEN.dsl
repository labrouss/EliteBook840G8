/*
 * SSDT-BTEN: power-cycle the Intel CNVi Bluetooth core once at boot (macOS only).
 *
 * The AX201 BT module keeps the firmware that ran last (Linux/Windows) across restarts and shutdowns on AC,
 * and Intel's HCI hard reset restarts that same image. IntelBTUnified then reports "(already running)" and
 * macOS's bluetoothd fails ("Transport layer initialization failed", Address NULL).
 * HP's DSDT has \_SB.PC00.SBTE (BT enable GPIO 0x090A0000 + CNVi BT enable via S023(3,x)) and GBTE.
 * Switching it off and on again clears the firmware; the module then enumerates in bootloader mode and
 * IntelBTUnified uploads its own firmware.
 */
DefinitionBlock ("", "SSDT", 2, "HACK", "BTEN", 0x00000000)
{
    External (_SB_.PC00.SBTE, MethodObj)   // 1 arg: 0 = BT off, 1 = BT on
    External (_SB_.PC00.GBTE, MethodObj)   // 0 args
    External (_SB_.PC00.CNIP, MethodObj)   // 0 args: CNVi present

    Scope (\_SB)
    {
        Device (BTEN)
        {
            Name (_HID, "BTEN0000")
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin")) { Return (0x0B) }
                Return (Zero)
            }

            Method (_INI, 0, Serialized)
            {
                If (_OSI ("Darwin") && CondRefOf (\_SB.PC00.SBTE) && CondRefOf (\_SB.PC00.CNIP))
                {
                    If (\_SB.PC00.CNIP ())
                    {
                        \_SB.PC00.SBTE (Zero)     // BT core off: firmware in RAM is lost
                        Sleep (250)
                        \_SB.PC00.SBTE (One)      // BT core on: boots into its bootloader
                        Sleep (250)
                    }
                }
            }
        }
    }
}

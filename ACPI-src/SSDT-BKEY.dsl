/*
 * EliteBook 840 G8 - brightness keys (Fn+F3/F4)
 * Requires ACPI renames in DSDT: _Q86 -> XQ86, _Q87 -> XQ87
 * OEM path: _Q86/_Q87 -> \_GPE.G400 only if G289==1 -> G40B -> Notify(GFX0.DD1F, 0x86/0x87).
 * When G289==0 HP routes the keys through WMI (never serviced on macOS), so notify DD1F directly.
 */
DefinitionBlock ("", "SSDT", 2, "HACK", "BKEY", 0x00000000)
{
    External (_SB_.PC00.LPCB.EC0_, DeviceObj)
    External (_SB_.PC00.LPCB.EC0_.XQ86, MethodObj)
    External (_SB_.PC00.LPCB.EC0_.XQ87, MethodObj)
    External (_SB_.PC00.GFX0.DD1F, DeviceObj)

    Scope (\_SB.PC00.LPCB.EC0)
    {
        Method (_Q86, 0, NotSerialized)  // brightness up
        {
            If (_OSI ("Darwin"))
            {
                Notify (\_SB.PC00.GFX0.DD1F, 0x86)
            }
            Else
            {
                \_SB.PC00.LPCB.EC0.XQ86 ()
            }
        }

        Method (_Q87, 0, NotSerialized)  // brightness down
        {
            If (_OSI ("Darwin"))
            {
                Notify (\_SB.PC00.GFX0.DD1F, 0x87)
            }
            Else
            {
                \_SB.PC00.LPCB.EC0.XQ87 ()
            }
        }
    }
}

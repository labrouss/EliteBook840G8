/*
 * Instant-wake fix for EliteBook 840 G8. Requires DSDT rename GPRW -> XPRW.
 * 0x6D: PCH xHCI/XDCI/GbE/TBT xHCI+NHI (TXHC/TDM0/TDM1)
 * 0x69: Thunderbolt 4 root ports TRP0/TRP1 and PCIe root ports
 * 0x0D: legacy PME
 * Returning sleep state 0 = "can't wake from S3" for these devices on macOS only.
 */
DefinitionBlock ("", "SSDT", 2, "HACK", "GPRW", 0x00000000)
{
    External (XPRW, MethodObj)    // 2 Arguments

    Method (GPRW, 2, NotSerialized)
    {
        If (_OSI ("Darwin"))
        {
            If ((0x6D == Arg0))
            {
                Return (Package (0x02) { 0x6D, Zero })
            }

            If ((0x69 == Arg0))
            {
                Return (Package (0x02) { 0x69, Zero })
            }

            If ((0x0D == Arg0))
            {
                Return (Package (0x02) { 0x0D, Zero })
            }
        }

        Return (XPRW (Arg0, Arg1))
    }
}

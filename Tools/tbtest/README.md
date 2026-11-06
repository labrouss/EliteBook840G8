# tbtest — Thunderbolt check

Read-only script that shows whether a device is really running over
Thunderbolt (a PCIe tunnel behind the TB root ports `00:07.0`/`00:07.1`)
or has fallen back to plain USB-C (`00:0d.0`).

```bash
./tbtest.sh snap before            # nothing in the Type-C ports
# plug in the Thunderbolt device, wait ~15 s
./tbtest.sh snap after
./tbtest.sh diff before after      # what appeared, plus hot-plug log lines
./tbtest.sh summary after          # quick view of one snapshot
```

For a cold-plug test: shut down, attach the device, power on, then
`./tbtest.sh snap coldboot` and `./tbtest.sh diff before coldboot`.

Snapshots are saved in `~/tbtest/<name>/`. Nothing on the system is changed.

## Expected on the EliteBook 840 G8

- Dock bridges (`8086:1578` for an Alpine Ridge dock) appear behind `TRP0` or
  `TRP1`, and the dock's PCIe devices (USB controller, Ethernet) get drivers.
- `TDM0`/`TDM1` (the built-in Thunderbolt controllers, `00:0d.2`/`00:0d.3`)
  have no driver, and System Information > Thunderbolt/USB4 says
  "No hardware was found". Both are normal.
- If nothing appears behind `00:07.x`, check the BIOS Thunderbolt security
  level ("PCIe and DisplayPort - No Security") and use a Thunderbolt cable.

Tested on macOS Tahoe 26.7.1 with an HP Thunderbolt Dock: hot-plug and
cold-plug both work.

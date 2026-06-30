# Hardware Probe Notes

## Environment

- Date: 2026-06-30
- macOS: 26.5.1 (`25F80`)
- Architecture: `arm64`
- Swift target observed from toolchain: `arm64-apple-macosx26.0`

## Attached Wired Mouse

Command:

```bash
swift run RazerShaperProbe list --likely-ouroboros
```

Observed devices:

```text
[0] product=Razer Ouroboros manufacturer=Razer vid=0x1532 pid=0x0032 usagePage=0x01 usage=0x02 interface=0 maxFeature=90 transport=USB flags=razer,likely-ouroboros,feature90
[1] product=Razer Ouroboros manufacturer=Razer vid=0x1532 pid=0x0032 usagePage=0x01 usage=0x06 interface=1 maxFeature=1 transport=USB flags=razer,likely-ouroboros
[2] product=Razer Ouroboros manufacturer=Razer vid=0x1532 pid=0x0032 usagePage=0x01 usage=0x06 interface=2 maxFeature=0 transport=USB flags=razer,likely-ouroboros
```

Interpretation:

- The user-reported `RC30-007701` wired mouse enumerates as `Razer Ouroboros`.
- USB vendor ID is confirmed as `0x1532`.
- USB product ID is confirmed as `0x0032`.
- Interface `0` is the mouse interface and exposes `MaxFeatureReportSize=90`, matching the archived Razer protocol notes.
- Interfaces `1` and `2` expose keyboard usage (`usagePage=0x01`, `usage=0x06`), which matches the expectation that extra controls may arrive through keyboard-like HID interfaces.

## Read-Only Feature Reports

Command pattern:

```bash
.build/debug/RazerShaperProbe feature --packet <name> --likely-ouroboros
```

Sequential read-only probes succeeded on interface `0` with transaction ID `0xFF`:

| Packet | Set | Get | Status | Notes |
| --- | --- | --- | --- | --- |
| `firmware` | `0x0` | `0x0` | `0x02` | Response args `01 05`, interpreted as firmware `1.05`. |
| `battery` | `0x0` | `0x0` | `0x02` | Response args are currently `00 00` while wired. Keep raw until battery semantics are confirmed. |
| `charging` | `0x0` | `0x0` | `0x02` | Response args are currently `00 02` while wired. Keep raw until charging semantics are confirmed. |
| `dpi` | `0x0` | `0x0` | `0x02` | Response args include `20 08 20 08`, interpreted as `8200 x 8200` DPI. |
| `polling` | `0x0` | `0x0` | `0x02` | Response arg `01`, interpreted as `1000Hz`. |

Important: do not run multiple feature probes in parallel. The mouse returns valid responses, but parallel probe processes can read each other's pending response and confuse the output.

## Event Capture Status

`RazerShaperProbe capture` with IOHID did not capture left-click events in filtered or vendor-inclusive mode. `RazerShaperProbe tap-capture` created a read-only event tap but captured no events in the test window.

Permission check:

```bash
swift run RazerShaperProbe permissions
```

Current result:

```text
Input Monitoring listen access: granted
Input Monitoring post access: granted
Accessibility trusted: granted
```

The event-tap probe now uses the session tap location for translated system events. If it still captures nothing, repeat the command while pressing the target control during the capture window.

Next button-mapping attempt should start with:

```bash
swift run RazerShaperProbe tap-capture --label "left click" --seconds 8
```

If it still reports no CGEvents, grant permission for the built probe executable from System Settings before continuing the physical button map.

## Probe Commands

Protocol and community reference files from `Razer_Ouroboros_macOS_Archive.zip` are extracted under `References/archive/` for local searching.

List all Razer HID interfaces:

```bash
swift run RazerShaperProbe list
```

List only the likely Ouroboros interfaces:

```bash
swift run RazerShaperProbe list --likely-ouroboros
```

Listen for button/key/media-style HID input without pointer-motion noise:

```bash
swift run RazerShaperProbe listen --likely-ouroboros --seconds 30
```

Capture one physical control at a time and summarize unique HID events:

```bash
swift run RazerShaperProbe capture --likely-ouroboros --label "side button 6" --seconds 5
```

Capture every raw HID value, including pointer motion and vendor-defined reports:

```bash
swift run RazerShaperProbe listen --likely-ouroboros --seconds 30 --raw
```

Print a known 90-byte feature report without sending it to hardware:

```bash
swift run RazerShaperProbe packet --packet firmware
```

Send a read-only feature report and print the response:

```bash
swift run RazerShaperProbe feature --packet firmware --likely-ouroboros
```

## Button Map Status

The probe can now enumerate the device, listen for raw HID input, and capture one labeled control at a time. A button-by-button guided capture still needs to be recorded for:

- left and right click
- wheel click
- sensitivity stage up/down
- side buttons 6/7/9/10
- left/right trigger or clutch controls

The raw listener produced a large amount of pointer-motion data, so the default listener and capture command suppress generic desktop X/Y/wheel motion and vendor-defined reports. Use `--raw` only when the filtered listener misses a control.

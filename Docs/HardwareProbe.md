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

## Probe Commands

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

Capture every raw HID value, including pointer motion and vendor-defined reports:

```bash
swift run RazerShaperProbe listen --likely-ouroboros --seconds 30 --raw
```

Print a known 90-byte feature report without sending it to hardware:

```bash
swift run RazerShaperProbe packet --packet firmware
```

## Button Map Status

The probe can now enumerate the device and listen for raw HID input. A button-by-button guided capture still needs to be recorded for:

- left and right click
- wheel click
- sensitivity stage up/down
- side buttons 6/7/9/10
- left/right trigger or clutch controls

The raw listener produced a large amount of pointer-motion data, so the default listener now suppresses generic desktop X/Y/wheel motion and vendor-defined reports. Use `--raw` only when the filtered listener misses a control.

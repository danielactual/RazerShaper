# RazerShaper Roadmap

## North Star

RazerShaper should become a small, dependable macOS 26+ utility for a wired discontinued Razer mouse labeled `RC30-007701`. The first useful version should let the user see exactly what each physical button emits, then map those buttons to practical macOS actions without disturbing other input devices.

## Current Assumptions

- Target hardware: user-reported model label `RC30-007701`.
- Likely reference family: Razer Ouroboros / `RZ01-00770`, pending wired-device probe.
- Initial transport: wired USB only.
- Initial OS target: macOS 26+.
- Initial strategy: probe first, remap second.
- UI direction: quiet menu bar utility with a compact configuration window.
- Hardware control path: IOHID feature reports, only after the wired device identity is confirmed.
- Button remap path: global event tap plus strict source-device filtering.

## Milestone 0: Repository and Reference Foundation

Status: in progress

Goals:

- Initialize the Git repository and connect it to GitHub.
- Preserve existing research/reference material.
- Document the implementation plan before writing app code.

Deliverables:

- `TASKS.md`
- `Roadmap.md`
- `.gitignore`
- Initial README
- Organized `References/` directory

Exit criteria:

- The repository can be cloned and understood without needing the original desktop folder layout.
- Reference archives remain available but do not crowd the source tree.
- The next implementation step is unambiguous.

## Milestone 1: Probe CLI

Status: in progress

Goals:

- Build a Swift command-line probe that can run before the UI exists.
- Enumerate matching HID devices and print device/interface metadata.
- Detect whether the attached wired mouse matches the archived Ouroboros assumptions.
- Log physical button activity without remapping anything.

Deliverables:

- `Package.swift`
- `Sources/RazerShaperCore`
- `Sources/RazerShaperProbe`
- HID device enumeration
- Event logger mode
- Report builder unit tests
- `Docs/HardwareProbe.md`

Exit criteria:

- Running the probe with the mouse attached prints VID, PID, product name, manufacturer, usage page, usage, interface number, and max feature report size where available.
- Pressing each relevant physical button produces a clear log entry.
- The probe distinguishes the target mouse from other mice/keyboards.
- The app does not suppress or alter user input in this milestone.

Progress:

- The wired mouse enumerates as `Razer Ouroboros`, VID `0x1532`, PID `0x0032`.
- Interface `0` exposes `MaxFeatureReportSize=90`.
- The probe CLI can list devices, print packet bytes, and listen for HID input.
- The probe CLI can capture one labeled control at a time for button mapping.
- Read-only feature reports work on wired interface `0` with transaction ID `0xFF`.
- Remaining work is a guided button-by-button capture.

## Milestone 2: HID Protocol Core

Status: planned

Goals:

- Implement the Razer 90-byte feature report model in Swift.
- Confirm safe wired-mode read operations before attempting write operations.
- Isolate hardware commands behind a small testable API.

Deliverables:

- `RazerReport`
- checksum tests
- command builders for firmware, battery, charging state, DPI, polling rate, LED brightness, idle time, and low-battery threshold
- IOHID feature report send/read wrapper
- response status parser

Exit criteria:

- Unit tests verify report length, command bytes, argument placement, and checksum behavior.
- A read-only firmware or battery command succeeds on the attached wired device, or logs a clear unsupported/permission/interface failure.
- No write command runs unless explicitly invoked from a diagnostic path.

## Milestone 3: Minimal Remapper

Status: planned

Goals:

- Convert the confirmed button map into configurable actions.
- Support the most valuable everyday mappings before advanced profile/UI work.

Deliverables:

- button identity model
- action model
- pass-through action
- disable/suppress action
- keyboard shortcut action
- mouse button 4/back and mouse button 5/forward actions
- scroll up/down actions
- minimal JSON or UserDefaults profile storage

Exit criteria:

- One confirmed physical button can be remapped and suppressed reliably.
- Unmapped buttons continue to pass through normally.
- Remapping only applies to the target wired mouse.
- Rapid button presses do not disable or stall the event tap.

## Milestone 4: Menu Bar Utility

Status: planned

Goals:

- Wrap the working remapper in a compact macOS 26+ menu bar app.
- Make permissions and device state understandable.
- Keep configuration fast and sparse, with diagnostics close at hand.

Deliverables:

- menu bar status item
- compact settings window
- device connection status
- button mapping editor
- permission status/onboarding
- diagnostics log view
- reset-to-pass-through command
- launch-at-login option

Exit criteria:

- The utility can be launched, configured, quit, and relaunched without losing mappings.
- The menu bar item clearly shows whether the target mouse is connected.
- Missing permissions result in clear recovery guidance.
- The app is usable without opening Terminal.

## Milestone 5: Profiles

Status: planned

Goals:

- Add profile behavior once the base remapper is stable.
- Support both a default profile and app-specific overrides.

Deliverables:

- profile list
- default profile
- per-application profile rules keyed by bundle identifier
- `NSWorkspace.didActivateApplicationNotification` switching
- profile import/export

Exit criteria:

- Active profile changes when the frontmost app changes.
- If no app-specific profile exists, the default profile applies.
- Profile changes do not interrupt held buttons or leave stuck synthetic events.

## Milestone 6: Device Feature Controls

Status: planned

Goals:

- Add safe hardware controls that have been proven against the wired device.
- Keep risky or uncertain commands in diagnostics until verified.

Deliverables:

- current DPI readout, if supported
- DPI setter, if supported
- polling rate selector, if supported
- battery/charging readout, if supported over wired USB
- LED brightness control, if supported
- idle time and low-battery threshold controls, if supported

Exit criteria:

- Each exposed control has been tested on the actual wired mouse.
- Failed or unsupported commands are surfaced without crashing the app.
- Settings that may affect tracking behavior require deliberate user action.

## Milestone 7: Release Hardening

Status: planned

Goals:

- Make the app boring in the best possible way: resilient, recoverable, and easy to install locally.

Deliverables:

- build instructions
- local signing notes
- permission reset instructions
- troubleshooting guide
- regression checklist
- optional release artifact

Exit criteria:

- Fresh checkout builds successfully on the target macOS 26+ development machine.
- The app handles no-device, unplug/replug, sleep/wake, and permission-denied states.
- The repository has enough documentation for future maintenance.

## Risks and Unknowns

- The `RC30-007701` label may refer to a component or regional model while USB descriptors expose a different product identity.
- Extra buttons may appear as mouse events, keyboard events, proprietary HID input reports, or a mix.
- macOS 26+ may have event-tap or IOHID permission behavior that differs from archived examples.
- Some Razer feature reports may work only on a different interface or with a transaction ID other than `0xFF`.
- The app may need Accessibility permission for selected synthetic actions even if basic listening works with Input Monitoring.
- Hardware write commands can alter device behavior, so write support should come after read-only probing and explicit confirmation.

## Near-Term Next Steps

- Scaffold the Swift package and probe CLI.
- Organize references into a stable `References/` directory.
- Add report-builder tests before touching hardware.
- Implement HID enumeration for the wired target.
- Run the probe with the mouse attached and record the real button map.

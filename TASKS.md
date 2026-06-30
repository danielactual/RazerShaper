# RazerShaper Tasks

## Project Goal

Build a native Swift macOS 26+ utility for an old/discontinued wired Razer gaming mouse labeled `RC30-007701`, focused first on assigning functions to physical mouse buttons and then, if validated against the hardware, configuring device features such as DPI, polling rate, lighting, battery status, idle time, and low-battery threshold.

## Directory Review

- [x] Confirmed this folder is reference material, not an existing Swift project or Git repository.
- [x] Reviewed `References/Creating Custom Software for Razer Ouroboros on macOS/Razer Ouroboros (RZ01-00770) - macOS Driver Development Reference.md`.
- [x] Reviewed `References/Creating Custom Software for Razer Ouroboros on macOS/notes_official_sources.md`.
- [x] Reviewed `References/Creating Custom Software for Razer Ouroboros on macOS/ButtonInputReceiver.m`.
- [x] Reviewed `References/Creating Custom Software for Razer Ouroboros on macOS/OuroborosOMG-ENG.txt` and checked the companion PDF metadata.
- [x] Listed both zip archives and inspected the development archive manifest.
- [x] Spot-checked archived OpenRazer, librazermacos, Mac Mouse Fix, Razer battery monitor, per-app profile, and protocol testing references.
- [x] Initialized local Git repository on `main` and set `origin` to `https://github.com/danielactual/RazerShaper.git`.
- [x] Moved reference material under `References/`.

## Key Findings

- [x] User-reported target model label is `RC30-007701`.
- [x] Local Swift toolchain target is `arm64-apple-macosx26.0`.
- [x] Current references identify the likely product family as Razer Ouroboros `RZ01-00770`; confirm this against the attached wired device before hard-coding behavior beyond discovery.
- [x] Razer USB vendor ID is `0x1532`; Ouroboros product ID is `0x0032`.
- [x] The mouse likely exposes multiple HID interfaces: mouse plus keyboard-like interfaces for extra controls.
- [x] Feature-report configuration appears to use 90-byte Razer HID packets with XOR checksum over bytes 2 through 87.
- [x] OpenRazer explicitly supports `USB_DEVICE_ID_RAZER_OUROBOROS` and exposes `dpi`, `poll_rate`, `charge_level`, `charge_status`, `scroll_led_brightness`, `scroll_matrix_effect_on`, `scroll_matrix_effect_none`, `device_idle_time`, and `charge_low_threshold`.
- [x] The Mac Mouse Fix sample demonstrates a viable macOS strategy for extra mouse buttons: `CGEventTapCreate`, `CGEventGetSendingDevice`, device filtering, optional event suppression, and synthetic event posting.
- [x] The bundled `Testing_Guide.md` has useful `hidapitester` commands, but its Python CRC helper contains a placeholder return and must not be copied as-is.

## Working Architecture

- [ ] Use a small Swift core module for HID protocol, device discovery, button event parsing, profile storage, and action execution.
- [ ] Use a macOS menu bar app as the main UI, likely with `LSUIElement = YES`.
- [ ] Keep the app unsandboxed unless hardware testing proves sandboxing still allows the required IOHID access.
- [x] Start with an observable/probe-oriented build so we can safely map the real button events before remapping them.
- [ ] Split hardware feature reports from button remapping so the app remains useful even if some device-configuration commands need later reverse engineering.
- [x] Scope the first hardware path to wired USB only.

## Phase 1: Project Setup

- [x] Decide whether to initialize Git in this folder.
- [ ] Create a clean source layout:
  - [x] `Sources/RazerShaperCore`
  - [x] `Sources/RazerShaperProbe`
  - [ ] `RazerShaperApp`
  - [x] `Tests/RazerShaperCoreTests`
  - [x] `References`
- [x] Move or copy the current reference material under `References` without losing the original archive contents.
- [ ] Extract `Razer_Ouroboros_macOS_Archive.zip` into `References/archive` for searchable local development.
- [x] Create an initial `Package.swift` for shared Swift code and a probe CLI.
- [ ] Create or generate a macOS app target for the menu bar utility.
- [x] Add a short project README explaining the hardware target, permission requirements, and current development status.
- [x] Create `Roadmap.md`.

## Milestone 1: Probe CLI

- [x] Scaffold `RazerShaperCore` and `RazerShaperProbe`.
- [x] Implement `RazerReport` as a 90-byte packet builder.
- [x] Implement checksum calculation and unit tests for XOR bytes 2 through 87.
- [x] Implement command builders for firmware, battery, charging state, DPI, polling rate, LED brightness, idle time, and low-battery threshold.
- [x] Implement HID enumeration with VID/PID, usage, interface, and max feature report metadata.
- [x] Implement `RazerShaperProbe list`.
- [x] Implement `RazerShaperProbe packet` for local packet inspection without hardware writes.
- [x] Implement `RazerShaperProbe listen`.
- [x] Add default listener filtering so pointer motion does not overwhelm button-capture sessions.
- [x] Add `--raw`, `--include-motion`, and `--include-vendor` options for deeper diagnostics.
- [x] Verify attached wired mouse enumerates as Razer Ouroboros VID `0x1532`, PID `0x0032`.
- [x] Identify wired control interface: interface `0`, usage page `0x01`, usage `0x02`, max feature report size `90`.
- [x] Record probe commands and findings in `Docs/HardwareProbe.md`.
- [ ] Capture a guided button-by-button map for every physical control.
- [ ] Record whether each extra control appears as mouse button, keyboard, consumer-control, or vendor-defined HID input.

## Phase 2: Hardware Reconnaissance

- [ ] Collect local hardware facts with the mouse attached:
  - [x] macOS version
  - [x] CPU architecture
  - [x] wired USB identifiers
  - [x] HID usage pages/usages
  - [x] interface numbers
  - [x] max feature report sizes
- [x] Run `hidapitester --vidpid 1532 --list-detail` or an equivalent Swift probe.
- [x] Identify the HID control interface with max feature report size `90`.
- [ ] Verify whether transaction ID `0xFF` works for wired mode.
- [ ] Capture a physical button map for every button:
  - [ ] left/right/main buttons
  - [ ] wheel click
  - [ ] sensitivity up/down
  - [ ] side buttons 6/7/9/10
  - [ ] left/right trigger or clutch controls
- [ ] Record whether extra controls appear as mouse events, keyboard events, proprietary HID input reports, or a mix.

## Phase 3: Swift HID Protocol Layer

- [ ] Implement `RazerReport` as a 90-byte packet builder.
- [ ] Implement checksum calculation and unit tests for XOR bytes 2 through 87.
- [ ] Implement command builders for:
  - [ ] get firmware version
  - [ ] get/set DPI
  - [ ] get/set polling rate
  - [ ] get battery level
  - [ ] get charging status
  - [ ] get/set scroll LED brightness
  - [ ] set scroll LED on/off
  - [ ] get/set idle time
  - [ ] get/set low-battery threshold
- [ ] Implement `IOHIDManager` device matching for VID `0x1532` and PID `0x0032`.
- [ ] Implement control-interface selection by feature report size and usage/interface metadata.
- [ ] Implement feature report send/read with clear timeout and status handling.
- [ ] Add structured logging for all outgoing reports and responses.
- [ ] Add unit tests for packet construction without requiring hardware.

## Phase 4: Button Event Capture

- [ ] Implement a global event tap for `otherMouseDown` and `otherMouseUp`.
- [ ] Add keyboard event capture only if the hardware reconnaissance shows extra buttons arrive as keyboard events.
- [ ] Use `CGEventGetSendingDevice` to identify whether an event came from the Ouroboros.
- [ ] Add a fallback IOHID input callback path if `CGEventGetSendingDevice` is unreliable on the target macOS version.
- [ ] Build an event-inspector mode that logs physical button, down/up state, source device, usage, and raw fields.
- [ ] Filter strictly to the target mouse to avoid remapping other mice, keyboards, tablets, or synthetic events.
- [ ] Handle tap disablement and timeout by re-enabling the tap and keeping heavy work off the tap callback.
- [ ] Verify event capture on macOS 26+ specifically.

## Phase 5: Action and Profile Engine

- [ ] Define an action model:
  - [ ] pass through
  - [ ] disable/suppress
  - [ ] keyboard shortcut
  - [ ] mouse button 4/back
  - [ ] mouse button 5/forward
  - [ ] double click
  - [ ] scroll up/down
  - [ ] media controls
  - [ ] launch application
  - [ ] switch profile
  - [ ] DPI stage up/down
  - [ ] temporary DPI clutch
  - [ ] macro playback, if wanted
- [ ] Implement event suppression for remapped buttons.
- [ ] Implement synthetic event posting for keyboard, mouse, scroll, and media actions.
- [ ] Add debounce/repeat behavior where needed for held buttons.
- [ ] Store profiles as Codable JSON or UserDefaults.
- [ ] Add default and per-application profiles keyed by bundle identifier.
- [ ] Observe `NSWorkspace.didActivateApplicationNotification` for automatic profile switching.
- [ ] Add import/export for profiles after the storage format stabilizes.

## Phase 6: Menu Bar App

- [ ] Build a menu bar status item showing device connected/disconnected state.
- [ ] Add first-run permission onboarding for Input Monitoring and any Accessibility permission proven necessary.
- [ ] Add a device status view:
  - [ ] connection mode
  - [ ] battery level
  - [ ] charging state
  - [ ] current DPI
  - [ ] current polling rate
- [ ] Add a button-mapping editor using the captured physical button map.
- [ ] Add an action picker for each assignable button.
- [ ] Add a profile picker and per-app profile assignment UI.
- [ ] Add a diagnostics pane with event logs and last HID response status.
- [ ] Add launch-at-login support.
- [ ] Add a safe reset option that restores all mappings to pass-through.

## Phase 7: Permissions, Signing, and Packaging

- [ ] Verify exact permission requirements on the target macOS version.
- [ ] Confirm whether Input Monitoring alone is enough for listening and posting events.
- [ ] Confirm whether Accessibility is required for any chosen action type.
- [ ] Keep App Sandbox disabled if IOHID feature reports fail under sandboxing.
- [ ] Define signing settings for local development.
- [ ] Add a release signing/notarization path if this will be distributed beyond this machine.
- [ ] Document manual permission reset steps for testing.

## Phase 8: Validation

- [ ] Run unit tests for report construction and profile/action models.
- [ ] Run the probe CLI with the mouse disconnected and connected.
- [ ] Verify no event tap crashes or stalls under rapid button presses.
- [ ] Verify pass-through behavior for unassigned buttons.
- [ ] Verify remapped buttons do not leak original events unless configured to pass through.
- [ ] Test sleep/wake and wired USB unplug/replug.
- [ ] Test default profile and per-app profile switching.
- [ ] Test launch-at-login behavior.
- [ ] Verify the app behaves safely if the Razer mouse is absent.

## Phase 9: Stretch Features

- [ ] Macro recording and editing.
- [ ] On-screen profile/DPI overlay.
- [ ] Multiple Razer device support.
- [ ] Built-in HID report capture/export for debugging.
- [ ] Surface calibration or lift-off distance support if protocol documentation is found.
- [ ] On-device profile storage if the hardware supports it and the protocol is confirmed.

## Interview Questions

- [x] Which exact mouse do you want to target first: user reports model label `RC30-007701`.
- [x] Will you use it wired, wireless through the dock/receiver, or both? Wired.
- [x] What Mac CPU architecture should we target first? Initial local target is Apple Silicon / `arm64`.
- [x] What macOS version should we target first? macOS 26+.
- [ ] Do you mainly want button remapping, or do you also want DPI, polling rate, lighting, and battery controls in the first usable version?
- [ ] Which physical buttons matter most, and what should each one do by default?
- [ ] Do you need app-specific profiles, or is one global mapping enough for the first version?
- [ ] Do you want macro recording/playback, or only simple shortcuts and system actions?
- [ ] Are you comfortable granting Input Monitoring and possibly Accessibility permissions to a local unsigned or development-signed utility?
- [ ] Should this be a quiet menu bar utility, a full preferences app, or both?
- [x] Should the first milestone be a probe/event logger, or should we jump straight to a minimal remapper once the mouse is attached? Probe/event logger first.

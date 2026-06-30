# RazerShaper

RazerShaper is a native Swift macOS utility for a wired discontinued Razer gaming mouse labeled `RC30-007701`.

The first milestone is a probe/event logger. Before remapping anything, the project will identify the real wired USB descriptors, HID interfaces, feature-report behavior, and physical button events on macOS 26+.

## Current Scope

- Target OS: macOS 26+
- Initial CPU target: Apple Silicon / `arm64`
- Initial transport: wired USB
- Initial hardware strategy: confirm the attached device before hard-coding Razer Ouroboros assumptions
- First usable path: log and map physical mouse buttons, then build remapping actions

## Repository Layout

- `TASKS.md`: working task breakdown
- `Roadmap.md`: milestone roadmap and exit criteria
- `References/`: archived research, manuals, protocol notes, and sample code

## Permission Expectations

The eventual menu bar app will likely require Input Monitoring for low-level mouse/button listening. Some synthetic action types may also require Accessibility permission. The app should remain unsandboxed unless hardware testing proves IOHID feature reports work reliably with sandboxing enabled.

## Development Status

Planning and reference organization are in progress. The next implementation step is to scaffold a Swift package with:

- `RazerShaperCore`
- `RazerShaperProbe`
- report-builder tests
- HID enumeration
- non-invasive event logging

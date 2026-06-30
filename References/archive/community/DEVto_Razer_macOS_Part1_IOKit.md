# USB HID on macOS: Talking to Devices with IOKit
Source: https://dev.to/paulcontr_/usb-hid-on-macos-talking-to-devices-with-iokit-3g2n
Author: Paul Contreras

## Finding a Device
Use `IOHIDManagerCreate` and `IOHIDManagerSetDeviceMatching` with `kIOHIDVendorIDKey` (0x1532) and `kIOHIDProductIDKey`.

## The Multiple Interfaces Problem
Razer devices enumerate multiple interfaces. Filter for the one with `kIOHIDMaxFeatureReportSizeKey` == 90.

## Opening and Sending
- Do not prepend the report ID to the buffer. Send exactly 90 bytes.
- Wait 200-300ms between `IOHIDDeviceSetReport` and `IOHIDDeviceGetReport`.

## Interpreting Response
Byte [0]:
- 0x00: No response / stale
- 0x01: Busy
- 0x02: Command accepted
- 0x05: Command not understood

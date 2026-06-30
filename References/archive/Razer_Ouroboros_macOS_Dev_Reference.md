# Razer Ouroboros (RZ01-00770) - macOS Driver Development Reference

## 1. Overview
The Razer Ouroboros (Model: RZ01-00770) is an ambidextrous wireless/wired gaming mouse released by Razer. Official driver support ended in 2018, and modern macOS versions are completely unsupported by official software [1]. This reference document aggregates hardware specifications, USB HID protocol details, and reverse-engineered driver implementations to assist in developing custom macOS software using IOKit.

All critical source code, Apple framework headers, and community reverse-engineering notes have been archived locally alongside this document to protect against link rot.

## 2. Hardware & USB Specifications

### 2.1 Device Identifiers
- **USB Vendor ID (VID):** `0x1532` (Razer USA, Ltd)
- **USB Product ID (PID):** `0x0032` (Razer Ouroboros) [2]

### 2.2 USB Interfaces
When plugged in via USB, the Ouroboros typically exposes three interfaces [3]:
- **Interface 0:** Mouse (Boot Protocol 2)
- **Interface 1:** Keyboard (Boot Protocol 1)
- **Interface 2:** Keyboard (Additional HID endpoint)

*Note: Like many gaming mice, extra buttons (side buttons, DPI clutches) often send standard keyboard keystrokes or proprietary HID reports rather than standard mouse button 4/5 events. This is why it registers keyboard interfaces.*

### 2.3 Hardware Capabilities
- **DPI/CPI:** Up to 8200 DPI (4G Dual Sensor System)
- **Polling Rate:** 125Hz, 500Hz, 1000Hz
- **Buttons:** 11 programmable buttons
- **Lighting:** Green LED lighting
- **Power:** 1x AA NiMH rechargeable battery (can be used wired via USB mini-B)

## 3. USB Control Protocol (The "Razer Protocol")

Razer devices communicate configuration changes (DPI, polling rate, lighting, battery status) via USB Feature Reports sent to the specific HID interface that has a `MaxFeatureReportSize` of 90 [4].

### 3.1 Packet Structure
The standard Razer USB report is exactly **90 bytes** (`0x5A`) long [5].

| Byte Index | Name | Description |
|------------|------|-------------|
| 0 | Status | `0x00` (New Cmd), `0x01` (Busy), `0x02` (Success), `0x05` (Not Supported) |
| 1 | Transaction ID | Grouping ID. Crucial for success. Varies per device (`0xFF`, `0x1F`, `0x3F`). |
| 2-3 | Remaining Packets | Big Endian. Usually `0x0000`. |
| 4 | Protocol Type | Always `0x00`. |
| 5 | Data Size | Size of payload in the Arguments array. |
| 6 | Command Class | Type of command (e.g., `0x03` for LED, `0x04` for DPI, `0x07` for Battery). |
| 7 | Command ID | Direction (Bit 7: `0`=Host->Dev, `1`=Dev->Host) + Command ID. |
| 8-87 | Arguments | Up to 80 bytes of payload data. |
| 88 | CRC | XOR checksum of bytes 2 through 87 inclusive. |
| 89 | Reserved | Always `0x00`. |

**Checksum Calculation (Swift):**
```swift
report[88] = report[2...87].reduce(0, ^)
```

### 3.2 Known Command Classes and IDs for Ouroboros

#### Polling Rate (Class: `0x00`)
- **Get Polling Rate:** Class `0x00`, Cmd `0x85`, Size `0x01`.
- **Set Polling Rate:** Class `0x00`, Cmd `0x05`, Size `0x01`.
  - Arguments[0]: `0x01` (1000Hz), `0x02` (500Hz), `0x08` (125Hz).

#### DPI (Class: `0x04`)
- **Get DPI:** Class `0x04`, Cmd `0x85`, Size `0x07`.
- **Set DPI:** Class `0x04`, Cmd `0x05`, Size `0x07`.
  - Arguments[0]: Variable Storage (usually `0x01` for VARSTORE)
  - Arguments[1-2]: X DPI (Big Endian)
  - Arguments[3-4]: Y DPI (Big Endian)

#### Power & Battery (Class: `0x07`)
- **Get Battery Level:** Class `0x07`, Cmd `0x80`, Size `0x02`. Returns a value out of 255.
- **Get Charging Status:** Class `0x07`, Cmd `0x84`, Size `0x02`. Arguments[1] contains `1` if charging, `0` if not.

#### Lighting (Class: `0x03` / `0x0F`)
The Ouroboros has a green LED, mostly controlled via the Scroll Wheel LED ID (`0x01`).
- **Set LED Brightness:** Class `0x03`, Cmd `0x03`, Size `0x03`.
  - Arguments[0]: Variable Storage (`0x01`)
  - Arguments[1]: LED ID (`0x01` for Scroll Wheel)
  - Arguments[2]: Brightness (`0x00` to `0xFF`)
- **Set Static Color:** Class `0x0F`, Cmd `0x02`, Size `0x09`.
  - Arguments[0]: `0x01` (VARSTORE)
  - Arguments[1]: LED ID (`0x01` scroll, `0x04` logo)
  - Arguments[2]: `0x01` (Static Effect)
  - Arguments[6-8]: R, G, B values [6].

## 4. macOS Implementation Strategies

To build custom software for the Ouroboros on macOS, use `IOHIDManager` from the `IOKit` framework.

### 4.1 Sending Feature Reports via IOHIDManager
1. **Match the Device:** Use `IOHIDManagerSetDeviceMatching` with `kIOHIDVendorIDKey` (0x1532) and `kIOHIDProductIDKey` (0x0032).
2. **Find the Control Interface:** Iterate through the returned devices and find the one where `kIOHIDMaxFeatureReportSizeKey` is exactly 90.
3. **Send the Report:** Use `IOHIDDeviceSetReport` with `kIOHIDReportTypeFeature`. Pass exactly 90 bytes. Do not prepend the report ID.
4. **Read the Response:** Wait ~300ms, then call `IOHIDDeviceGetReport` to read the response. Check byte 0 for `0x02` (Success) [4].

### 4.2 Handling Extra Buttons
Because the Ouroboros exposes interfaces as a Keyboard, macOS intercepts these.
- **Mac Mouse Fix Approach:** Use `CGEventTapCreate(kCGHIDEventTap, ...)` to intercept all low-level mouse and keyboard events globally. Use `CGEventGetSendingDevice()` to map the event back to the specific `IOHIDDeviceRef` of the Ouroboros. If it matches, consume the event and inject a new virtual event (like Mission Control or a keyboard shortcut) using `CGEventPost` [7].

## 5. Local Archive Contents

The following critical resources have been downloaded and archived locally in the `archive/` directory to protect against link rot:

- **`openrazer/`**: The complete C source files and Python daemon scripts from the OpenRazer Linux project detailing the exact byte protocols for Razer mice.
- **`librazermacos/`**: The C source files for the community macOS IOKit port of OpenRazer.
- **`apple_docs/`**: Apple's official `IOHIDManager` and `IOUSBLib` programming guides, plus the actual C headers from the macOS SDK (`IOHIDLib.h`, `CGEvent.h`, etc.).
- **`usb_specs/`**: The official USB-IF HID 1.11 Specification and HID Usage Tables 1.5 PDFs.
- **`community/`**: 
  - OpenRazer Reverse Engineering Wiki pages.
  - Paul Contreras's DEV.to article series on writing a Razer mouse controller in Swift/IOKit for macOS.
  - The `RazerDevice.cpp` implementation from `razer-battery-status-macos`.
  - The `ButtonInputReceiver.m` source from Mac Mouse Fix showing how to intercept extra mouse buttons using `CGEventTap` and `IOHIDManager`.

---
### References
[1] Razer Support. "Mac OS support in Razer Synapse." mysupport.razer.com.
[2] OpenRazer Contributors. "razermouse_driver.h". GitHub.
[3] Unix & Linux Stack Exchange. "Razer Ouroboros mouse not working". unix.stackexchange.com.
[4] Contreras, Paul. "USB HID on macOS: Talking to Devices with IOKit". DEV.to.
[5] Contreras, Paul. "The Packet Format: 90 Bytes and One Cursed Byte". DEV.to.
[6] Contreras, Paul. "DPI, Color, and Why 'OK' Doesn't Mean It Worked". DEV.to.
[7] Nuebling, Noah. "Mac Mouse Fix - ButtonInputReceiver.m". GitHub.

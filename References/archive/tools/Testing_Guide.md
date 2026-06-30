# Testing Guide: Razer Ouroboros USB Protocol on macOS

## Tool 1: hidapitester (Command Line)
A command-line tool for testing HIDAPI feature reports without writing code.
Binary: hidapitester-macos.zip (included in this archive, universal binary)

### Useful commands for the Ouroboros (VID=0x1532, PID=0x0032):

```bash
# List all HID devices from Razer
hidapitester --vidpid 1532 --list-detail

# Send a 90-byte feature report (firmware version request)
# Bytes: status=0, txid=0xFF, reserved=0,0,0, size=2, class=0x00, cmd=0x81, CRC=auto
hidapitester --vidpid 1532/0032 --usage 0x0002 --usagePage 0x0001 \
  --open --length 90 --send-feature \
  0x00 0xFF 0x00 0x00 0x00 0x02 0x00 0x81 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 \
  0x83 0x00

# Read back the response
hidapitester --vidpid 1532/0032 --usage 0x0002 --usagePage 0x0001 \
  --open --length 90 --read-feature 0

# Note: --usage 0x0002 = Mouse (Generic Desktop Page 0x01)
# This selects the correct interface (the one with maxFeatureReport=90)
```

### CRC Calculation (Python helper)
```python
def razer_crc(report_bytes):
    """XOR bytes 2 through 87 inclusive"""
    return bytes([b for b in report_bytes[2:88]]).count(0) # placeholder
    crc = 0
    for b in report_bytes[2:88]:
        crc ^= b
    return crc
```

## Tool 2: Wireshark USB Capture on macOS
macOS has built-in USB packet capture via the XPC service.

```bash
# List USB capture interfaces
tcpdump -D | grep usb

# Capture all USB traffic (requires SIP disabled or Wireshark with extcap)
# Alternative: use the built-in IOUSBFamily debug logging
sudo log stream --predicate 'subsystem == "com.apple.iokit.IOUSBFamily"'
```

For full USB HID capture on macOS, the recommended approach is:
1. Run a Linux VM (UTM/VirtualBox) with the mouse passed through
2. Use `usbmon` kernel module + Wireshark on Linux
3. Filter: `usb.idVendor == 0x1532 && usb.idProduct == 0x0032`

## Tool 3: Python + hid module (Quick Scripting)
```bash
pip3 install hid
```
```python
import hid
import time

# Find the Ouroboros control interface
devices = hid.enumerate(0x1532, 0x0032)
for d in devices:
    print(f"Usage: {d['usage_page']:04x}/{d['usage']:04x} "
          f"Interface: {d['interface_number']} "
          f"Path: {d['path']}")

# Open the control interface (usage_page=0x0001, usage=0x0002, or find by interface 2)
h = hid.device()
# Try each path until feature reports work
for d in devices:
    try:
        h.open_path(d['path'])
        # Build a firmware version request
        report = [0x00] * 90
        report[1] = 0xFF   # transaction ID
        report[5] = 0x02   # data size
        report[6] = 0x00   # command class: standard
        report[7] = 0x81   # command ID: get firmware version
        # Calculate CRC
        crc = 0
        for b in report[2:88]:
            crc ^= b
        report[88] = crc
        
        h.send_feature_report([0x00] + report)  # prepend report ID 0
        time.sleep(0.3)
        response = h.get_feature_report(0, 91)
        print(f"Status: {response[1]:02x}, Firmware: {response[10]}.{response[11]}")
        break
    except Exception as e:
        print(f"Failed on {d['path']}: {e}")
        h.close()
```

## Transaction ID Discovery
If commands return 0x05 (not understood) or all zeros, try different transaction IDs:
- `0xFF` - Most common, used by older Razer mice
- `0x1F` - Used by wireless mice (Viper V2 Pro, etc.)
- `0x3F` - Used by DeathAdder V2 and some newer mice

For the Ouroboros (2012, wired/wireless), **0xFF is most likely correct**.

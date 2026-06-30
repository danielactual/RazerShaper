# OpenRazer Wiki: Using the Mouse Driver
Source: https://github.com/openrazer/openrazer/wiki/Using-the-mouse-driver
Last edited: Apr 23, 2020

## Device Mode
- `0x00, 0x00`: Normal Mode
- `0x03, 0x00`: Driver Mode (DPI buttons send events to software, not hardware)

## Key sysfs attributes (Linux, applicable to understanding protocol)
- `charge_level`: Battery 0-255 (divide by 255 * 100 for %)
- `charge_status`: 1=charging, 0=not
- `device_idle_time`: Seconds before sleep (60-900)
- `charge_low_threshold`: Battery % threshold (0-255 scale)
- `dpi`: 2 or 4 bytes, two unsigned shorts big-endian (X DPI, Y DPI)
- `poll_rate`: 125, 500, or 1000
- `scroll_led_brightness`: 0-255

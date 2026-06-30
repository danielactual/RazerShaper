# DPI, Color, and Why "OK" Doesn't Mean It Worked
Source: https://dev.to/paulcontr_/dpi-color-and-why-ok-doesnt-mean-it-worked-2nc
Author: Paul Contreras

## DPI
Set: Class 0x04, ID 0x05, Size 0x07.
Args: [0]=stage, [1-2]=X high/low, [3-4]=Y high/low.
Get: Class 0x04, ID 0x85.

## Lighting
Static color: Class 0x0F, ID 0x02. Size 0x09.
args[0] = 0x01 (varstore)
args[1] = led_id (0x01 scroll, 0x04 logo)
args[2] = 0x01 (static)
args[6,7,8] = R, G, B.

# OpenRazer Wiki: Reverse Engineering USB Protocol
Source: https://github.com/openrazer/openrazer/wiki/Reverse-Engineering-USB-Protocol
Last edited: Aug 30, 2025

## Prerequisites
- Device to reverse, extra mouse/keyboard, hypervisor (VirtualBox or KVM/QEMU), Windows VM, Wireshark on host.
- Save captures as `.pcapng`.

## Phase 2 - Setup (Linux)
```bash
sudo gpasswd -a $USER wireshark
sudo setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip CAP_DAC_OVERRIDE+eip' /usr/bin/dumpcap
sudo modprobe usbmon
sudo setfacl -m u:$USER:r /dev/usbmon*
```
Filter in Wireshark: `usb.bus_id == 5 && usb.device_address == 3`

## Phase 4 - Decoding the Protocol
The Razer protocol fields:
- Start Byte: `0x00` (PC→Device), `0x02` (Device→PC)
- ID Byte: normally `0xFF`
- Reserved: 3 bytes of `0x000000`
- Num Params: number of bytes after command byte
- Reserved: 1 byte
- Command Byte: action type (e.g., `0x0A` = change effect)
- Sub Command Byte: part of parameters
- Parameters: variable length

Example decoded packets:
```
Start | ID | Reserved | Num Params | Reserved | Command | Sub Cmd | Params | Effect
00      FF    000000       04           03        0A         06     00FF00 | Static (Green RGB)
00      FF    000000       02           03        0A         01     02     | Wave (Direction Down)
```

# The Packet Format: 90 Bytes and One Cursed Byte
Source: https://dev.to/paulcontr_/the-packet-format-90-bytes-and-one-cursed-byte-55pe
Author: Paul Contreras

## Layout
[0] status
[1] transaction_id (Crucial! Varies per device. Try 0xFF, 0x1F, 0x3F)
[2-3] remaining_packets
[4] protocol_type
[5] data_size
[6] command_class
[7] command_id
[8-87] arguments
[88] CRC (XOR of bytes 2 through 87)
[89] reserved

## CRC
`report[88] = report[2...87].reduce(0, ^)`

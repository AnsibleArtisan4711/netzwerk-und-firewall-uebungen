#!/usr/bin/env python3
"""Sendet einen von Hand gebauten Ethernet-Rahmen mit 802.1Q-Tag (VLAN-ID) auf eine Schnittstelle (nur Labor, benötigt root).
Aufruf: tagframe.py SCHNITTSTELLE VLAN-ID   – der Rahmen enthält eine ARP-Anfrage; tcpdump -e zeigt das Etikett „vlan N“."""
import socket, struct, sys
ifname, vid = sys.argv[1], int(sys.argv[2])
dst = bytes.fromhex("ffffffffffff"); src = bytes.fromhex("020000000001")
tag = struct.pack("!HH", 0x8100, vid & 0x0FFF)                       # TPID 0x8100, PCP 0, DEI 0, VID
arp = struct.pack("!HHBBH6s4s6s4s", 1, 0x0800, 6, 4, 1, src, bytes([10, 8, 10, 2]), bytes(6), bytes([10, 8, 10, 1]))
frame = dst + src + tag + struct.pack("!H", 0x0806) + arp
s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW); s.bind((ifname, 0)); s.send(frame); print(f"gesendet: {len(frame)} Bytes mit VLAN-ID {vid}")

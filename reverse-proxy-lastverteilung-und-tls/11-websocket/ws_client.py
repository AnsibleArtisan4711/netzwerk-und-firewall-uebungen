#!/usr/bin/env python3
"""Minimaler WebSocket-Client (nur Standardbibliothek): Handshake, Textnachricht, Antwort, optional Pause und zweite Nachricht.
Aufruf: ws_client.py HOST PORT PFAD [PAUSE_SEKUNDEN]"""
import base64, os, socket, sys, time

def frame(text):
    daten = text.encode(); maske = os.urandom(4)
    return bytes([0x81, 0x80 | len(daten)]) + maske + bytes(b ^ maske[i % 4] for i, b in enumerate(daten))

def lesen(s):
    kopf = s.recv(2)
    if len(kopf) < 2: raise EOFError('Verbindung geschlossen')
    ln = kopf[1] & 0x7f
    data = b''
    while len(data) < ln:
        teil = s.recv(ln - len(data))
        if not teil: raise EOFError('Verbindung geschlossen')
        data += teil
    return data.decode()

host, port, pfad = sys.argv[1], int(sys.argv[2]), sys.argv[3]
pause = float(sys.argv[4]) if len(sys.argv) > 4 else 0
s = socket.create_connection((host, port), timeout=15)
schluessel = base64.b64encode(os.urandom(16)).decode()
s.sendall(('GET %s HTTP/1.1\r\nHost: shop.lab.test\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n'
           'Sec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n' % (pfad, schluessel)).encode())
antwort = b''
while b'\r\n\r\n' not in antwort:
    teil = s.recv(4096)
    if not teil: break
    antwort += teil
statuszeile = antwort.split(b'\r\n')[0].decode()
print('Handshake:', statuszeile)
if ' 101 ' not in statuszeile:
    sys.exit(1)
s.sendall(frame('hallo')); print('Antwort 1:', lesen(s))
if pause:
    time.sleep(pause)
    try:
        s.sendall(frame('nach der Pause')); print('Antwort 2:', lesen(s))
    except (EOFError, OSError) as e:
        print('Antwort 2: Verbindung vom Proxy beendet (%s)' % type(e).__name__)
        sys.exit(2)

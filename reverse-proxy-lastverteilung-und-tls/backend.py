#!/usr/bin/env python3
"""Test-Backend für die Übungen: meldet Namen, Anfrage-Header und Zähler; Pfade /health, /slow, /cache, /upload, /ws."""
import sys, os, time, base64, hashlib, threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

NAME = sys.argv[1] if len(sys.argv) > 1 else 'backend'
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
ZAEHLER = {'n': 0}
SPERRE = threading.Lock()
GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'

class H(BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'
    server_version = 'labbackend'

    def log_message(self, *a): pass

    def senden(self, code, text, extra=None):
        b = text.encode()
        self.send_response(code)
        self.send_header('Content-Type', 'text/plain; charset=utf-8')
        self.send_header('Content-Length', str(len(b)))
        self.send_header('X-Backend', NAME)
        for k, v in (extra or {}).items(): self.send_header(k, v)
        self.end_headers(); self.wfile.write(b)

    def do_GET(self):
        pfad = self.path.split('?')[0]
        with SPERRE:
            ZAEHLER['n'] += 1; n = ZAEHLER['n']
        if pfad == '/health':
            if os.path.exists('/tmp/p11-%s.down' % NAME): return self.senden(503, 'krank\n')
            return self.senden(200, 'ok\n')
        if pfad == '/slow':
            s = float(self.path.split('s=')[1]) if 's=' in self.path else 3
            time.sleep(s); return self.senden(200, 'langsam fertig nach %s s\n' % s)
        if pfad == '/cache':
            return self.senden(200, 'antwort-nr=%d von %s\n' % (n, NAME), {'Cache-Control': 'public, max-age=10'})
        if pfad == '/ws':
            return self.websocket()
        h = self.headers
        text = 'backend=%s\nzaehler=%d\npfad=%s\nclient=%s\nhost=%s\nx-forwarded-for=%s\nx-forwarded-proto=%s\nx-real-ip=%s\n' % (
            NAME, n, self.path, self.client_address[0], h.get('Host', '-'), h.get('X-Forwarded-For', '-'), h.get('X-Forwarded-Proto', '-'), h.get('X-Real-IP', '-'))
        self.senden(200, text)

    def do_POST(self):
        n = int(self.headers.get('Content-Length', 0)); self.rfile.read(n)
        self.senden(200, 'empfangen=%d Bytes von %s\n' % (n, NAME))

    def websocket(self):
        if self.headers.get('Upgrade', '').lower() != 'websocket':
            return self.senden(426, 'Upgrade erforderlich\n')
        key = self.headers['Sec-WebSocket-Key']
        acc = base64.b64encode(hashlib.sha1((key + GUID).encode()).digest()).decode()
        self.send_response(101)
        self.send_header('Upgrade', 'websocket'); self.send_header('Connection', 'Upgrade')
        self.send_header('Sec-WebSocket-Accept', acc); self.send_header('X-Backend', NAME)
        self.end_headers(); self.wfile.flush()
        try:
            while True:
                kopf = self.rfile.read(2)
                if len(kopf) < 2: break
                op = kopf[0] & 0x0f; ln = kopf[1] & 0x7f
                if ln == 126: ln = int.from_bytes(self.rfile.read(2), 'big')
                maske = self.rfile.read(4) if kopf[1] & 0x80 else b'\0\0\0\0'
                daten = bytes(b ^ maske[i % 4] for i, b in enumerate(self.rfile.read(ln)))
                if op == 8: self.wfile.write(b'\x88\x00'); break
                antwort = ('%s: ' % NAME).encode() + daten
                self.wfile.write(bytes([0x81, len(antwort)]) + antwort); self.wfile.flush()
        except Exception:
            pass
        self.close_connection = True

if __name__ == '__main__':
    ThreadingHTTPServer(('0.0.0.0', PORT), H).serve_forever()

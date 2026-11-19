#!/usr/bin/env python3
"""Minimaler Test-Webserver: antwortet mit Name und Adresse des Clients (wie der Server sie sieht). Aufruf: echo_server.py NAME PORT"""
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
name, port = sys.argv[1], int(sys.argv[2])
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        body = f"server={name} client={self.client_address[0]} pfad={self.path}\n".encode()
        self.send_response(200); self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)
    def log_message(self, *a): pass
HTTPServer(("0.0.0.0", port), H).serve_forever()

#!/usr/bin/env bash
# Testkatalog für die Musterlösung des Abschlussprojekts (abschluss_loesung.nft): jede Anforderung ein Test mit erwartetem Ergebnis.
. "$(dirname "$0")/../lab.sh"
cd "$(dirname "$0")"
lab_up
on srv pkill -f "http.server 8080"; sleep 0.3
cat > /tmp/p09-www/whoami.py <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_GET(self):
        b = ("Quelle: %s\n" % self.client_address[0]).encode()
        self.send_response(200); self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def log_message(self, *a): pass
HTTPServer(("0.0.0.0", 8080), H).serve_forever()
PY
( setsid ip netns exec $NS_SRV python3 /tmp/p09-www/whoami.py >/dev/null 2>&1 < /dev/null & ); sleep 0.6
on fw nft -c -f abschluss_loesung.nft && echo "Prüfung ok" && on fw nft -f abschluss_loesung.nft
ok=0; fail=0
pruefe() {   # pruefe "Beschreibung" erwartet(ja|nein) Befehl...
  local d=$1 erw=$2; shift 2
  if "$@" >/dev/null 2>&1; then ist=ja; else ist=nein; fi
  if [ "$ist" = "$erw" ]; then ok=$((ok+1)); printf 'OK    %-55s erwartet=%s\n' "$d" "$erw"; else fail=$((fail+1)); printf 'FEHLER %-54s erwartet=%s ist=%s\n' "$d" "$erw" "$ist"; fi
}
step "Testkatalog"
pruefe "LAN -> Server Port 80" ja on cl curl -s -m 2 http://10.0.2.2:80/
pruefe "LAN -> Server Port 22 (nicht erlaubt)" nein on cl python3 -c "import socket;s=socket.socket();s.settimeout(2);s.connect(('10.0.2.2',22))"
pruefe "Server -> LAN Ping" nein on srv ping -c1 -W1 10.0.1.2
pruefe "Ping LAN -> Firewall" ja on cl ping -c1 -W1 10.0.1.1
pruefe "Ping Server -> Firewall" nein on srv ping -c1 -W1 10.0.2.1
pruefe "Weiterleitung 10.0.1.1:8000 -> Server:8080" ja on cl curl -s -m 2 http://10.0.1.1:8000/
echo "Quelle laut Server: $(on cl curl -s -m 2 http://10.0.2.2:8080/)  (Masquerade erwartet 10.0.2.1)"
step "Begrenzung: 8080 direkt, bereits 2 Verbindungen verbraucht (80 zählt nicht, 8000 und die Abfrage oben)"
for i in 1 2 3 4 5 6; do if on cl curl -s -m 2 -o /dev/null http://10.0.2.2:8080/; then echo "Versuch $i: OK"; else echo "Versuch $i: BLOCKIERT"; fi; done
step "Zähler"
on fw nft list chain inet fw lan_zu_srv | grep -E "counter|limit"
on fw nft list chain inet fw forward | grep -E "counter"
echo "Ergebnis: $ok bestanden, $fail fehlgeschlagen"
lab_down

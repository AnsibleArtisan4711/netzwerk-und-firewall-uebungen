#!/usr/bin/env bash
# Source-NAT (masquerade), Port-Weiterleitung (DNAT) und Redirect; der Server protokolliert die Quelladresse.
. "$(dirname "$0")/../lab.sh"
lab_up
# Server-Dienst, der die Quelladresse zurückgibt
on srv pkill -f "http.server 8080" ; sleep 0.3
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
step "1. Ohne NAT: der Server sieht die echte Client-Adresse"
cmd on cl curl -s -m 2 http://10.0.2.2:8080/
step "2. Source-NAT: masquerade für alles, was über v-fw2 hinausgeht"
on fw nft -f - <<'RS'
table ip nat {
  chain post { type nat hook postrouting priority srcnat; policy accept;
    oifname "v-fw2" counter masquerade
  }
}
RS
cmd on cl curl -s -m 2 http://10.0.2.2:8080/
cmd on fw conntrack -L -p tcp
step "3. Port-Weiterleitung: Aufrufe an 10.0.1.1:8000 landen beim Server 10.0.2.2:8080 (DNAT in prerouting)"
on fw nft add chain ip nat pre '{ type nat hook prerouting priority dstnat; policy accept; }'
on fw nft add rule ip nat pre iifname "v-fw1" tcp dport 8000 counter dnat to 10.0.2.2:8080
cmd on cl curl -s -m 2 http://10.0.1.1:8000/
step "4. Ohne passende forward-Regel scheitert das Weiterleiten trotz DNAT, sobald die Firewall verwirft"
on fw nft -f - <<'RS'
table inet filter {
  chain forward { type filter hook forward priority 0; policy drop;
    ct state established,related accept
    ct status dnat accept comment "alle per DNAT umgeleiteten Verbindungen"
  }
}
RS
cmd on cl curl -s -m 2 http://10.0.1.1:8000/
cmd on cl curl -s -m 2 -o /dev/null -w "direkt zu 10.0.2.2:8080 -> HTTP %{http_code}\n" http://10.0.2.2:8080/ || echo "direkt zu 10.0.2.2:8080 -> verworfen (nicht per DNAT)"
step "5. Redirect: Aufrufe an Port 9000 der Firewall selbst auf den lokalen Port 3128 umleiten"
( cd /tmp && setsid ip netns exec $NS_FW python3 -m http.server 3128 --bind 0.0.0.0 >/dev/null 2>&1 < /dev/null & ); sleep 0.6
on fw nft add rule ip nat pre iifname "v-fw1" tcp dport 9000 redirect to :3128
cmd on cl curl -s -m 2 -o /dev/null -w "HTTP-Status von 10.0.1.1:9000: %{http_code}\n" http://10.0.1.1:9000/
step "6. NAT-Tabelle mit Zählern"
on fw nft list table ip nat
lab_down

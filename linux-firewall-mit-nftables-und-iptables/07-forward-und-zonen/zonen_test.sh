#!/usr/bin/env bash
# Prüft die Zonenregeln in beide Richtungen und liest die Zähler pro Kette.
. "$(dirname "$0")/../lab.sh"
cd "$(dirname "$0")"
lab_up
on fw nft -f zonen.nft
step "1. LAN -> SERVER"
ping_test cl 10.0.2.2
http_get cl 10.0.2.2 80
http_get cl 10.0.2.2 8080
step "2. Nicht erlaubter Port (22 über eine Test-Verbindung)"
if on cl python3 -c "import socket;s=socket.socket();s.settimeout(2);s.connect(('10.0.2.2',22))" 2>/dev/null; then echo "22: verbunden"; else echo "22: keine Verbindung (verworfen oder kein Dienst)"; fi
step "3. SERVER -> LAN (muss verworfen werden)"
ping_test srv 10.0.1.2
if on srv curl -s -m 2 -o /dev/null http://10.0.1.2/; then echo "srv->lan http: OK"; else echo "srv->lan http: BLOCKIERT"; fi
step "4. Firewall selbst: Ping aus LAN erlaubt, Ping aus SERVER-Zone nicht"
ping_test cl 10.0.1.1
ping_test srv 10.0.2.1
step "5. Zähler der Ketten"
on fw nft list chain inet fw lan_zu_srv
on fw nft list chain inet fw srv_zu_lan
on fw nft list chain inet fw forward | grep counter
lab_down

#!/usr/bin/env bash
# WebSocket hinter nginx und HAProxy: fehlender Upgrade, richtige Header, Leerlaufzeit (read_timeout bzw. timeout tunnel).
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
WS="on cl python3 $D/ws_client.py"
nginx_start "$D/ws.conf"
step "1. nginx ohne Upgrade-Header: das Backend sieht keinen Upgrade (426)"
$WS 10.1.1.1 80 /ohne
step "2. nginx mit Upgrade-Headern, Leerlaufzeit 3 s: Verbindung steht, nach 5 s Pause kappt der Proxy sie"
$WS 10.1.1.1 80 /kurz 5
step "3. nginx mit Leerlaufzeit 60 s: dieselbe Pause von 5 s ist unkritisch"
$WS 10.1.1.1 80 /lang 5
nginx_stop
step "4. HAProxy (kein Zusatz außer timeout tunnel nötig): Leerlaufzeit 3 s kappt, 60 s hält"
haproxy_start "$D/ws.cfg"
echo "- timeout tunnel 3s:";  $WS 10.1.1.1 8000 /kurz 5
echo "- timeout tunnel 60s:"; $WS 10.1.1.1 8000 /lang 5
lab_down

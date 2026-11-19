#!/usr/bin/env bash
# HAProxy als Reverse Proxy: Konfigurationsprüfung, Weiterleitung nach Host und Pfad, TCP-Modus, Admin-Socket.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
step "1. Fehlerhafte Konfiguration: haproxy -c nennt Zeile und Ursache"
echo "$ haproxy -c -f haproxy_defekt.cfg"; haproxy_pruefen "$D/haproxy_defekt.cfg"
step "2. Richtige Konfiguration prüfen (haproxy -c) und starten"
haproxy_start "$D/haproxy.cfg"
step "3. Weiterleitung nach Host: shop.lab.test -> b1, api.lab.test -> b2"
echo "shop.lab.test -> $(on cl curl -s -m 3 http://shop.lab.test/ | sed -n 's/^backend=//p')"
echo "api.lab.test  -> $(on cl curl -s -m 3 http://api.lab.test/  | sed -n 's/^backend=//p')"
step "4. Weiterleitung nach Pfad (/api/ wird entfernt) und Header X-Forwarded-For"
on cl curl -s -m 3 http://shop.lab.test/api/info | grep -E "backend|pfad|x-forwarded"
step "5. TCP-Modus (Port 9000): der Proxy reicht Bytes durch und versteht kein HTTP, es gibt keine Header-Ergänzung"
on cl curl -s -m 3 http://10.1.1.1:9000/ | grep -E "backend|client|x-forwarded"
step "6. Laufzeit-Schnittstelle (Admin-Socket): Version und Zustand der Server"
haproxy_cli "show info" | grep -E "^(Name|Version|Nbthread):"
haproxy_tabelle
lab_down

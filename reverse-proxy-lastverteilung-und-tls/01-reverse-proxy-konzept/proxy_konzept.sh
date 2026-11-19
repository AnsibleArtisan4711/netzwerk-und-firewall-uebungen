#!/usr/bin/env bash
# Reverse-Proxy-Konzept: ohne Proxy, mit minimalem nginx-Proxy; was Client, Proxy und Backend jeweils sehen.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
step "1. Das Backend ist vom Client aus nicht erreichbar (nur der Proxy ist an beide Netze angeschlossen, Routing ist aus)"
cmd on cl curl -s -m 2 -o /dev/null -w "HTTP %{http_code}\n" http://10.1.2.11:8080/
step "2. nginx als minimaler Reverse Proxy starten (nginx -t prüft die Konfiguration)"
nginx_start "$D/minimal.conf"
step "3. Der Client spricht nur mit dem Proxy; das Backend meldet, wer bei ihm angefragt hat"
cmd on cl curl -s -m 3 http://10.1.1.1/
step "4. Während einer langsamen Anfrage: zwei getrennte TCP-Verbindungen (Client zum Proxy, Proxy zum Backend)"
( on cl curl -s -m 6 "http://10.1.1.1/slow?s=2" > /dev/null & ); sleep 0.8
cmd on px ss -tn state established
step "5. Zugriffsprotokoll des Proxys (letzte Zeilen, Zeitstempel ersetzt)"
tail -2 /tmp/p11-nginx/access.log | sed -E 's/\[[^]]*\]/[Zeit]/'
lab_down

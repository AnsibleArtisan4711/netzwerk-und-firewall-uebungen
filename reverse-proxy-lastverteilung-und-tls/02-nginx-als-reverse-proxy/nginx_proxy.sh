#!/usr/bin/env bash
# nginx als Reverse Proxy: Host-Header, X-Forwarded-*, Pfadumschreibung, virtuelle Server und eine fehlerhafte Konfiguration.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
step "1. Fehlerhafte Konfiguration wird von nginx -t abgelehnt (Datei, Zeile, Ursache)"
{ echo "events { worker_connections 8; }"; echo "http { include $D/proxy_defekt.conf; }"; } > /tmp/p11-defekt.conf
on px nginx -t -c /tmp/p11-defekt.conf 2>&1 | sed -E 's/^[0-9\/]+ [0-9:]+ //; s#/tmp/p11-defekt.conf#nginx.conf#; s#in [^ ]*proxy_defekt.conf#in proxy_defekt.conf#; s/\[emerg\] [0-9#]+:/[emerg]/'
step "2. Korrigierte Konfiguration starten (nginx_start prüft zuerst mit nginx -t)"
nginx_start "$D/proxy.conf"
step "3. Ohne eigene Header (location /roh): das Backend sieht den Host des Upstreams, die Adresse des Proxys und keine Client-Angaben"
cmd on cl curl -s -m 3 -H "Host: shop.lab.test" http://10.1.1.1/roh
step "4. Mit Headern (location /): Host, echte Client-Adresse und Protokoll kommen an"
cmd on cl curl -s -m 3 http://shop.lab.test/
step "5. Pfad mit und ohne Schrägstrich in proxy_pass"
echo "- /api/info  (proxy_pass mit /):";    on cl curl -s -m 3 http://shop.lab.test/api/info | grep -E "backend|pfad"
echo "- /voll/info (proxy_pass ohne /):";   on cl curl -s -m 3 http://shop.lab.test/voll/info | grep -E "backend|pfad"
step "6. Virtueller Server: gleiche Adresse, anderer Name führt zu einem anderen Backend"
echo "shop.lab.test -> $(on cl curl -s -m 3 http://shop.lab.test/ | sed -n 's/^backend=//p')"
echo "api.lab.test  -> $(on cl curl -s -m 3 http://api.lab.test/  | sed -n 's/^backend=//p')"
step "7. Zeitlimit: proxy_read_timeout 5s, das Backend braucht 7 s (Fehler 504 Gateway Time-out)"
cmd on cl curl -s -m 12 -o /dev/null -w "HTTP %{http_code} nach %{time_total} s\n" "http://shop.lab.test/slow?s=7"
grep -c "upstream timed out" /tmp/p11-nginx/error.log | sed 's/^/Zeilen "upstream timed out" im Fehlerprotokoll: /'
lab_down

#!/usr/bin/env bash
# Header am Proxy: gefälschtes X-Forwarded-For, Sicherheits-Header, versteckte Server-Angaben; echte Client-Adresse über das PROXY-Protokoll.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
nginx_start "$D/header.conf"
step "1. Naiver Proxy (Port 80): Der Client schickt selbst ein X-Forwarded-For; es wird nur verlängert, die Fälschung bleibt vorn"
cmd on cl curl -s -m 3 -H "X-Forwarded-For: 6.6.6.6" http://shop.lab.test/ | grep x-forwarded-for
step "2. Gehärteter Proxy (Port 81): die Kette wird mit der echten Adresse überschrieben"
cmd on cl curl -s -m 3 -H "X-Forwarded-For: 6.6.6.6" http://shop.lab.test:81/ | grep x-forwarded-for
step "3. Antwort-Header: Server-Version, Sicherheits-Header, Backend-Kennung"
echo "- Port 80 (naiv):";    on cl curl -s -m 3 -D - -o /dev/null http://shop.lab.test/   | grep -iE "^server:|^x-backend|^x-content|^x-frame|^content-security|^referrer" | tr -d '\r'
echo "- Port 81 (gehärtet):"; on cl curl -s -m 3 -D - -o /dev/null http://shop.lab.test:81/ | grep -iE "^server:|^x-backend|^x-content|^x-frame|^content-security|^referrer" | tr -d '\r'
step "4. PROXY-Protokoll: HAProxy (Port 8000) gibt die Client-Adresse an nginx weiter; ohne send-proxy (Port 8001) scheitert die Verbindung"
haproxy_start "$D/haproxy_pp.cfg"
echo "- mit send-proxy:"; on cl curl -s -m 3 http://10.1.1.1:8000/ | grep -E "client|x-real-ip"
echo "- ohne send-proxy:"; on cl curl -s -m 3 -o /dev/null -w "HTTP %{http_code}\n" http://10.1.1.1:8001/
grep -m1 "broken header" /tmp/p11-nginx/error.log | sed -E 's/^[0-9\/]+ [0-9:]+ //; s/\[error\] [0-9#]+: //; s/\*[0-9]+ //; s/, client:.*//'
echo "(client= zeigt die Adresse des Proxys, x-real-ip die echte Adresse des Clients)"
lab_down

#!/usr/bin/env bash
# Fehlersuche und Schutz am Proxy: 502, 504, 413, 429, 444 bei nginx; 503 bei HAProxy; was Zugriffs- und Fehlerprotokoll verraten.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
nginx_start "$D/fehler.conf"
U=http://shop.lab.test
code() { on cl curl -s -m 8 -o /dev/null -w "%{http_code}" "$@"; }
step "1. Tabelle der Fälle: Aufruf, HTTP-Status, Bedeutung"
printf '%-44s %-7s %s\n' "/ok" "$(code $U/ok)" "alles in Ordnung"
printf '%-44s %-7s %s\n' "/abgelehnt (Port ohne Dienst)" "$(code $U/abgelehnt)" "Bad Gateway: Verbindung wurde abgewiesen"
printf '%-44s %-7s %s\n' "/tot (Adresse ohne Host)" "$(code $U/tot)" "Gateway Time-out: Verbindungsaufbau ohne Antwort"
printf '%-44s %-7s %s\n' "/langsam (read timeout 2 s, Backend 3 s)" "$(code $U/langsam?s=3)" "Gateway Time-out: Antwort zu spät"
printf '%-44s %-7s %s\n' "/upload mit 5000 Bytes (Grenze 1k)" "$(on cl curl -s -m 5 -o /dev/null -w '%{http_code}' --data-binary @<(head -c 5000 /dev/zero | tr '\0' x) $U/upload)" "Request Entity Too Large"
printf '%-44s %-7s %s\n' "unbekannter Host-Name" "$(on cl curl -s -m 5 -o /dev/null -w '%{http_code}' -H 'Host: unbekannt.example' http://10.1.1.1/ || true)" "000 = Verbindung ohne Antwort beendet (nginx 444)"
step "2. Begrenzung: 10 schnelle Anfragen auf /limit (2 pro Sekunde, Burst 2): 3 gehen durch, der Rest bekommt 429"
for i in $(seq 1 10); do code $U/limit; echo -n " "; done; echo
step "3. Was das Fehlerprotokoll dazu sagt (gekürzt, ohne Zeit und Prozessnummern)"
sed -E 's/^[0-9\/]+ [0-9:]+ //; s/\[([a-z]+)\] [0-9#]+: \*[0-9]+ /[\1] /; s/, client: .*(upstream: "[^"]*").*/, \1/; s/, client: .*//; s/, request: .*//' /tmp/p11-nginx/error.log | grep -E "refused|timed out|too large|limiting" | sed -E 's/\(([0-9]+): [^)]*\)/(\1)/; s/excess: [0-9.]+/excess: N/' | sort | uniq -c | sed 's/^ *//' | cut -c1-150
step "4. Server-Header ist ohne Version (server_tokens off); der Zugriff auf /ok im Zugriffsprotokoll"
on cl curl -s -m 3 -D - -o /dev/null $U/ok | grep -i "^server:" | tr -d '\r'
grep '"GET /ok' /tmp/p11-nginx/access.log | tail -1 | sed -E 's/\[[^]]*\]/[Zeit]/'
nginx_stop
step "5. HAProxy: sind alle Server als DOWN markiert, liefert der Proxy selbst 503 (nicht das Backend)"
haproxy_start "$D/haproxy_503.cfg"; sleep 2.5
echo "- beide gesund: HTTP $(on cl curl -s -m 3 -o /dev/null -w '%{http_code}' http://10.1.1.1:8000/)"
touch /tmp/p11-b1.down /tmp/p11-b2.down; sleep 3.5
echo "- beide krank:  HTTP $(on cl curl -s -m 3 -o /dev/null -w '%{http_code}' http://10.1.1.1:8000/)"
on cl curl -s -m 3 http://10.1.1.1:8000/ | head -3 | sed 's/^/   /'
haproxy_tabelle | grep -E "^alle +b[12]"
lab_down

#!/usr/bin/env bash
# Lastverteilung und Health Checks mit HAProxy: Verfahren, Gewichte, Sitzungsbindung per Cookie, aktive Prüfung, Backup-Server, Laufzeit-Schnittstelle.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
haproxy_start "$D/lb.cfg"; sleep 2.5      # die ersten Prüfungen abwarten
U=http://shop.lab.test
cli() { echo "$ echo \"$1\" | socat stdio /tmp/p11-haproxy.sock"; haproxy_cli "$1" | sed "/^$/d"; }
step "1. Round Robin (20 Anfragen) und gewichtet 3:1 (20 Anfragen)"
verteilung 20 $U/rr/;      echo "- gewichtet:"; verteilung 20 $U/gewicht/
step "2. Sitzungsbindung per Cookie: ohne Cookie wechseln die Backends, mit Cookie-Datei bleibt der Client beim selben"
echo "- ohne Cookie:"; verteilung 10 $U/sticky/
echo "- mit Cookie:";  for i in $(seq 1 10); do on cl curl -s -m 3 -b /tmp/p11-jar -c /tmp/p11-jar $U/sticky/ | sed -n 's/^backend=//p'; done | sort | uniq -c | sed 's/^ *//'
echo "- Set-Cookie vom Proxy:"; on cl curl -s -m 3 -D - -o /dev/null $U/sticky/ | grep -i "^set-cookie" | sed -E 's/\r//'
step "3. Aktive Prüfung: b2 meldet sich krank (/health liefert 503); nach 2 Fehlschlägen nimmt HAProxy ihn heraus"
touch /tmp/p11-b2.down; sleep 3.5
echo "Zustand (Server, Status, Prüfergebnis):"; haproxy_cli "show stat" | awk -F, '$1=="rr" && $2!="BACKEND" && $2!="FRONTEND" {printf "   %s/%s  %s  %s\n", $1, $2, $18, $37}'
echo "- Verteilung jetzt:"; verteilung 10 $U/rr/
step "4. b2 gesund: nach 2 erfolgreichen Prüfungen wieder UP"
rm -f /tmp/p11-b2.down; sleep 3.5
haproxy_cli "show stat" | awk -F, '$1=="rr" && $2!="BACKEND" && $2!="FRONTEND" {printf "   %s/%s  %s  %s\n", $1, $2, $18, $37}'
echo "- Verteilung jetzt:"; verteilung 10 $U/rr/
step "5. Backup-Server: b2 trägt nur, wenn b1 ausfällt"
echo "- beide gesund:"; verteilung 10 $U/backup/
touch /tmp/p11-b1.down; sleep 3.5
echo "- b1 krank:";    verteilung 10 $U/backup/
rm -f /tmp/p11-b1.down
step "6. Laufzeit-Schnittstelle: Server sanft aus der Verteilung nehmen (drain), deaktivieren, Gewicht ändern"
sleep 3.5
cli "set server rr/b2 state drain"
echo "- drain: neue Anfragen gehen nicht mehr an b2:"; verteilung 10 $U/rr/
cli "set server rr/b2 state ready"
cli "set server rr/b2 weight 1"
cli "set server rr/b1 weight 3"
echo "- Gewicht b1 3 / b2 1:"; verteilung 20 $U/rr/
lab_down

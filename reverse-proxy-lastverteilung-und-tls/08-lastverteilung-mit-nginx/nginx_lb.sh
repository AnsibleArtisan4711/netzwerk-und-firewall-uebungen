#!/usr/bin/env bash
# Lastverteilung mit nginx: Round Robin, Gewichte, least_conn, ip_hash, passive Gesundheitsprüfung mit max_fails/fail_timeout.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
nginx_start "$D/lb.conf"
step "1. Round Robin: 20 Anfragen"
verteilung 20 http://shop.lab.test/rr/
step "2. Gewichtet 3:1 (b1 weight=3): 20 Anfragen"
verteilung 20 http://shop.lab.test/gewicht/
step "3. ip_hash: alle 20 Anfragen desselben Clients landen auf demselben Backend"
verteilung 20 http://shop.lab.test/hash/
step "4. least_conn: eine lange Anfrage hält ein Backend besetzt, 10 kurze Anfragen sollten überwiegend das andere treffen"
( on cl curl -s -m 8 "http://shop.lab.test/lc/slow?s=4" -o /dev/null & ); sleep 0.6
verteilung 10 http://shop.lab.test/lc/
step "5. Passive Prüfung: b2 wird beendet. Alle Anfragen gelingen trotzdem (nginx probiert das nächste Backend), b2 wird nach 2 Fehlern 5 s lang ausgelassen"
on b2 pkill -f "backend.py b2"; sleep 0.5
sleep 4.5      # least_conn-Anfrage aus Schritt 4 abwarten
verteilung 20 http://shop.lab.test/passiv/
echo "Fehlermeldungen im Fehlerprotokoll (connect() failed): $(grep -c 'connect() failed' /tmp/p11-nginx/error.log)"
echo "Beispielzeile: $(grep -m1 'connect() failed' /tmp/p11-nginx/error.log | sed -E 's/^[0-9\/]+ [0-9:]+ //; s/\[error\] [0-9#]+: //; s/, client:.*upstream:/, upstream:/; s/, host:.*//')"
step "6. b2 wieder starten; nach Ablauf von fail_timeout (5 s) nimmt nginx es wieder auf"
bg b2 python3 "$D/../backend.py" b2 8080; sleep 6.5
verteilung 20 http://shop.lab.test/passiv/
lab_down

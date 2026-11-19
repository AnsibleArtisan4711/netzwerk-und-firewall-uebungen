#!/usr/bin/env bash
# Testkatalog für die Musterlösung des Abschlussprojekts (abschluss.conf): jede Anforderung ein Test mit erwartetem Ergebnis.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up; ca_erzeugen
nginx_start "$D/abschluss.conf"
CAF=$CA/ca.pem; ok=0; fail=0
pruefe() {   # pruefe "Beschreibung" "erwartet" "ist"
  if [ "$2" = "$3" ]; then ok=$((ok+1)); printf 'OK     %-58s %s\n' "$1" "$3"; else fail=$((fail+1)); printf 'FEHLER %-58s erwartet=%s ist=%s\n' "$1" "$2" "$3"; fi
}
step "Testkatalog"
pruefe "HTTP wird mit 301 auf HTTPS umgeleitet" "301" "$(on cl curl -s -m 3 -o /dev/null -w '%{http_code}' http://shop.lab.test/)"
pruefe "HTTPS mit Lab-CA gelingt" "200" "$(on cl curl -s -m 3 --cacert $CAF -o /dev/null -w '%{http_code}' https://shop.lab.test/)"
pruefe "HTTPS ohne Lab-CA wird abgelehnt (curl 60)" "60" "$(on cl curl -s -m 3 -o /dev/null https://shop.lab.test/; echo $?)"
pruefe "HSTS-Header vorhanden" "1" "$(on cl curl -s -m 3 --cacert $CAF -D - -o /dev/null https://shop.lab.test/ | grep -ci '^strict-transport-security')"
pruefe "Server-Header ohne Version" "server: nginx" "$(on cl curl -s -m 3 --cacert $CAF -D - -o /dev/null https://shop.lab.test/ | grep -i '^server:' | tr -d '\r' | tr A-Z a-z)"
pruefe "Backend-Kennung ist verborgen" "0" "$(on cl curl -s -m 3 --cacert $CAF -D - -o /dev/null https://shop.lab.test/ | grep -ci '^x-backend')"
pruefe "Gefälschtes X-Forwarded-For wird überschrieben" "x-forwarded-for=10.1.1.2" "$(on cl curl -s -m 3 --cacert $CAF -H 'X-Forwarded-For: 6.6.6.6' https://shop.lab.test/ | grep x-forwarded-for)"
pruefe "Backend erfährt X-Forwarded-Proto=https" "x-forwarded-proto=https" "$(on cl curl -s -m 3 --cacert $CAF https://shop.lab.test/ | grep x-forwarded-proto)"
pruefe "TLS 1.2 wird akzeptiert" "TLSv1.2" "$(echo | on cl openssl s_client -connect 10.1.1.1:443 -servername shop.lab.test -tls1_2 2>&1 | sed -n 's/^New, \(TLSv[0-9.]*\),.*/\1/p')"
pruefe "Unbekannter Host-Name: keine Antwort (curl 52 oder 0)" "000" "$(on cl curl -s -m 3 -o /dev/null -w '%{http_code}' -H 'Host: fremd.example' http://10.1.1.1/)"
lb12() { for i in $(seq 1 12); do on cl curl -s -m 3 --cacert $CAF https://shop.lab.test/ | sed -n 's/^backend=//p'; sleep 0.25; done | sort | uniq -c | sed 's/^ *//' | paste -sd' '; }   # 4 Anfragen pro Sekunde, unter dem Limit
pruefe "Lastverteilung: 12 Anfragen verteilen sich auf beide Backends" "6 b1 6 b2" "$(lb12)"
echo "- Ausfall von b2: alle Anfragen gelingen weiter"
on b2 pkill -f "backend.py b2"; sleep 0.5
pruefe "12 Anfragen nach Ausfall von b2: alle von b1" "12 b1" "$(lb12)"
echo "- Begrenzung: 30 schnelle Anfragen (5 pro Sekunde, Burst 10)"
n429=$(for i in $(seq 1 30); do on cl curl -s -m 3 --cacert $CAF -o /dev/null -w '%{http_code}\n' https://shop.lab.test/; done | grep -c 429)
pruefe "mindestens 10 Anfragen mit 429 abgewiesen" "ja" "$([ "$n429" -ge 10 ] && echo ja || echo nein)"
echo "Ergebnis: $ok bestanden, $fail fehlgeschlagen"
lab_down

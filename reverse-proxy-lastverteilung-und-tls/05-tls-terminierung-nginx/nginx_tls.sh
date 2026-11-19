#!/usr/bin/env bash
# TLS-Terminierung mit nginx: Zertifikat, Weiterleitung auf HTTPS, HSTS, Protokollversionen, HTTP/2, Weitergabe von X-Forwarded-Proto.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up; ca_erzeugen
nginx_start "$D/tls.conf"
CAF=$CA/ca.pem
step "1. HTTP wird auf HTTPS umgeleitet (301), curl folgt nicht"
cmd on cl curl -s -m 3 -I http://shop.lab.test/foo | grep -v "^Date:"
step "2. HTTPS mit der CA des Labors: Verbindung, Protokollversion, Server-Antwort"
cmd on cl curl -s -m 3 --cacert $CAF https://shop.lab.test/
step "3. Ohne die CA lehnt curl ab (Rückgabewert 60)"
on cl curl -s -m 3 -o /dev/null https://shop.lab.test/; echo "$ curl https://shop.lab.test/ → Rückgabewert $?"

step "4. HSTS-Header und HTTP-Version"
on cl curl -s -m 3 --cacert $CAF -o /dev/null -D - --http2 -w "Protokoll: HTTP/%{http_version}\n" https://shop.lab.test/ | grep -iE "^HTTP/|strict-transport|Protokoll"
on cl curl -sv -m 3 --cacert $CAF -o /dev/null https://shop.lab.test/ 2>&1 | grep -E "SSL connection using|ALPN: server accepted"
step "5. Zertifikat des Servers wie es der Client sieht"
on cl sh -c "echo | openssl s_client -connect 10.1.1.1:443 -servername shop.lab.test -CAfile $CAF 2>/dev/null | openssl x509 -noout -subject -issuer -ext subjectAltName" | sed 's/^/   /'
step "6. Protokollversionen: TLS 1.2 und 1.3 erlaubt"
for v in tls1_2 tls1_3; do
  r=$(on cl sh -c "echo | openssl s_client -connect 10.1.1.1:443 -servername shop.lab.test -$v 2>&1" | grep -E "^New, TLS" | sed 's/, Cipher is.*//; s/^New, //')
  echo "$v: ${r:-keine Verbindung}"
done
step "7. Nur TLS 1.3 zulassen (ssl_protocols ändern, nginx neu laden): TLS 1.2 wird abgelehnt"
sed 's/ssl_protocols       TLSv1.2 TLSv1.3;/ssl_protocols       TLSv1.3;/' "$D/tls.conf" > /tmp/p11-tls13.conf
sed -i "s#include .*;#include /tmp/p11-tls13.conf;#" /tmp/p11-nginx.conf; nginx_neu_laden
for v in tls1_2 tls1_3; do
  r=$(on cl sh -c "echo | openssl s_client -connect 10.1.1.1:443 -servername shop.lab.test -$v 2>&1" | grep -E "^New, TLS" | sed 's/, Cipher is.*//; s/^New, //')
  echo "$v: ${r:-keine Verbindung (Server lehnt die Version ab)}"
done
step "8. Das Backend erfährt über X-Forwarded-Proto, dass außen HTTPS gesprochen wurde"
on cl curl -s -m 3 --cacert $CAF https://shop.lab.test/ | grep -E "host|x-forwarded-proto|x-forwarded-for"
lab_down

#!/usr/bin/env bash
# TLS-Terminierung mit HAProxy: mehrere Zertifikate (SNI), HTTP/2, Weiterleitung, HSTS und TLS-Durchleitung.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up; ca_erzeugen; zert_erzeugen shop.lab.test; zert_erzeugen api.lab.test   # je ein Zertifikat pro Name (Datei: Zertifikat + Schlüssel)
CAF=$CA/ca.pem
bg px openssl s_server -accept 4443 -cert $CA/server.crt -key $CA/server.key -www -quiet
step "1. HAProxy prüfen und starten"
haproxy_start "$D/haproxy_tls.cfg"
step "2. HTTP -> HTTPS (301) und HTTPS mit HTTP/2"
cmd on cl curl -s -m 3 -o /dev/null -w "HTTP %{http_code} -> %{redirect_url}\n" http://shop.lab.test/x
on cl curl -s -m 3 --cacert $CAF -o /dev/null -D - -w "Protokoll: HTTP/%{http_version}\n" --http2 https://shop.lab.test/ | grep -iE "^HTTP/|strict-transport|Protokoll"
step "3. SNI: je nach Servername liefert HAProxy ein anderes Zertifikat und ein anderes Backend"
for n in shop.lab.test api.lab.test; do
  echo "- $n: $(on cl sh -c "echo | openssl s_client -connect 10.1.1.1:443 -servername $n -CAfile $CAF 2>/dev/null | openssl x509 -noout -subject" | sed 's/subject=//')"
  echo "  Backend: $(on cl curl -s -m 3 --cacert $CAF https://$n/ | sed -n 's/^backend=//p')"
done
step "4. Header, die das Backend sieht (TLS wurde am Proxy beendet)"
on cl curl -s -m 3 --cacert $CAF https://shop.lab.test/ | grep -E "host|x-forwarded"
step "5. Passthrough (Port 8443): das Zertifikat kommt vom dahinterliegenden TLS-Server, HAProxy sieht keinen Klartext"
on cl sh -c "echo | openssl s_client -connect 10.1.1.1:8443 -servername shop.lab.test -CAfile $CAF 2>/dev/null | grep -E 'subject=|Verification'" | head -3
on cl curl -s -m 3 --cacert $CAF --resolve shop.lab.test:8443:10.1.1.1 https://shop.lab.test:8443/ | head -3
step "6. HAProxy-Zustand"
haproxy_tabelle
lab_down

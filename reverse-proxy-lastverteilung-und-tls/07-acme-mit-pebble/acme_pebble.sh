#!/usr/bin/env bash
# ACME mit einem lokalen Testserver (Pebble) und certbot: Zertifikat ausstellen (standalone und webroot), einbinden, erneuern.
# Voraussetzungen (nicht im Repository): Pebble-Programm, Pebble-Quellordner (Testzertifikate), certbot.
#   PEBBLE_BIN   Pfad zum Programm pebble               (Standard: pebble)
#   PEBBLE_SRC   Quellordner von Pebble (test/certs/…)  (Standard: $HOME/pebble)
#   CERTBOT      Pfad zu certbot                        (Standard: certbot)
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
PEBBLE_BIN=${PEBBLE_BIN:-pebble}; PEBBLE_SRC=${PEBBLE_SRC:-$HOME/pebble}; CERTBOT=${CERTBOT:-certbot}
LE=/tmp/p11-le; rm -rf $LE /tmp/p11-webroot; mkdir -p $LE /tmp/p11-webroot/.well-known/acme-challenge
export REQUESTS_CA_BUNDLE=$PEBBLE_SRC/test/certs/pebble.minica.pem      # certbot soll dem Testserver vertrauen
CB="$CERTBOT certonly --non-interactive --agree-tos --register-unsafely-without-email --server https://localhost:14000/dir --config-dir $LE/conf --work-dir $LE/work --logs-dir $LE/logs"
lab_up
cat > $LE/pebble.json <<RS
{ "pebble": { "listenAddress": "0.0.0.0:14000", "managementListenAddress": "0.0.0.0:15000",
  "certificate": "$PEBBLE_SRC/test/certs/localhost/cert.pem", "privateKey": "$PEBBLE_SRC/test/certs/localhost/key.pem",
  "httpPort": 80, "tlsPort": 443, "ocspResponderURL": "", "externalAccountBindingRequired": false,
  "certificateValidityPeriod": 7776000 } }
RS
step "1. Pebble starten (ACME-Testserver auf dem Proxy: Verzeichnis unter https://localhost:14000/dir, Prüfung auf Port 80)"
PEBBLE_VA_NOSLEEP=1 bg px "$PEBBLE_BIN" -config $LE/pebble.json; sleep 2
on px curl -s --cacert $PEBBLE_SRC/test/certs/pebble.minica.pem https://localhost:14000/dir | python3 -c "import json,sys; d=json.load(sys.stdin); print('\n'.join(sorted(d)[:5]))"
step "2. Zertifikat für shop.lab.test mit der Methode standalone (certbot lauscht selbst auf Port 80)"
echo "$ certbot certonly --standalone -d shop.lab.test --server https://localhost:14000/dir"
on px $CB --standalone -d shop.lab.test 2>&1 | grep -E "Successfully|Certificate is saved|Key is saved|This certificate expires|Requesting|Challenge|Error|error" | sed -E 's/expires on .*/expires on (Datum)/'
step "3. Ergebnis: Dateien und Aussteller (der Aussteller ist die Testzertifizierungsstelle, nicht die Lab-CA)"
ls $LE/conf/live/shop.lab.test | tr '\n' ' '; echo
openssl x509 -in $LE/conf/live/shop.lab.test/cert.pem -noout -subject -issuer -ext subjectAltName | sed 's/^/   /' | sed -E 's/Pebble Intermediate CA [0-9a-f]+/Pebble Intermediate CA (Kennung)/'
step "4. Zweites Zertifikat mit der Methode webroot (nginx liefert die Challenge-Datei aus), dann nginx mit HTTPS starten"
nginx_start "$D/nginx_acme.conf"
echo "$ certbot certonly --webroot -w /tmp/p11-webroot -d api.lab.test --server https://localhost:14000/dir"
on px $CB --webroot -w /tmp/p11-webroot -d api.lab.test 2>&1 | grep -E "Successfully|Certificate is saved|Error|error"
nginx_start "$D/nginx_acme_tls.conf"
step "5. Prüfen mit dem Wurzelzertifikat des Testservers (Abruf über die Verwaltungsschnittstelle von Pebble)"
on px curl -s --cacert $PEBBLE_SRC/test/certs/pebble.minica.pem https://localhost:15000/roots/0 > $LE/root.pem
openssl x509 -in $LE/root.pem -noout -subject | sed 's/^/   /' | sed -E 's/Pebble Root CA [0-9a-f]+/Pebble Root CA (Kennung)/'
echo "$ curl --cacert root.pem https://api.lab.test/"; on cl curl -s -m 3 --cacert $LE/root.pem https://api.lab.test/ | grep -E "backend|host|x-forwarded-proto"
step "6. Erneuern: certbot renew prüft die Laufzeit; mit --force-renewal wird sofort ein neues Zertifikat ausgestellt, der Hook lädt nginx neu"
S1=$(openssl x509 -in $LE/conf/live/api.lab.test/cert.pem -noout -serial)
echo "$ certbot renew --no-random-sleep-on-renew --force-renewal --cert-name api.lab.test --deploy-hook \"kill -HUP <nginx>\""
on px $CERTBOT renew --no-random-sleep-on-renew --force-renewal --cert-name api.lab.test --server https://localhost:14000/dir --config-dir $LE/conf --work-dir $LE/work --logs-dir $LE/logs --deploy-hook "kill -HUP \$(cat /tmp/p11-nginx/nginx.pid)" 2>&1 | grep -E "Congratulations|renewed|deploy|Hook|hook|failure|Error"
S2=$(openssl x509 -in $LE/conf/live/api.lab.test/cert.pem -noout -serial)
[ "$S1" != "$S2" ] && echo "Seriennummer geändert: neues Zertifikat ausgestellt" || echo "Seriennummer unverändert"
sleep 0.5
SL=$(echo | on cl openssl s_client -connect 10.1.1.1:443 -servername api.lab.test 2>/dev/null | openssl x509 -noout -serial)
[ "$SL" = "$S2" ] && echo "nginx liefert das neue Zertifikat (Hook hat neu geladen)" || echo "nginx liefert noch das alte Zertifikat"
step "7. Laufzeit und Erneuerungskonfiguration"
openssl x509 -in $LE/conf/live/api.lab.test/cert.pem -noout -startdate -enddate | sed 's/^/   /'
grep -E "^(authenticator|server|renew_before_expiry)" $LE/conf/renewal/api.lab.test.conf | sed 's/^/   /'
lab_down

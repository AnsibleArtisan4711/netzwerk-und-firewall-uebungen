#!/usr/bin/env bash
# Interne CA mit openssl: Root-CA, Serverzertifikat mit SAN, Prüfung der Kette, typische Fehler (falscher Name, abgelaufen, fehlende CA).
. "$(dirname "$0")/../lab.sh"
W=/tmp/p11-ca4; rm -rf $W; mkdir -p $W; cd $W
step "1. Root-CA: Schlüssel und selbstsigniertes Zertifikat (30 Tage; im Echtbetrieb länger und Schlüssel geschützt)"
echo "$ openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.pem -days 30 -subj \"/O=Lab/CN=Lab Root CA\""
openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.pem -days 30 -subj "/O=Lab/CN=Lab Root CA" 2>/dev/null
openssl x509 -in ca.pem -noout -subject -issuer -dates -ext basicConstraints 2>&1 | sed 's/^/   /'
step "2. Serverschlüssel und Zertifikatsanforderung (CSR); der Name steht im CSR"
openssl req -newkey rsa:2048 -nodes -keyout server.key -out server.csr -subj "/O=Lab/CN=shop.lab.test" 2>/dev/null
openssl req -in server.csr -noout -subject -verify 2>&1 | sed 's/^/   /'
step "3. CA signiert: Namen kommen über subjectAltName (SAN); der Common Name allein reicht Browsern und curl nicht"
cat > san.ext <<'RS'
subjectAltName=DNS:shop.lab.test,DNS:api.lab.test
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
RS
cat san.ext
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out server.crt -days 30 -extfile san.ext 2>&1 | sed 's/^/   /'
openssl x509 -in server.crt -noout -subject -issuer -ext subjectAltName 2>&1 | sed 's/^/   /'
step "4. Kette prüfen"
cmd openssl verify -CAfile ca.pem server.crt
cmd openssl x509 -in server.crt -noout -checkhost shop.lab.test
cmd openssl x509 -in server.crt -noout -checkhost www.example.org
cmd openssl x509 -in server.crt -noout -checkend 86400
cmd openssl x509 -in server.crt -noout -checkend 3888000
step "5. Passt der Schlüssel zum Zertifikat? (Vergleich des öffentlichen Schlüssels aus Zertifikat und Schlüsseldatei)"
a=$(openssl x509 -in server.crt -noout -pubkey | openssl sha256); b=$(openssl pkey -in server.key -pubout | openssl sha256)
[ "$a" = "$b" ] && echo "Schlüssel und Zertifikat gehören zusammen" || echo "NICHT zusammengehörig"
step "6. TLS-Verbindung mit openssl s_server und s_client: mit und ohne CA, mit falschem Namen"
lab_up
bg px openssl s_server -accept 4443 -cert server.crt -key server.key -www -quiet; sleep 0.8
echo "- mit CA und richtigem Namen:"
on cl sh -c "echo | openssl s_client -connect 10.1.1.1:4443 -servername shop.lab.test -CAfile $W/ca.pem -verify_hostname shop.lab.test 2>&1 | grep -E 'Verification|Verify return'"
echo "- ohne CA (Vertrauen fehlt):"
on cl sh -c "echo | openssl s_client -connect 10.1.1.1:4443 -servername shop.lab.test 2>&1 | grep -E 'Verification|Verify return'"
echo "- falscher Name:"
on cl sh -c "echo | openssl s_client -connect 10.1.1.1:4443 -CAfile $W/ca.pem -verify_hostname www.example.org 2>&1 | grep -E 'Verification|Verify return'"
lab_down

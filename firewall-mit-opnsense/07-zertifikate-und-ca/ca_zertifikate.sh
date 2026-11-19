#!/usr/bin/env bash
# Modul 7: Zertifikate. OPNsense verwaltet CAs und Zertifikate in einer eigenen Oberfläche; hier das Handwerk mit openssl:
# interne CA, Server- und Client-Zertifikat, Prüfung, Sperrliste (CRL). Keine OPNsense-Dateien oder Menüs ausgeführt.
set -e
W=$(mktemp -d /tmp/p08-ca.XXXX); cd "$W"
step() { echo; echo "## $*"; }
step "1. Interne CA (Schlüssel, selbstsigniertes Zertifikat, 30 Tage)"
openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.crt -days 30 -subj "/O=Lab/CN=Lab Firewall CA" \
  -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null
openssl x509 -in ca.crt -noout -subject -issuer -ext basicConstraints
step "2. Serverzertifikat für die Weboberfläche der Firewall (SAN mit Name und Adresse)"
openssl req -newkey rsa:2048 -nodes -keyout fw.key -out fw.csr -subj "/O=Lab/CN=fw.lab.test" 2>/dev/null
printf "subjectAltName=DNS:fw.lab.test,IP:10.8.1.1\nextendedKeyUsage=serverAuth\n" > fw.ext
openssl x509 -req -in fw.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out fw.crt -days 30 -extfile fw.ext 2>/dev/null
openssl x509 -in fw.crt -noout -subject -issuer -ext subjectAltName,extendedKeyUsage
step "3. Prüfen: Kette, Name, Adresse, Restlaufzeit"
openssl verify -CAfile ca.crt fw.crt
openssl x509 -in fw.crt -noout -checkhost fw.lab.test; openssl x509 -in fw.crt -noout -checkip 10.8.1.1
openssl x509 -in fw.crt -noout -checkhost falsch.lab.test
openssl x509 -in fw.crt -noout -checkend 86400 && openssl x509 -in fw.crt -noout -checkend 3888000 || true
step "4. Clientzertifikat (für Anmeldung per Zertifikat, z. B. VPN) mit clientAuth"
openssl req -newkey rsa:2048 -nodes -keyout bob.key -out bob.csr -subj "/O=Lab/CN=bob" 2>/dev/null
printf "extendedKeyUsage=clientAuth\n" > bob.ext
openssl x509 -req -in bob.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out bob.crt -days 30 -extfile bob.ext 2>/dev/null
openssl x509 -in bob.crt -noout -subject -ext extendedKeyUsage
step "5. Sperrliste (CRL): Zertifikat von bob widerrufen und prüfen"
mkdir -p demoCA; : > demoCA/index.txt; echo 1000 > demoCA/crlnumber
printf "[ca]\ndefault_ca=c\n[c]\ndatabase=demoCA/index.txt\ncrlnumber=demoCA/crlnumber\ndefault_md=sha256\ndefault_crl_days=7\ncertificate=ca.crt\nprivate_key=ca.key\nnew_certs_dir=demoCA\nunique_subject=no\npolicy=p\n[p]\ncommonName=supplied\n" > ca.cnf
openssl ca -config ca.cnf -revoke bob.crt 2>&1 | grep -i "^Revoking" | sed -E "s/Certificate [0-9A-F]+\./Certificate <Seriennummer>./"
openssl ca -config ca.cnf -gencrl -out ca.crl 2>/dev/null
openssl crl -in ca.crl -noout -issuer -nextupdate >/dev/null && echo "CRL ausgestellt von: $(openssl crl -in ca.crl -noout -issuer)"
openssl crl -in ca.crl -noout -text | grep -E 'Serial Number' | sed 's/^ *//' | sed -E 's/Serial Number: .*/Serial Number: (Nummer von bob.crt)/'
cat ca.crt ca.crl > chain_crl.pem
openssl verify -crl_check -CAfile chain_crl.pem fw.crt 2>&1 | head -1
openssl verify -crl_check -CAfile chain_crl.pem bob.crt 2>&1 | grep -E 'revoked|OK' | head -1
step "6. TLS-Verbindung mit CA prüfen (s_server/s_client, Rückgabecode)"
openssl s_server -accept 14433 -cert fw.crt -key fw.key -www -quiet >/dev/null 2>&1 &
SP=$!; sleep 1
echo | openssl s_client -connect 127.0.0.1:14433 -servername fw.lab.test -CAfile ca.crt -verify_hostname fw.lab.test 2>&1 | grep -E 'Verify return code'
echo | openssl s_client -connect 127.0.0.1:14433 -CAfile ca.crt -verify_hostname falsch.lab.test 2>&1 | grep -E 'Verify return code'
echo | openssl s_client -connect 127.0.0.1:14433 2>&1 | grep -E 'Verify return code'
kill $SP 2>/dev/null; wait $SP 2>/dev/null || true
cd /; rm -rf "$W"

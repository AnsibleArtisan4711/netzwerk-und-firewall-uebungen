#!/usr/bin/env bash
# Modul 11: Sicherung der Konfiguration. OPNsense speichert seine Konfiguration als XML-Datei (Export über die Oberfläche; nicht ausgeführt).
# Geübt wird mit einer frei erfundenen Beispieldatei: prüfen, vergleichen, Geheimnisse schwärzen, verschlüsseln, wiederherstellen, Aufbewahrung.
D=$(cd "$(dirname "$0")" && pwd)
W=$(mktemp -d /tmp/p08-cfg.XXXX); cd "$W"; umask 077
step() { echo; echo "## $*"; }
cp "$D/config.xml.beispiel" config.xml
step "1. Sicherung anlegen und Prüfsumme bilden"
cp config.xml "sicherung-1.xml"; sha256sum sicherung-1.xml | awk '{print substr($1,1,16)"…  "$2}'
step "2. Wohlgeformtheit prüfen (xmllint) – vor dem Einspielen unbedingt"
xmllint --noout config.xml && echo "config.xml: wohlgeformt"
sed 's#</rules>#<rule></rules>#' config.xml > kaputt.xml; xmllint --noout kaputt.xml 2>&1 | head -2 | cut -c1-110
step "3. Änderung vornehmen und Unterschiede anzeigen (diff)"
sed 's#<port>80</port></rule>#<port>80</port></rule>\n    <rule><nr>2</nr><action>pass</action><from>lan</from><to>dmz</to><port>443</port></rule>#' config.xml > neu.xml
cp neu.xml sicherung-2.xml; diff -u sicherung-1.xml sicherung-2.xml | tail -n +3 | cut -c1-120
step "4. Vor dem Weitergeben (Support, Forum) Geheimnisse schwärzen"
sed -E 's#(<password>)[^<]*#\1<geschwärzt>#; s#(<privatekey>)[^<]*#\1<geschwärzt>#' config.xml > teilbar.xml
grep -c GEHEIM config.xml | sed 's/^/Zeilen mit Geheimnis im Original: /'; grep -c GEHEIM teilbar.xml | sed 's/^/Zeilen mit Geheimnis in der geteilten Datei: /'
step "5. Verschlüsselt aufbewahren (openssl AES-256, Passwort aus Umgebungsvariable)"
export BACKUP_PW="Lab-Passwort-nur-zum-Test"
openssl enc -aes-256-cbc -pbkdf2 -salt -pass env:BACKUP_PW -in sicherung-2.xml -out sicherung-2.xml.enc
echo "Dateianfang: $(head -c 8 sicherung-2.xml.enc)"; echo "Klartext in der Datei: $(grep -c firewall-beispiel sicherung-2.xml.enc) Treffer"
openssl enc -d -aes-256-cbc -pbkdf2 -pass env:BACKUP_PW -in sicherung-2.xml.enc -out zurueck.xml && cmp sicherung-2.xml zurueck.xml && echo "Entschlüsselt: identisch mit dem Original"
BACKUP_PW=falsch openssl enc -d -aes-256-cbc -pbkdf2 -pass env:BACKUP_PW -in sicherung-2.xml.enc -out /dev/null 2>&1 | head -1
step "6. Aufbewahrung: nur die letzten 3 Sicherungen behalten"
for i in 1 2 3 4 5; do cp config.xml "auto-$i.xml"; touch -d "2026-11-0$i" "auto-$i.xml"; done
ls -1t auto-*.xml | tail -n +4 | xargs rm -f; ls -1 auto-*.xml
unset BACKUP_PW; cd /; rm -rf "$W"

#!/usr/bin/env bash
# Regelwerk sichern, prüfen, atomar laden, fehlerhafte Datei erkennen, include-Aufbau wie in /etc/nftables.conf.
. "$(dirname "$0")/../lab.sh"
lab_up
W=/tmp/p09-sichern; rm -rf $W; mkdir -p $W/conf.d; cd $W
cat > conf.d/10-basis.nft <<'RS'
table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    iif "lo" accept
    ct state established,related accept
    tcp dport 80 accept
  }
}
RS
cat > nftables.conf <<'RS'
#!/usr/sbin/nft -f
flush ruleset
include "conf.d/*.nft"
RS
step "1. Falle: relativer include-Pfad ohne -I findet nichts, und nft meldet trotzdem keinen Fehler"
cmd on srv nft -f nftables.conf
echo "Zeilen im Regelwerk: $(on srv nft list ruleset | wc -l)"
step "2. Mit Suchpfad (-I .) wird conf.d/*.nft gefunden; erst prüfen, dann laden"
cmd on srv nft -I . -c -f nftables.conf && echo "Prüfung ok"
cmd on srv nft -I . -f nftables.conf
echo "Zeilen im Regelwerk: $(on srv nft list ruleset | wc -l)"
http_get cl 10.0.2.2 80; http_get cl 10.0.2.2 8080
step "3. Laufendes Regelwerk sichern mit nft list ruleset"
on srv nft list ruleset > sicherung.nft
cat sicherung.nft
step "4. Atomar: Datei mit ungültigem Port (99999) ändert NICHTS am laufenden Regelwerk"
cat > conf.d/20-kaputt.nft <<'RS'
table inet filter {
  chain input {
    tcp dport 8080 accept
    tcp dport 99999 accept
  }
}
RS
cmd on srv nft -I . -f nftables.conf
http_get cl 10.0.2.2 8080
rm conf.d/20-kaputt.nft
step "5. Neues Regelwerk in einem Schritt austauschen (flush + Neuaufbau in einer Transaktion)"
cat > conf.d/20-8080.nft <<'RS'
add rule inet filter input tcp dport 8080 accept
RS
cmd on srv nft -I . -f nftables.conf
http_get cl 10.0.2.2 8080
step "6. Zurück zur Sicherung aus Schritt 3 (ohne Port 8080); ohne Regelwerk ist der Server offen"
cmd on srv nft flush ruleset
http_get cl 10.0.2.2 80
cmd on srv nft -f sicherung.nft
http_get cl 10.0.2.2 80; http_get cl 10.0.2.2 8080
step "7. Dauerhaft: so sieht die Einbindung in systemd aus (nur gezeigt, hier nicht ausgeführt)"
cat <<'RS'
# /etc/nftables.conf wird vom Dienst nftables.service beim Start geladen:
#   systemctl enable --now nftables
#   systemctl reload nftables    # lädt die Datei neu
#   nft -c -f /etc/nftables.conf # vorher prüfen
RS
lab_down

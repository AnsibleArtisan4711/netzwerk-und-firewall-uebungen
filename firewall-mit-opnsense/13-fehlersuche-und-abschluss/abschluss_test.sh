#!/usr/bin/env bash
# Abschlussprojekt: Testkatalog. Lädt abschluss_loesung.nft (oder die Datei aus $1) in die Firewall und prüft die Anforderungen.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd); RS=${1:-$D/abschluss_loesung.nft}
lab_up
step "Regelwerk prüfen und laden: $(basename "$RS")"
on fw nft -c -f "$RS" && echo "Syntax: OK (nft -c)"
on fw nft -f "$RS" && echo "Geladen"
ok=0; fehl=0
pruefe() { # pruefe "Text" erwartet(ja|nein) Befehl...   – „ja“ = Befehl muss gelingen
  local t=$1 e=$2; shift 2
  if "$@" >/dev/null 2>&1; then r=ja; else r=nein; fi
  if [ "$r" = "$e" ]; then echo "[OK]   $t"; ok=$((ok+1)); else echo "[FEHL] $t (erwartet: $e, war: $r)"; fehl=$((fehl+1)); fi; }
h() { on "$1" curl -s -m 2 -o /dev/null --fail "http://$2:$3/"; }
step "Tests"
pruefe "LAN → DMZ Port 80 erreichbar" ja h cl 10.8.2.2 80
pruefe "LAN → DMZ Port 8080 erreichbar" ja h cl 10.8.2.2 8080
pruefe "LAN → DMZ Port 22 gesperrt" nein h cl 10.8.2.2 22
pruefe "LAN → Internet Port 80 erreichbar" ja h cl 10.8.9.1 80
pruefe "Internet sieht die WAN-Adresse der Firewall (NAT)" ja bash -c "[ \"\$(ip netns exec p08-cl curl -s -m 2 http://10.8.9.1/ | grep -o 'client=[0-9.]*')\" = client=10.8.9.2 ]"
pruefe "DMZ → LAN gesperrt" nein h srv 10.8.1.2 80
pruefe "DMZ → Internet gesperrt" nein h srv 10.8.9.1 80
pruefe "Internet → Firewall Port 8080 landet im DMZ-Server (Portweiterleitung)" ja bash -c "ip netns exec p08-wan curl -s -m 2 http://10.8.9.2:8080/ | grep -q server=srv"
pruefe "Internet → Firewall Port 80 gesperrt (keine Weiterleitung)" nein h wan 10.8.9.2 80
pruefe "Internet → Firewall Ping gesperrt" nein on wan ping -c1 -W1 10.8.9.2
pruefe "LAN → Firewall Ping erlaubt" ja on cl ping -c1 -W1 10.8.1.1
pruefe "Gesperrter SSH-Versuch wird gezählt" ja bash -c "ip netns exec p08-fw nft list chain inet fw forward | grep -E 'SSH-GESPERRT.*packets [1-9]' "
echo; echo "Ergebnis: $ok bestanden, $fehl fehlgeschlagen"
lab_down
[ "$fehl" -eq 0 ]

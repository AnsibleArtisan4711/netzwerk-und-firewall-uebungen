#!/usr/bin/env bash
# Migration: iptables-Regelwerk übersetzen, in nftables laden und Verhalten vorher/nachher vergleichen.
. "$(dirname "$0")/../lab.sh"
cd "$(dirname "$0")"
lab_up
on srv pkill -f "http.server 8080"; sleep 0.3
( cd /tmp/p09-www && setsid ip netns exec $NS_SRV python3 -m http.server 8080 >/dev/null 2>&1 < /dev/null & ); sleep 0.6
matrix() {   # fester Testkatalog; Ausgabe wird für den Vergleich gespeichert
  http_get cl 10.0.2.2 80; http_get cl 10.0.2.2 8080; http_get cl 10.0.1.1 8000; http_get cl 10.0.2.2 22
  ping_test cl 10.0.2.2; ping_test srv 10.0.1.2
  on srv curl -s -m 2 http://10.0.2.2:8080/ >/dev/null; on cl curl -s -m 2 -o /dev/null http://10.0.1.1:8000/
}
step "1. Altbestand mit iptables-restore laden und testen"
cmd on fw iptables-restore alt.rules
on fw iptables-save | grep -v '^#' | head -20
matrix | tee /tmp/p09-vorher.txt
step "2. Sichern und mit iptables-restore-translate übersetzen"
on fw iptables-save > gesichert.rules
echo "$ iptables-restore-translate -f gesichert.rules > neu.nft"; iptables-restore-translate -f gesichert.rules > neu.nft
grep -v "^# " neu.nft
step "3. Einzelne Regeln übersetzen (iptables-translate)"
cmd iptables-translate -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set --name ssh
cmd iptables-translate -A FORWARD -s 10.0.0.0/8 ! -d 10.0.2.0/24 -j DROP
cmd ip6tables-translate -A INPUT -p ipv6-icmp -j ACCEPT
step "4. Alles Alte entfernen, übersetzte Datei laden, erneut testen"
on fw iptables -F; on fw iptables -t nat -F; on fw iptables -P FORWARD ACCEPT
on fw nft flush ruleset
cmd on fw nft -f neu.nft
on fw nft list ruleset
matrix | tee /tmp/p09-nachher.txt
step "5. Vergleich"
if diff /tmp/p09-vorher.txt /tmp/p09-nachher.txt >/dev/null; then echo "Verhalten identisch ($(wc -l < /tmp/p09-nachher.txt) Prüfungen)"; else diff /tmp/p09-vorher.txt /tmp/p09-nachher.txt; fi
lab_down

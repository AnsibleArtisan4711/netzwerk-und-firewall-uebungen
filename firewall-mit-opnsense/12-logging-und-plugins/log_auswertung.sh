#!/usr/bin/env bash
# Modul 12: Logging. OPNsense protokolliert Filterereignisse über pf (FreeBSD) – hier nicht verfügbar. Nachbildung: nftables-Regeln mit
# „log group“ (nflog), Mitschnitt mit tcpdump, Auswertung mit awk. Plugins (Teil des Moduls) werden nur beschrieben, nicht ausgeführt.
. "$(dirname "$0")/../lab.sh"
lab_up
on fw nft -f - <<'RS'
table inet fw {
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    iifname "v-lan" tcp dport { 80 } accept
    iifname "v-lan" tcp dport { 22, 23, 3389 } log group 5 prefix "BLOCK-LAN " counter drop
    iifname "v-wan" log group 5 prefix "BLOCK-WAN " counter drop
  }
}
RS
step "1. Mitschnitt der Protokollgruppe starten und Verkehr erzeugen"
timeout 12 ip netns exec p08-fw tcpdump -nn -i nflog:5 -l >/tmp/p08-log.txt 2>/dev/null &
TP=$!; sleep 1
test_http cl 10.8.2.2 80 >/dev/null
for p in 22 22 23 3389 22; do on cl curl -s -m 1 -o /dev/null http://10.8.2.2:$p/; done
on wan ip route add 10.8.2.0/24 via 10.8.9.2
on wan curl -s -m 1 -o /dev/null http://10.8.2.2:80/ || true
sleep 1; kill $TP 2>/dev/null; wait $TP 2>/dev/null
echo "Protokollzeilen: $(wc -l < /tmp/p08-log.txt)"
step "2. Rohe Zeilen (Beispiel: die ersten zwei, Zeitstempel entfernt)"
head -2 /tmp/p08-log.txt | sed -E 's/^[0-9:.]+ //'
step "3. Auswertung: wie oft wurde welcher Zielport blockiert? (nur SYN-Pakete)"
grep 'Flags \[S\]' /tmp/p08-log.txt | sed -E 's/.* > [0-9.]+\.([0-9]+): Flags.*/\1/' | sort | uniq -c | sort -rn | awk '{print "Port "$2": "$1"x"}'
step "4. Zähler der Regeln"
on fw nft list chain inet fw forward | grep 'counter packets' | sed -E 's/^\s+//; s/ bytes [0-9]+//'
step "5. Ohne Protokollierung der erlaubten Regel entsteht kein Eintrag (Protokollmenge steuern)"
echo "Regel „tcp dport 80 accept“ hat kein log: sie erscheint nicht in der Auswertung."
echo; echo "(Plugins: OPNsense erweitert sich über Pakete namens „os-…“; Installation und Wirkung sind hier nicht geprüft.)"
rm -f /tmp/p08-log.txt
lab_down

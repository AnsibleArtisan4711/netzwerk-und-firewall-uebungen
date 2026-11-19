#!/usr/bin/env bash
# Modul 13: Fehlersuche an fünf typischen Fehlern (Regelreihenfolge, fehlendes NAT, Portweiterleitung ohne Filterregel,
# falsches Gateway im Server, Tippfehler im Alias). Jeweils: Symptom → Diagnose → Korrektur → erneuter Test.
. "$(dirname "$0")/../lab.sh"
lab_up
basis() { # korrektes Regelwerk; Argument: Zusatzzeilen für forward (am Anfang), „nonat“ lässt Masquerade weg
on fw nft flush ruleset
on fw nft -f - <<RS
table inet fw {
  set alias_dmz_server { type ipv4_addr; elements = { ${SRVIP:-10.8.2.2} } }
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
$1
    iifname "v-lan" oifname "v-dmz" ip daddr @alias_dmz_server tcp dport { 80, 8080 } counter accept comment "LAN-DMZ-Web"
    iifname "v-lan" oifname "v-wan" tcp dport 80 counter accept comment "LAN-Internet"
    counter comment "ENDE"
  }
}
RS
on fw nft add table ip nat; on fw nft add chain ip nat post '{ type nat hook postrouting priority 100; }'
[ "$2" = nonat ] || on fw nft add rule ip nat post oifname v-wan masquerade
}
zaehler() { on fw nft list chain inet fw forward | grep 'counter packets' | sed -E 's/^\s+//; s/ bytes [0-9]+//; s/^(.*) counter packets ([0-9]+) (.*)$/Zähler \2: \1 \3/'; }

step "Fehler 1: „SSH ist erreichbar, obwohl ich es gesperrt habe“"
basis '    iifname "v-lan" counter accept comment "ALLES-AUS-LAN"
    iifname "v-lan" tcp dport 22 counter drop comment "SSH-SPERRE"'
test_http cl 10.8.2.2 22
echo "Diagnose: Zähler je Regel (die Sperre steht unten und bleibt bei 0)"; zaehler | grep -E 'SSH-SPERRE|ALLES'
echo "Korrektur: Sperre vor die allgemeine Erlaubnis stellen"
on fw nft delete rule inet fw forward handle "$(on fw nft -a list chain inet fw forward | grep SSH-SPERRE | grep -oE '[0-9]+$')"
on fw nft insert rule inet fw forward position "$(on fw nft -a list chain inet fw forward | grep ALLES-AUS-LAN | grep -oE '[0-9]+$')" iifname v-lan tcp dport 22 counter drop comment '"SSH-SPERRE"' 2>/dev/null \
  || on fw nft insert rule inet fw forward handle "$(on fw nft -a list chain inet fw forward | grep ALLES-AUS-LAN | grep -oE '[0-9]+$')" iifname v-lan tcp dport 22 counter drop comment '"SSH-SPERRE"'
test_http cl 10.8.2.2 22

step "Fehler 2: „Von innen ist das Internet nicht erreichbar“ (NAT fehlt)"
basis "" nonat
test_http cl 10.8.9.1 80
echo "Diagnose: Mitschnitt auf der WAN-Seite – die Anfrage verlässt die Firewall mit der internen Quelladresse (10.8.1.2); das Internet kennt keine Rückroute"
timeout 4 ip netns exec p08-fw tcpdump -nn -i v-wan -c 1 'tcp[tcpflags] & tcp-syn != 0' 2>/dev/null >/tmp/p08-d.txt &
TP=$!; sleep 1; on cl curl -s -m 1 -o /dev/null http://10.8.9.1/; wait $TP; sed -E 's/^[0-9:.]+ //; s/\.[0-9]+ > 10.8.9.1/.PORT > 10.8.9.1/; s/seq [0-9]+, //; s/options.*//' /tmp/p08-d.txt | head -1
echo "Korrektur: Masquerade am WAN-Interface"; on fw nft add rule ip nat post oifname v-wan masquerade
test_http cl 10.8.9.1 80

step "Fehler 3: „Die Portweiterleitung funktioniert nicht“ (DNAT ohne Filterregel)"
basis ""; on fw nft add chain ip nat pre '{ type nat hook prerouting priority -100; }'
on fw nft add rule ip nat pre iifname v-wan tcp dport 8080 counter dnat to 10.8.2.2:80
cmd on wan curl -s -m 2 http://10.8.9.2:8080/
echo "Diagnose: Die NAT-Regel zählt (Pakete kommen an), die Standardregel am Ende der Filterkette zählt ebenfalls (sie werden verworfen)"
on fw nft list chain ip nat pre | grep -oE 'counter packets [0-9]+' | sed 's/^/NAT-Regel: /'; zaehler | grep ENDE
echo "Korrektur: Filterregel für die weitergeleiteten Verbindungen"
on fw nft insert rule inet fw forward iifname v-wan oifname v-dmz ct status dnat ip daddr 10.8.2.2 tcp dport 80 accept
cmd on wan curl -s -m 2 http://10.8.9.2:8080/

step "Fehler 4: „Der Server antwortet nicht“ (Server hat falsches Gateway)"
basis ""; on srv ip route replace default via 10.8.2.9
test_http cl 10.8.2.2 80
echo "Diagnose: Mitschnitt auf der DMZ-Seite – die Anfrage kommt an, der Server fragt per ARP nach seinem Gateway 10.8.2.9 und bekommt keine Antwort"
timeout 5 ip netns exec p08-fw tcpdump -nn -i v-dmz -c 3 'arp or tcp port 80' 2>/dev/null >/tmp/p08-d.txt &
TP=$!; sleep 1; on cl curl -s -m 2 -o /dev/null http://10.8.2.2/; wait $TP; sed -E 's/^[0-9:.]+ //; s/\.[0-9]+ > 10.8.2.2/.PORT > 10.8.2.2/; s/seq [0-9]+, //; s/options.*//' /tmp/p08-d.txt | sort -u | head -3
echo "Gegenprobe: Der Server ist im eigenen Netz erreichbar (nur der Rückweg in fremde Netze fehlt):"
test_ping fw 10.8.2.2
on srv ip route replace default via 10.8.2.1; echo "Korrektur: Gateway des Servers auf 10.8.2.1"
test_http cl 10.8.2.2 80

step "Fehler 5: „Neuer Server wird nicht erreicht“ (Tippfehler im Alias)"
SRVIP=10.8.2.22 basis ""
test_http cl 10.8.2.2 80
echo "Diagnose: Inhalt des Alias prüfen"; on fw nft list set inet fw alias_dmz_server | grep elements
on fw nft flush set inet fw alias_dmz_server; on fw nft add element inet fw alias_dmz_server '{ 10.8.2.2 }'
echo "Korrektur: Eintrag richtigstellen"; test_http cl 10.8.2.2 80
rm -f /tmp/p08-d.txt
lab_down

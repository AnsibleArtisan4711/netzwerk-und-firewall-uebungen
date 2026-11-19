#!/usr/bin/env bash
# Modul 4: Regeln und Reihenfolge. Nachbildung des Verhaltens „von oben nach unten, erster Treffer gilt, am Ende Standard-Block“.
. "$(dirname "$0")/../lab.sh"
lab_up
regeln() { on fw nft flush ruleset; on fw nft -f - <<RS
table inet fw {
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
$1
    counter comment "ENDE: Standard-Block"
  }
}
RS
}
zeigen() { on fw nft -a list chain inet fw forward | sed -E 's/^\s+//' | grep -v '^table\|^chain\|^type\|^}'; }
zaehler() { on fw nft list chain inet fw forward | grep 'counter packets' | sed -E 's/^\s+//; s/ bytes [0-9]+//' ; }
step "1. Standard: nichts erlaubt, am Ende blockt die Standardregel (weitergeleiteter Verkehr)"
regeln ""
test_http cl 10.8.2.2 80; test_ping cl 10.8.2.2
step "2. Falsche Reihenfolge: erst „alles aus dem LAN erlauben“, dann „SSH sperren“ – die Sperre kommt nie zum Zug"
regeln '    iifname "v-lan" accept comment "1 LAN alles"
    iifname "v-lan" tcp dport 22 drop comment "2 SSH sperren"'
test_http cl 10.8.2.2 22
step "3. Richtige Reihenfolge: erst sperren, dann erlauben"
regeln '    iifname "v-lan" tcp dport 22 drop comment "1 SSH sperren"
    iifname "v-lan" accept comment "2 LAN alles"'
test_http cl 10.8.2.2 22; test_http cl 10.8.2.2 80
step "4. Regeln pro Schnittstelle: Verkehr aus der DMZ ins LAN bleibt ohne Regel gesperrt (nur Antworten erlaubt)"
test_http srv 10.8.1.2 80
step "5. Block mit Protokollierung vs. Reject: Unterschied für den Client (Wartezeit bzw. sofortige Ablehnung)"
regeln '    iifname "v-lan" tcp dport 22 counter reject with tcp reset comment "1 SSH ablehnen"
    iifname "v-lan" tcp dport 8080 counter drop comment "2 8080 still verwerfen"
    iifname "v-lan" counter accept comment "3 LAN alles"'
echo "reject (RST):"; ( time on cl curl -s -m 3 -o /dev/null -w "rc=%{exitcode}\n" http://10.8.2.2:22/ ) 2>&1 | grep -E 'rc=|real' | tr '\n' ' '; echo
echo "drop (still):"; ( time on cl curl -s -m 3 -o /dev/null -w "rc=%{exitcode}\n" http://10.8.2.2:8080/ ) 2>&1 | grep -E 'rc=|real' | tr '\n' ' '; echo
step "6. Zähler je Regel (zeigen, welche Regel Pakete trifft)"
zaehler
lab_down

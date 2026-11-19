#!/usr/bin/env bash
# Lädt sets_maps.nft in den Server-Namespace, ändert die Sets zur Laufzeit und prüft die Wirkung.
. "$(dirname "$0")/../lab.sh"
cd "$(dirname "$0")"
lab_up
on srv nft -f sets_maps.nft
step "1. Ausgangslage: Port 80 über die Verdict-Map, Port 8080 über jump verwaltung"
http_get cl 10.0.2.2 80
http_get cl 10.0.2.2 8080
step "2. Client zur Laufzeit sperren (Set mit Timeout), danach Test"
cmd on srv nft add element inet filter gesperrt '{ 10.0.1.2 timeout 5m }'
cmd on srv nft list set inet filter gesperrt
http_get cl 10.0.2.2 80
step "3. Sperre wieder entfernen"
cmd on srv nft delete element inet filter gesperrt '{ 10.0.1.2 }'
http_get cl 10.0.2.2 80
step "4. Verkettung Adresse . Port: 8080 aus intern erlaubt, auch ohne Eintrag in freigaben"
cmd on srv nft delete element inet filter freigaben '{ 10.0.1.2 . 8080 }'
http_get cl 10.0.2.2 8080
step "5. Intern-Set ändern: Client-Netz entfernen -> jump verwaltung verwirft"
cmd on srv nft delete element inet filter intern '{ 10.0.1.0/24 }'
http_get cl 10.0.2.2 8080
step "6. Set und Map im Überblick"
on srv nft list sets
on srv nft list map inet filter dienste
lab_down

#!/usr/bin/env bash
# Lädt host_firewall.nft in den Server-Namespace und prüft sie vom Client (und von einer nicht erlaubten Adresse) aus.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
cd "$D"; lab_up
step "1. Regelwerk prüfen (nft -c) und laden"
cmd on srv nft -c -f host_firewall.nft && echo "Syntax ok"
on srv nft -f host_firewall.nft
step "2. Tests vom Client (10.0.1.2)"
ping_test cl 10.0.2.2
http_get cl 10.0.2.2 80
http_get cl 10.0.2.2 8080
step "3. Zweite Client-Adresse (10.0.9.2) darf Port 8080 nicht erreichen"
on cl ip addr add 10.0.9.2/24 dev v-cl
on fw ip route add 10.0.9.0/24 dev v-fw1
on srv ip route add 10.0.9.0/24 via 10.0.2.1
if on cl curl -s -m 2 --interface 10.0.9.2 -o /dev/null http://10.0.2.2:8080/; then echo "8080 von 10.0.9.2: OK (Fehler im Regelwerk)"; else echo "8080 von 10.0.9.2: BLOCKIERT"; fi
if on cl curl -s -m 2 --interface 10.0.9.2 -o /dev/null http://10.0.2.2:80/; then echo "80   von 10.0.9.2: OK"; else echo "80   von 10.0.9.2: BLOCKIERT"; fi
step "4. Zähler: was wurde verworfen?"
on srv nft list chain inet filter input
lab_down

#!/usr/bin/env bash
# Modul 3: Aliase. In OPNsense fasst ein Alias Hosts, Netze oder Ports unter einem Namen zusammen. Nachbildung: benannte nftables-Sets.
. "$(dirname "$0")/../lab.sh"
lab_up
step "1. Aliase als Sets: Web-Server (Hosts), Web-Ports (Ports), Verwaltungsnetz (Netz)"
on fw nft -f - <<'RS'
table inet fw {
  set alias_webserver { type ipv4_addr; elements = { 10.8.2.2 } }
  set alias_webports  { type inet_service; elements = { 80, 8080 } }
  set alias_verwaltung { type ipv4_addr; flags interval; elements = { 10.8.1.0/24 } }
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    ip saddr @alias_verwaltung ip daddr @alias_webserver tcp dport @alias_webports accept comment "LAN -> Web"
  }
}
RS
cmd on fw nft list sets
step "2. Die Regel verwendet nur die Namen; Test"
test_http cl 10.8.2.2 80; test_http cl 10.8.2.2 8080; test_http cl 10.8.2.2 22
step "3. Alias erweitern: Port 22 aufnehmen – die Regel bleibt unverändert"
cmd on fw nft add element inet fw alias_webports '{ 22 }'
test_http cl 10.8.2.2 22
step "4. Alias verkleinern: Port 8080 entfernen"
cmd on fw nft delete element inet fw alias_webports '{ 8080 }'
test_http cl 10.8.2.2 8080; test_http cl 10.8.2.2 80
step "5. Zweiter Server: nur ein Eintrag im Alias nötig (hier eine weitere Adresse 10.8.2.3 als Beispiel)"
cmd on fw nft add element inet fw alias_webserver '{ 10.8.2.3 }'
cmd on fw nft list set inet fw alias_webserver
step "6. Verschachtelte Aliase (ein Alias aus Aliasen) werden hier nicht nachgebildet: nftables kann Sets nicht ineinander einbetten (OPNsense kann es; nicht bestätigt)"
lab_down

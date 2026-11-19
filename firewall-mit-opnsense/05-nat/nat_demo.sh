#!/usr/bin/env bash
# Modul 5: NAT – ausgehend (Masquerade/SNAT), Portweiterleitung (DNAT), 1:1-NAT. Nachbildung mit nftables.
. "$(dirname "$0")/../lab.sh"
lab_up
on fw nft -f - <<'RS'
table inet fw {
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    iifname "v-lan" accept
    iifname "v-wan" ct status dnat accept comment "nur weitergeleitete Verbindungen"
  }
}
RS
step "1. Ohne NAT: LAN-Client erreicht das „Internet“ nicht (keine Rückroute im WAN-Netz)"
test_http cl 10.8.9.1 80
step "2. Ausgehendes NAT: Quelladresse wird die WAN-Adresse der Firewall"
on fw nft add table ip nat
on fw nft add chain ip nat post '{ type nat hook postrouting priority 100; }'
on fw nft add rule ip nat post oifname v-wan masquerade
test_http cl 10.8.9.1 80
echo "Verbindungstabelle der Firewall:"; on fw conntrack -L -p tcp 2>/dev/null | grep 10.8.9.1 | sed -E 's/sport=[0-9]+/sport=P/g; s/ id=[0-9]+//; s/^tcp +6 [0-9]+ [A-Z_]+ //' | head -1
step "3. Portweiterleitung: WAN-Seite Port 8080 → Server in der DMZ Port 80"
on fw nft add chain ip nat pre '{ type nat hook prerouting priority -100; }'
on fw nft add rule ip nat pre iifname v-wan tcp dport 8080 dnat to 10.8.2.2:80
cmd on wan curl -s -m 2 http://10.8.9.2:8080/
step "4. Ohne passende Filterregel wäre die Weiterleitung wirkungslos (ct status dnat entfernen)"
on fw nft flush chain inet fw forward
on fw nft add rule inet fw forward ct state established,related accept
on fw nft add rule inet fw forward iifname v-lan accept
cmd on wan curl -s -m 2 http://10.8.9.2:8080/ || true
step "5. Wieder erlauben, aber nur genau diese Weiterleitung"
on fw nft add rule inet fw forward iifname v-wan ip daddr 10.8.2.2 tcp dport 80 ct status dnat accept
cmd on wan curl -s -m 2 http://10.8.9.2:8080/
step "6. 1:1-NAT: externe Adresse 10.8.9.50 ↔ interner Server 10.8.2.2 (beide Richtungen)"
on fw ip addr add 10.8.9.50/24 dev v-wan
on fw nft add rule ip nat pre ip daddr 10.8.9.50 dnat to 10.8.2.2
on fw nft insert rule ip nat post ip saddr 10.8.2.2 oifname v-wan snat to 10.8.9.50   # vor der Masquerade-Regel: die Reihenfolge entscheidet
on fw nft add rule inet fw forward iifname v-dmz accept
on fw nft add rule inet fw forward iifname v-wan ip daddr 10.8.2.2 ct status dnat accept
cmd on wan curl -s -m 2 http://10.8.9.50:80/
cmd on srv curl -s -m 2 http://10.8.9.1:80/
step "7. Aktuelle NAT-Regeln"
on fw nft list table ip nat | sed -E 's/^\s+//'
lab_down

#!/usr/bin/env bash
# Zählt in allen fünf Netfilter-Hooks mit, welchen Weg Pakete nehmen (Firewall-Namespace).
. "$(dirname "$0")/../lab.sh"
lab_up
on fw nft -f - <<'RS'
table ip pfad {
  chain h_pre { type filter hook prerouting  priority 0; counter comment "prerouting"; }
  chain h_in  { type filter hook input       priority 0; counter comment "input"; }
  chain h_forward { type filter hook forward     priority 0; counter comment "forward"; }
  chain h_out { type filter hook output      priority 0; counter comment "output"; }
  chain h_post { type filter hook postrouting priority 0; counter comment "postrouting"; }
}
RS
zeige() { on fw nft list table ip pfad | grep -E 'comment' | sed -E 's/^\s+//' ; }
nullen() { on fw nft reset rules table ip pfad >/dev/null; }
step "1. Paket durch die Firewall (Client -> Server): prerouting, forward, postrouting"
nullen; on cl ping -c1 -W1 10.0.2.2 >/dev/null; zeige
step "2. Paket an die Firewall (Client -> 10.0.1.1): prerouting, input"
nullen; on cl ping -c1 -W1 10.0.1.1 >/dev/null; zeige
step "3. Paket von der Firewall selbst (Firewall -> Server): output, postrouting"
nullen; on fw ping -c1 -W1 10.0.2.2 >/dev/null; zeige
step "4. Hooks und Prioritäten der Kette"
on fw nft list chains
lab_down

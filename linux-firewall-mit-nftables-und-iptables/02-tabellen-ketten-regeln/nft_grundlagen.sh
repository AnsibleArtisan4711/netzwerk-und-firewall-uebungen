#!/usr/bin/env bash
# Tabellen, Ketten und Regeln mit nft anlegen, einfügen, mit Handle löschen, Familien und Sprungziele zeigen.
. "$(dirname "$0")/../lab.sh"
lab_up
step "1. Tabelle und Basis-Kette anlegen (Familie inet gilt für IPv4 und IPv6)"
cmd on fw nft add table inet demo
cmd on fw nft 'add chain inet demo input { type filter hook input priority 0 ; policy accept ; }'
step "2. Regeln anhängen (add) und vorn einfügen (insert)"
cmd on fw nft add rule inet demo input tcp dport 22 counter accept
cmd on fw nft add rule inet demo input tcp dport 23 counter drop
cmd on fw nft insert rule inet demo input iif lo accept
cmd on fw nft -a list table inet demo
step "3. Regel anhand des Handles löschen (Handle der Regel für Port 23 ermitteln)"
H=$(on fw nft -a list chain inet demo input | awk '/dport 23/ {print $NF}')
cmd on fw nft delete rule inet demo input handle $H
cmd on fw nft list chain inet demo input
step "4. Reguläre Kette und jump"
cmd on fw nft add chain inet demo web
cmd on fw nft add rule inet demo web tcp dport "{ 80, 443 }" counter accept
cmd on fw nft add rule inet demo input jump web
cmd on fw nft list table inet demo
step "5. Familien: ip, ip6, inet, arp, bridge, netdev (nur Auflistung, keine Ausführung)"
cmd on fw nft add table ip v4only
cmd on fw nft add table ip6 v6only
cmd on fw nft list tables
step "6. Aufräumen: eine Kette, auf die noch ein jump zeigt, lässt sich nicht löschen"
cmd on fw nft delete chain inet demo web
cmd on fw nft flush chain inet demo web
cmd on fw nft delete rule inet demo input handle $(on fw nft -a list chain inet demo input | awk '/jump web/ {print $NF}')
cmd on fw nft delete chain inet demo web
cmd on fw nft delete table inet demo
cmd on fw nft list tables
lab_down

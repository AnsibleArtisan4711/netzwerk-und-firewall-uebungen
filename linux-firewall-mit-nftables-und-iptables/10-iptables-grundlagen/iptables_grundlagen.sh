#!/usr/bin/env bash
# iptables-Grundlagen: Ketten, Regeln, Zähler, conntrack-Modul; Verhältnis zu nftables (iptables-nft).
. "$(dirname "$0")/../lab.sh"
lab_up
step "1. Welche iptables-Variante ist installiert?"
cmd iptables --version
cmd ip6tables --version
step "2. Standard-Richtlinie auf DROP, dann erlauben (Server-Namespace)"
cmd on srv iptables -P INPUT DROP
cmd on srv iptables -A INPUT -i lo -j ACCEPT
cmd on srv iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
cmd on srv iptables -A INPUT -p tcp --dport 80 -j ACCEPT
cmd on srv iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/second -j ACCEPT
http_get cl 10.0.2.2 80; http_get cl 10.0.2.2 8080; ping_test cl 10.0.2.2
step "3. Regeln mit Zählern und Nummern anzeigen (-L -n -v --line-numbers)"
cmd on srv iptables -L INPUT -n -v --line-numbers
step "4. Regel einfügen (-I), ersetzen (-R) und löschen (-D)"
cmd on srv iptables -I INPUT 3 -p tcp --dport 8080 -s 10.0.1.0/24 -j ACCEPT
http_get cl 10.0.2.2 8080
cmd on srv iptables -R INPUT 3 -p tcp --dport 8080 -s 10.0.9.0/24 -j ACCEPT
http_get cl 10.0.2.2 8080
cmd on srv iptables -D INPUT 3
cmd on srv iptables -S INPUT
step "5. NAT-Tabelle und forward in der Firewall mit iptables"
cmd on fw iptables -t nat -A POSTROUTING -o v-fw2 -j MASQUERADE
cmd on fw iptables -P FORWARD DROP
cmd on fw iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
cmd on fw iptables -A FORWARD -i v-fw1 -o v-fw2 -p tcp --dport 80 -j ACCEPT
http_get cl 10.0.2.2 80; http_get cl 10.0.2.2 8080
cmd on fw iptables -t nat -L -n -v
step "6. Dieselben Regeln aus Sicht von nft: iptables-nft legt Tabellen im nf_tables-Kern an"
on fw nft list ruleset | head -30
lab_down

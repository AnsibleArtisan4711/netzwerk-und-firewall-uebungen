#!/usr/bin/env bash
# lab.sh – Testlabor für P08: vier Netzwerk-Namespaces, die Firewall wird mit Linux-nftables NACHGEBILDET
#
#   cl (LAN 10.8.1.2) --- fw ---+--- srv (DMZ 10.8.2.2)
#                               +--- wan (WAN-Seite 10.8.9.1, „Internet“; kennt kein Netz 10.8.1.0/24)
#   fw: LAN 10.8.1.1 (v-lan), DMZ 10.8.2.1 (v-dmz), WAN 10.8.9.2 (v-wan)
#
# WICHTIG: OPNsense (FreeBSD, pf) läuft hier NICHT. Die Skripte zeigen die Logik (Regelreihenfolge, NAT, Aliase,
# DHCP/DNS, IDS, Hochverfügbarkeit) mit Linux-Werkzeugen. Menüs, Dateien und Befehle von OPNsense sind nicht ausgeführt.
# Benötigt root, ip, nft, python3, curl. Namespaces mit Präfix p08- werden in lab_down wieder entfernt.

P=p08
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

on() { local ns=$1; shift; ip netns exec "$P-$ns" "$@"; }
cmd() { echo "\$ $*"; "$@" 2>&1; return $?; }
step() { echo; echo "## $*"; }

lab_down() {
  { for n in cl fw srv wan fw2 sw sw2; do ip netns pids "$P-$n" 2>/dev/null | xargs -r kill >/dev/null 2>&1; ip netns del "$P-$n" 2>/dev/null; done; } 2>/dev/null
  wait 2>/dev/null
  return 0
}

lab_up() {
  lab_down
  for n in cl fw srv wan; do ip netns add "$P-$n"; on $n ip link set lo up; done
  mk() { # mk NS_A IF_A NS_B IF_B
    ip link add "$2" type veth peer name "$4"; ip link set "$2" netns "$P-$1"; ip link set "$4" netns "$P-$3"; }
  mk cl v-cl fw v-lan; mk srv v-srv fw v-dmz; mk wan v-wan0 fw v-wan
  on cl ip addr add 10.8.1.2/24 dev v-cl; on cl ip link set v-cl up; on cl ip route add default via 10.8.1.1
  on srv ip addr add 10.8.2.2/24 dev v-srv; on srv ip link set v-srv up; on srv ip route add default via 10.8.2.1
  on wan ip addr add 10.8.9.1/24 dev v-wan0; on wan ip link set v-wan0 up   # keine Route in die internen Netze
  on fw ip addr add 10.8.1.1/24 dev v-lan; on fw ip addr add 10.8.2.1/24 dev v-dmz; on fw ip addr add 10.8.9.2/24 dev v-wan
  for i in v-lan v-dmz v-wan; do on fw ip link set $i up; done
  on fw ip route add default via 10.8.9.1
  on fw sysctl -qw net.ipv4.ip_forward=1
  for t in "srv 80" "srv 8080" "srv 22" "wan 80"; do set -- $t
    ( setsid ip netns exec "$P-$1" python3 "$HERE/echo_server.py" "$1" "$2" >/dev/null 2>&1 < /dev/null & ); done
  sleep 0.7
}

# test <ns> <ziel> [port] [text]  → eine Zeile mit Ergebnis
test_http() { local ns=$1 ip=$2 port=${3:-80}; local o
  if o=$(on "$ns" curl -s -m 2 "http://$ip:$port/"); then echo "http $ip:$port: $o"; else echo "http $ip:$port: keine Antwort"; fi; }
test_ping() { if on "$1" ping -c1 -W1 "$2" >/dev/null 2>&1; then echo "ping $2: OK"; else echo "ping $2: keine Antwort"; fi; }

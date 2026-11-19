#!/usr/bin/env bash
# lab.sh – Testlabor aus drei Netzwerk-Namespaces: Client – Firewall – Server
#
#   cl (10.0.1.2/24) --- fw (10.0.1.1/24 | 10.0.2.1/24) --- srv (10.0.2.2/24)
#
# Nutzung in den Modulskripten:  . "$(dirname "$0")/../lab.sh"; lab_up ... lab_down
# Benötigt root (oder CAP_NET_ADMIN), ip, nft, python3.
# Nur im Testlabor ausführen: Das Skript legt Namespaces mit dem Präfix p09- an
# und entfernt sie in lab_down wieder; die Firewall des Hosts bleibt unberührt.

P=p09
NS_CL=$P-cl; NS_FW=$P-fw; NS_SRV=$P-srv

on() { local ns=$1; shift; ip netns exec "$P-$ns" "$@"; }       # on fw nft list ruleset
cmd() { echo "\$ $*"; "$@" 2>&1; local rc=$?; return $rc; }       # Befehl anzeigen und ausführen
step() { echo; echo "## $*"; }                                    # Überschrift in der Ausgabe

lab_down() {
  { for n in cl fw srv; do ip netns pids "$P-$n" 2>/dev/null | xargs -r kill >/dev/null 2>&1; ip netns del "$P-$n" 2>/dev/null; done; } 2>/dev/null
  wait 2>/dev/null
  return 0
}

lab_up() {
  lab_down
  for n in cl fw srv; do ip netns add "$P-$n"; on $n ip link set lo up; done
  ip link add v-cl type veth peer name v-fw1; ip link set v-cl netns $NS_CL; ip link set v-fw1 netns $NS_FW
  ip link add v-srv type veth peer name v-fw2; ip link set v-srv netns $NS_SRV; ip link set v-fw2 netns $NS_FW
  on cl ip addr add 10.0.1.2/24 dev v-cl;  on cl ip link set v-cl up;  on cl ip route add default via 10.0.1.1
  on srv ip addr add 10.0.2.2/24 dev v-srv; on srv ip link set v-srv up; on srv ip route add default via 10.0.2.1
  on fw ip addr add 10.0.1.1/24 dev v-fw1; on fw ip addr add 10.0.2.1/24 dev v-fw2
  on fw ip link set v-fw1 up; on fw ip link set v-fw2 up
  on fw sysctl -qw net.ipv4.ip_forward=1
  # Dienste im Server: HTTP (80), zweiter Port (8080), UDP-Echo (5353)
  mkdir -p /tmp/$P-www && echo "hallo vom server" > /tmp/$P-www/index.html
  ( cd /tmp/$P-www && setsid ip netns exec $NS_SRV python3 -m http.server 80 --bind 0.0.0.0 >/dev/null 2>&1 < /dev/null & )
  ( cd /tmp/$P-www && setsid ip netns exec $NS_SRV python3 -m http.server 8080 --bind 0.0.0.0 >/dev/null 2>&1 < /dev/null & )
  sleep 0.7
}

# Hilfsfunktionen für Tests: http_get <ns> <ziel> [port]  → Ausgabe "OK"/"BLOCKIERT"
http_get() {
  local ns=$1 ip=$2 port=${3:-80}
  if on "$ns" curl -s -m 2 -o /dev/null "http://$ip:$port/"; then echo "http $ip:$port: OK"; else echo "http $ip:$port: BLOCKIERT/keine Antwort"; fi
}
ping_test() {
  local ns=$1 ip=$2
  if on "$ns" ping -c1 -W1 "$ip" >/dev/null 2>&1; then echo "ping $ip: OK"; else echo "ping $ip: keine Antwort"; fi
}

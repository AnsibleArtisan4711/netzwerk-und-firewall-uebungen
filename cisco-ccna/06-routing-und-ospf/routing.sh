#!/usr/bin/env bash
# Modul 6: Routing-Grundlagen, statische Routen und OSPF. Echte Linux-Router (Namensräume), OSPFv2 mit FRR (zebra, ospfd). OSPFv3 und IPv6 sind nicht ausgeführt; Cisco-IOS-Befehle stehen nur in den Aufgaben.
. "$(dirname "$0")/../lab.sh"
lab_up
vt() { ip netns exec $1 vtysh --vty_socket $W/$1 "${@:2}" 2>&1; }; export W; export -f vt
frr() { # frr NS ROUTER-ID KONFIG-TEXT: zebra und ospfd im Namensraum starten
  mkdir -p $W/$1; chmod 777 $W/$1
  printf 'hostname %s\nlog file %s/frr.log\n%s\n' "$1" "$W/$1" "$3" > $W/$1/frr.conf
  for d in zebra ospfd; do ip netns exec $1 /usr/lib/frr/$d -d -f $W/$1/frr.conf -i $W/$1/$d.pid -z $W/$1/zserv.api --vty_socket $W/$1 -u frr -g frr >/dev/null 2>&1; done
}
chain() { ns_up $1 $2 $3; link $1 $4 $2 $5; link $2 $6 $3 $7; }
step "A1. Statische Routen: Kette R1 - R2 - R3, je ein LAN an R1 (192.168.1.0/24) und R3 (192.168.3.0/24)"
chain ccr1 ccr2 ccr3 e12 e21 e23 e32
ip -n ccr1 addr add 10.0.12.1/30 dev e12; ip -n ccr2 addr add 10.0.12.2/30 dev e21; ip -n ccr2 addr add 10.0.23.1/30 dev e23; ip -n ccr3 addr add 10.0.23.2/30 dev e32
ip -n ccr1 addr add 192.168.1.1/24 dev lo; ip -n ccr3 addr add 192.168.3.1/24 dev lo; fwd ccr1 ccr2 ccr3
echo "--- ohne Routen: R1 kennt das LAN von R3 nicht"
run "ip netns exec ccr1 ping -c1 -W1 -I 192.168.1.1 192.168.3.1 2>&1 | grep -E 'unreachable|Unreachable|transmitted'"
ip -n ccr1 route add 192.168.3.0/24 via 10.0.12.2; ip -n ccr1 route add 10.0.23.0/30 via 10.0.12.2
echo "--- nur R1 konfiguriert: R2 kennt das Zielnetz nicht und verwirft das Paket"
run "ip netns exec ccr1 ping -c1 -W1 -I 192.168.1.1 192.168.3.1 2>&1 | grep -E 'unreachable|Unreachable|transmitted'"
ip -n ccr2 route add 192.168.3.0/24 via 10.0.23.2
echo "--- Hinweg bis R3 vorhanden, aber R3 kennt den Rückweg nicht: die Anfrage kommt an, die Antwort geht verloren"
run "ip netns exec ccr1 ping -c1 -W1 -I 192.168.1.1 192.168.3.1 2>&1 | grep -E 'unreachable|Unreachable|transmitted'"
ip -n ccr2 route add 192.168.1.0/24 via 10.0.12.1
ip -n ccr3 route add 192.168.1.0/24 via 10.0.23.1; ip -n ccr3 route add 10.0.12.0/30 via 10.0.23.1
echo "--- Hin- und Rückweg konfiguriert"
run "ip netns exec ccr1 ping -c1 -W1 -I 192.168.1.1 192.168.3.1 | grep -E 'transmitted'"
run "ip netns exec ccr1 traceroute -n -q1 -w1 -s 192.168.1.1 192.168.3.1 | sed 's/ms.*/ms/'"
run "ip -n ccr1 route | grep -v 'dev lo'"
step "A2. Längster Präfix gewinnt: eine Sperrroute für ein Teilnetz (prohibit) übersteuert die allgemeine Route"
ip -n ccr1 route add prohibit 192.168.3.128/25
run "ip -n ccr1 route get 192.168.3.5 2>&1 | head -1 | cut -c1-70"
run "ip -n ccr1 route get 192.168.3.200 2>&1 | head -1"
run "ip netns exec ccr1 ping -c1 -W1 -I 192.168.1.1 192.168.3.200 2>&1 | grep -v '^$' | head -3"
echo "Die Sperrroute /25 ist länger (spezifischer) als die Route /24 und gewinnt für 192.168.3.128 bis .255; der Rest von /24 bleibt erreichbar."
ip -n ccr1 route del prohibit 192.168.3.128/25
step "A3. Floating Static Route: Standardweg mit Metrik 10, Ersatzweg mit Metrik 200 (eigene Topologie P1 - P3 direkt, Umweg über PB)"
ns_up ccp1 ccp3 ccpb; link ccp1 p13 ccp3 p31; link ccp1 p1b ccpb pb1; link ccp3 p3b ccpb pb3
ip -n ccp1 addr add 10.1.13.1/30 dev p13; ip -n ccp3 addr add 10.1.13.2/30 dev p31
ip -n ccp1 addr add 10.1.1.1/30 dev p1b; ip -n ccpb addr add 10.1.1.2/30 dev pb1; ip -n ccp3 addr add 10.1.3.1/30 dev p3b; ip -n ccpb addr add 10.1.3.2/30 dev pb3
ip -n ccp1 addr add 192.168.10.1/24 dev lo; ip -n ccp3 addr add 192.168.30.1/24 dev lo; fwd ccp1 ccp3 ccpb
ip -n ccp1 route add 192.168.30.0/24 via 10.1.13.2 metric 10; ip -n ccp1 route add 192.168.30.0/24 via 10.1.1.2 metric 200
ip -n ccp3 route add 192.168.10.0/24 via 10.1.13.1 metric 10; ip -n ccp3 route add 192.168.10.0/24 via 10.1.3.2 metric 200
ip -n ccpb route add 192.168.30.0/24 via 10.1.3.1; ip -n ccpb route add 192.168.10.0/24 via 10.1.1.1
run "ip -n ccp1 route show 192.168.30.0/24"
run "ip netns exec ccp1 traceroute -I -n -q1 -w1 -s 192.168.10.1 192.168.30.1 | sed 's/ms.*/ms/'"
echo "--- direkte Verbindung fällt aus"
ip -n ccp1 link set p13 down; sleep 1.2
run "ip -n ccp1 route show 192.168.30.0/24"
run "ip netns exec ccp1 traceroute -I -n -q1 -w1 -s 192.168.10.1 192.168.30.1 | sed 's/ms.*/ms/'"
ip -n ccp1 link set p13 up
step "B1. OSPFv2 (FRR): Dreieck R1-R2-R3, Punkt-zu-Punkt, Hello 1 s / Dead 4 s (verkürzt für das Labor), Kosten fest 10"
for r in ccq1 ccq2 ccq3; do ns_up $r; done
link ccq1 q12 ccq2 q21; link ccq2 q23 ccq3 q32; link ccq1 q13 ccq3 q31
ip -n ccq1 addr add 10.2.12.1/30 dev q12; ip -n ccq2 addr add 10.2.12.2/30 dev q21; ip -n ccq2 addr add 10.2.23.1/30 dev q23; ip -n ccq3 addr add 10.2.23.2/30 dev q32; ip -n ccq1 addr add 10.2.13.1/30 dev q13; ip -n ccq3 addr add 10.2.13.2/30 dev q31
ip -n ccq1 link add lan1 type veth peer name h1; ip -n ccq1 addr add 192.168.1.1/24 dev lan1; ip -n ccq1 link set lan1 up; ip -n ccq1 link set h1 up
ip -n ccq3 link add lan3 type veth peer name h3; ip -n ccq3 addr add 192.168.3.1/24 dev lan3; ip -n ccq3 link set lan3 up; ip -n ccq3 link set h3 up; fwd ccq1 ccq2 ccq3
oi() { printf 'interface %s\n ip ospf network point-to-point\n ip ospf hello-interval 1\n ip ospf dead-interval 4\n ip ospf cost 10\n' "$1"; }
frr ccq1 1.1.1.1 "$(oi q12; oi q13)
router ospf
 ospf router-id 1.1.1.1
 network 10.2.12.0/30 area 0
 network 10.2.13.0/30 area 0
 network 192.168.1.0/24 area 0
 passive-interface lan1"
frr ccq2 2.2.2.2 "$(oi q21; oi q23)
router ospf
 ospf router-id 2.2.2.2
 network 10.2.12.0/30 area 0
 network 10.2.23.0/30 area 0"
frr ccq3 3.3.3.3 "$(oi q32; oi q31)
router ospf
 ospf router-id 3.3.3.3
 network 10.2.23.0/30 area 0
 network 10.2.13.0/30 area 0
 network 192.168.3.0/24 area 0
 passive-interface lan3"
sleep 14
run "vt ccq1 -c 'show ip ospf neighbor' | awk '\$1 ~ /^[0-9]/ {print \"Nachbar \" \$1, \"Zustand \" \$3, \"Adresse \" \$6, \"Anschluss \" \$7}'"
run "vt ccq1 -c 'show ip route ospf' | grep -E '^O' | sed -E 's/, weight [0-9]+//; s/, [0-9:]+$//'"
run "ip netns exec ccq1 ping -c1 -W1 -I 192.168.1.1 192.168.3.1 | grep transmitted"
echo "--- Kosten auf der direkten Verbindung R1-R3 (R1-Seite) auf 100 setzen: der Weg über R2 (Summe 30) wird billiger als direkt (100)"
vt ccq1 -c 'configure terminal' -c 'interface q13' -c 'ip ospf cost 100' >/dev/null; sleep 3
run "vt ccq1 -c 'show ip route ospf' | grep -E '^O.*192.168.3.0' | sed -E 's/, weight [0-9]+//; s/, [0-9:]+$//'"
run "ip netns exec ccq1 traceroute -n -q1 -w1 -s 192.168.1.1 192.168.3.1 | sed 's/ms.*/ms/'"
echo "--- Hello-Timer auf R1 (Verbindung zu R2) auf 3 s ändern, Dead 12 s: stimmt nicht mit R2 überein, die Nachbarschaft bricht ab"
vt ccq1 -c 'configure terminal' -c 'interface q12' -c 'ip ospf hello-interval 3' -c 'ip ospf dead-interval 12' >/dev/null; sleep 7
run "vt ccq1 -c 'show ip ospf neighbor' | awk '\$1 ~ /^[0-9]/ {print \"Nachbar \" \$1, \"Zustand \" \$3, \"Anschluss \" \$7}'"
run "grep -ciE 'hello.*mismatch|mismatch' $W/ccq2/frr.log | sed 's/^/Meldungen zu abweichenden Timern im Protokoll von R2: /'"
pkill -f /usr/lib/frr/; sleep 1
step "B2. Broadcast-Segment: Wahl von DR und BDR bei Prioritäten 200, 100, 1"
for r in ccd1 ccd2 ccd3 ccdb; do ns_up $r; done
ip -n ccdb link add br0 type bridge stp_state 0; ip -n ccdb link set br0 up
for i in 1 2 3; do link ccd$i d$i ccdb s$i; ip -n ccdb link set s$i master br0; ip -n ccd$i addr add 10.3.0.$i/24 dev d$i; done
ob() { printf 'interface %s\n ip ospf priority %s\n ip ospf hello-interval 1\n ip ospf dead-interval 4\n' "$1" "$2"; }
frr ccd1 1.1.1.1 "$(ob d1 200)
router ospf
 ospf router-id 1.1.1.1
 network 10.3.0.0/24 area 0"
frr ccd2 2.2.2.2 "$(ob d2 100)
router ospf
 ospf router-id 2.2.2.2
 network 10.3.0.0/24 area 0"
frr ccd3 3.3.3.3 "$(ob d3 1)
router ospf
 ospf router-id 3.3.3.3
 network 10.3.0.0/24 area 0"
sleep 18
for r in ccd1 ccd2 ccd3; do echo "\$ vt $r show ip ospf neighbor (gekürzt)"; vt $r -c "show ip ospf neighbor" | awk -v r=$r '$1 ~ /^[0-9]/ {split($3, z, "/"); print "  " r ": Nachbar " $1 ", Priorität " $2 ", Zustand " z[1] ", Rolle des Nachbarn " z[2]}'; done
run "vt ccd1 -c 'show ip ospf interface d1' | grep -E 'State|Priority' | head -2"
echo "--- DR (R1) fällt aus: BDR (R2) wird DR; R1 kommt später zurück und wird nicht erneut DR (kein Preemption)"
ip -n ccd1 link set d1 down; sleep 8
run "vt ccd2 -c 'show ip ospf interface d2' | grep -E 'State' | head -1"
ip -n ccd1 link set d1 up; sleep 10
run "vt ccd1 -c 'show ip ospf interface d1' | grep -E 'State' | head -1"
pkill -f /usr/lib/frr/; sleep 1
step "C. Auswahl der Route (Python-Modell): längster Präfix vor Administrative Distance vor Metrik (Lehrbuchwissen)"
python3 - <<'PY'
import ipaddress as ip
ad = {'verbunden': 0, 'statisch': 1, 'eBGP': 20, 'OSPF': 110, 'RIP': 120}
rib = [('192.168.3.0/24', 'OSPF', 20), ('192.168.3.0/24', 'statisch', 0), ('192.168.3.128/25', 'OSPF', 40), ('10.0.0.0/8', 'RIP', 2), ('0.0.0.0/0', 'statisch', 0)]
def suche(z):
    t = [r for r in rib if ip.ip_address(z) in ip.ip_network(r[0])]
    t.sort(key=lambda r: (-ip.ip_network(r[0]).prefixlen, ad[r[1]], r[2])); return t[0]
for z in ['192.168.3.9', '192.168.3.200', '10.9.9.9', '8.8.8.8']: print('%-14s -> %s' % (z, suche(z)))
print('Administrative Distance (Lehrbuchwissen, Cisco-Standardwerte nicht im Container geprüft):', ad)
print('Nicht ausgeführt: OSPFv3 und IPv6-Routing, EIGRP, BGP, IOS-Befehle (ip route, router ospf, show ip route).')
PY

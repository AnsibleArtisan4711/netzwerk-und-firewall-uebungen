#!/usr/bin/env bash
# Modul 10 (Priorität 2): Hochverfügbarkeit. OPNsense verwendet CARP und pfsync (FreeBSD); beides ist im Labor NICHT verfügbar.
# Als Stand-in dient VRRP mit keepalived 2.2.8: gleiche Idee (virtuelle Adresse, Master/Backup), anderes Protokoll und andere Konfiguration.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_down
for n in cl fw fw2 srv sw sw2; do ip netns add p08-$n; on $n ip link set lo up; done
link() { ip link add "$2" type veth peer name "$4"; ip link set "$2" netns p08-$1; ip link set "$4" netns p08-$3; on $1 ip link set "$2" up; on $3 ip link set "$4" up; }
# Switch sw (LAN) und sw2 (DMZ) als Linux-Bridges
on sw ip link add br0 type bridge; on sw2 ip link add br0 type bridge; on sw ip link set br0 up; on sw2 ip link set br0 up
for x in "cl v-cl sw p-cl" "fw v-lan sw p-fw" "fw2 v-lan sw p-fw2"; do set -- $x; link $1 $2 $3 $4; on sw ip link set $4 master br0; done
for x in "srv v-srv sw2 p-srv" "fw v-dmz sw2 p-fw" "fw2 v-dmz sw2 p-fw2"; do set -- $x; link $1 $2 $3 $4; on sw2 ip link set $4 master br0; done
on cl ip addr add 10.8.1.2/24 dev v-cl; on cl ip route add default via 10.8.1.254
on srv ip addr add 10.8.2.2/24 dev v-srv; on srv ip route add default via 10.8.2.254
on fw ip addr add 10.8.1.11/24 dev v-lan; on fw ip addr add 10.8.2.11/24 dev v-dmz
on fw2 ip addr add 10.8.1.12/24 dev v-lan; on fw2 ip addr add 10.8.2.12/24 dev v-dmz
for f in fw fw2; do on $f sysctl -qw net.ipv4.ip_forward=1; done
( setsid ip netns exec p08-srv python3 "$D/../echo_server.py" srv 80 >/dev/null 2>&1 < /dev/null & ); sleep 0.5
start_ka() { # start_ka NS PRIO
  sed "s/@PRIO@/$2/" "$D/keepalived.conf.vorlage" > /tmp/p08-ka-$1.conf
  ( setsid ip netns exec p08-$1 keepalived --vrrp -f /tmp/p08-ka-$1.conf -p /tmp/p08-ka-$1.pid -r /tmp/p08-kar-$1.pid -n -l >/tmp/p08-ka-$1.log 2>&1 < /dev/null & ); }
vip() { for f in fw fw2; do on $f ip -4 -o addr show | awk -v n=$f '/\.254\//{print n": "$2" hält "$4; g=1} END{if(!g) print n": hält keine virtuelle Adresse"}'; done; }
for f in fw fw2; do on $f nft -f - <<'RS'
table inet fw {
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    iifname "v-lan" accept
  }
}
RS
done
step "1. Zwei Firewalls mit je eigener Adresse (.11 und .12) und eine gemeinsame virtuelle Adresse (.254) für Clients und Server"
test_ping cl 10.8.1.254
step "2. keepalived starten: fw mit Priorität 150, fw2 mit Priorität 100"
start_ka fw 150; sleep 1; start_ka fw2 100; sleep 5
vip
step "3. Verkehr über die virtuelle Adresse als Gateway: Client → Server (ohne NAT)"
test_http cl 10.8.2.2 80
cmd on cl ip route get 10.8.2.2
echo "Zustandstabelle nach dem Test (Einträge zu 10.8.2.2):"
for f in fw fw2; do echo "  $f: $(on $f conntrack -L 2>/dev/null | grep -c 10.8.2.2)"; done
step "4. Master fällt aus (keepalived von fw wird beendet): das Backup übernimmt"
kill $(cat /tmp/p08-ka-fw.pid) 2>/dev/null
T0=$(date +%s.%N); N=0
until on cl ping -c1 -W1 10.8.1.254 >/dev/null 2>&1 && [ -n "$(on fw2 ip -br addr show | grep '10.8.1.254')" ]; do sleep 0.3; N=$((N+1)); [ $N -gt 40 ] && break; done
sleep 1
echo "Übernahme nach etwa $(printf '%.0f' "$(echo "$(date +%s.%N) - $T0" | bc)") Sekunden (advert_int 1; Wert schwankt)"
vip
test_http cl 10.8.2.2 80
step "5. Alter Master kehrt zurück: wegen höherer Priorität übernimmt er wieder (Preempt ist Standard)"
start_ka fw 150; sleep 6
vip
step "6. Grenze: Zustände werden nicht abgeglichen (pfsync-Ersatz fehlt); nach dem Wechsel kennt fw2 nur Verbindungen, die seit der Übernahme über ihn liefen"
for f in fw fw2; do echo "  $f: $(on $f conntrack -L 2>/dev/null | grep -c 10.8.2.2) Einträge zu 10.8.2.2"; done
echo "(Ob eine laufende TCP-Verbindung den Wechsel überlebt, wurde hier nicht geprüft; es hängt von der Zustandsverfolgung ab.)"
for f in fw fw2; do kill $(cat /tmp/p08-ka-$f.pid) $(cat /tmp/p08-kar-$f.pid) 2>/dev/null; done
rm -f /tmp/p08-ka-* /tmp/p08-kar-*
lab_down

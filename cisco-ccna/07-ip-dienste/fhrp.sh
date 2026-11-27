#!/usr/bin/env bash
# Modul 7c: First Hop Redundancy mit VRRP (keepalived). HSRP und GLBP sind Cisco-Verfahren und hier nur als Text beschrieben; VRRP ist der herstellerneutrale Standard mit derselben Idee.
. "$(dirname "$0")/../lab.sh"
lab_up
ns_up ccf1 ccf2 ccfc ccfsw
link ccf1 f1 ccfsw s1; link ccf2 f2 ccfsw s2; link ccfc fc ccfsw s3
ip -n ccfsw link add br0 type bridge stp_state 0; for p in s1 s2 s3; do ip -n ccfsw link set $p master br0; done; ip -n ccfsw link set br0 up
ip -n ccf1 addr add 192.168.10.2/24 dev f1; ip -n ccf2 addr add 192.168.10.3/24 dev f2; ip -n ccfc addr add 192.168.10.100/24 dev fc
for r in ccf1 ccf2; do ip netns exec $r sysctl -qw net.ipv4.conf.all.arp_ignore=1 net.ipv4.conf.all.arp_announce=2; done
mkdir -p k1 k2; chmod 777 k1 k2
vconf() { cat <<C
global_defs {
  vrrp_garp_master_delay 1
}
vrrp_instance LAN {
  state BACKUP
  interface $1
  virtual_router_id 10
  priority $2
  advert_int 1
  use_vmac
  vmac_xmit_base
  virtual_ipaddress {
    192.168.10.1/24
  }
}
C
}
vconf f1 110 > k1/k.conf; vconf f2 90 > k2/k.conf
(ip netns exec ccf1 keepalived -n -l --vrrp -f $W/k1/k.conf -p $W/k1/k.pid -r $W/k1/v.pid >$W/k1/k.log 2>&1 &)
(ip netns exec ccf2 keepalived -n -l --vrrp -f $W/k2/k.conf -p $W/k2/k.pid -r $W/k2/v.pid >$W/k2/k.log 2>&1 &)
step "1. Wahl des Masters: R1 (Priorität 110) gegen R2 (Priorität 90), virtuelle Adresse 192.168.10.1"
sleep 6
for r in ccf1 ccf2; do run "ip -n $r -br addr | grep -E 'vrrp' | awk '{print \"$r\", \$1, \$3}'"; done
echo "(Wer die virtuelle Adresse trägt, ist Master; der andere Router hält sie nicht.)"
run "ip netns exec ccfc ping -c1 -W1 192.168.10.1 | grep -E 'transmitted'"
run "ip netns exec ccfc ip neigh show 192.168.10.1 | awk '{print \$1, \$5}'"
echo "Die MAC-Adresse 00:00:5e:00:01:0a ist die virtuelle MAC von VRRP (00:00:5e:00:01:VRID, hier VRID 10 = 0x0a); sie bleibt beim Wechsel gleich, der Client muss seinen ARP-Eintrag nicht ändern."
step "2. Meldungen im Mitschnitt: VRRP-Advertisements gehen an die Multicast-Adresse 224.0.0.18"
(ip netns exec ccfc timeout 4 tcpdump -Z root -U -n -i fc -w vrrp.pcap "ip proto 112" >/dev/null 2>&1 &); sleep 5
run "tshark -r vrrp.pcap -T fields -e ip.src -e ip.dst -e vrrp.prio -e vrrp.adver_int 2>/dev/null | sort -u | awk -F'\\t' '{print \$1 \" -> \" \$2 \"  Priorität \" \$3 \"  Intervall \" \$4 \" s\"}'"
step "3. Ausfall des Masters: R1 verliert den Link, R2 übernimmt; Messung mit ping alle 0,2 s"
(ip netns exec ccfc timeout -s INT 18 ping -D -i 0.2 -W1 192.168.10.1 > ping.txt 2>&1 &); sleep 3
T0=$(date +%s.%N); ip -n ccf1 link set f1 down; sleep 12
run "ip -n ccf2 -br addr | grep vrrp | awk '{print \"ccf2\", \$1, \$3}'"
sleep 4
python3 - $T0 <<'PY'
import re, sys
t0 = float(sys.argv[1]); ts = [float(m.group(1)) for m in re.finditer(r'^\[(\d+\.\d+)\].*bytes from', open('ping.txt').read(), re.M)]
vor = [t for t in ts if t < t0]; nach = [t for t in ts if t > t0]
luecke = max(b - a for a, b in zip(ts, ts[1:])) if len(ts) > 1 else 0
print('Antworten vor dem Ausfall: %d, danach: %d; größte Lücke zwischen zwei Antworten: %.1f s (rund %d Pings mit 0,2 s)' % (len(vor), len(nach), luecke, round(luecke / 0.2) - 1))
PY
echo "Die Umschaltzeit entspricht etwa drei Advertisement-Intervallen plus Versatz (Master-Down-Intervall), bei einem Intervall von 1 s also rund 3 bis 4 s."
step "4. Rückkehr des alten Masters: bei aktiver Preemption übernimmt der Router mit der höheren Priorität wieder"
ip -n ccf1 link set f1 up; sleep 6
run "ip -n ccf1 -br addr | grep vrrp | awk '{print \"ccf1\", \$1, \$3}'"
run "ip -n ccf2 -br addr | grep vrrp | awk '{print \"ccf2\", \$1, \$3}'"
echo "HSRP (Cisco): Active/Standby, virtuelle MAC 0000.0c07.acXX (XX = Gruppe), Multicast 224.0.0.2 (v1) bzw. 224.0.0.102 (v2), Preempt standardmäßig aus. GLBP verteilt die Last auf mehrere Router. Beides ist hier nicht ausgeführt und nicht bestätigt."
pkill -x keepalived

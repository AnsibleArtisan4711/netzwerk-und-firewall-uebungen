#!/usr/bin/env bash
# Modul 2: Interfaces, VLANs, Zonen. Die Linux-Maschine des Labors hat KEIN VLAN-Modul (8021q) und keine Bridge;
# deshalb: (1) getrennte Netze je Zone als eigene Schnittstellen, (2) ein VLAN-Rahmen von Hand gebaut und mit tcpdump gelesen.
. "$(dirname "$0")/../lab.sh"
lab_up
step "1. Vorab: Können Linux-VLAN-Schnittstellen angelegt werden? (im Labor nicht)"
cmd on fw ip link add link v-lan name v-lan.10 type vlan id 10
step "2. Zonen als getrennte Schnittstellen: LAN, DMZ und WAN der Firewall (jede ein eigenes Netz)"
cmd on fw ip -br addr show
step "3. Ohne Regel zwischen den Zonen wird nicht geroutet, wenn Weiterleitung aus ist"
on fw sysctl -qw net.ipv4.ip_forward=0
test_http cl 10.8.2.2 80
on fw sysctl -qw net.ipv4.ip_forward=1
test_http cl 10.8.2.2 80
step "4. Ein getaggter Rahmen (VLAN 10) auf dem Kabel: tcpdump -e zeigt Tag und Typ"
timeout 4 ip netns exec p08-cl tcpdump -nel -i v-cl -c 1 vlan >/tmp/p08-tcpdump.txt 2>&1 &
TP=$!; sleep 1; on fw python3 "$(dirname "$0")/tagframe.py" v-lan 10; wait $TP
grep -E 'vlan' /tmp/p08-tcpdump.txt | sed -E 's/^[0-9:.]+ //' | head -2
step "5. Ein Tag mit anderer ID ist ein anderes Netz (VLAN 20): der Empfänger trennt nach ID"
timeout 4 ip netns exec p08-cl tcpdump -nel -i v-cl -c 1 'vlan 20' >/tmp/p08-tcpdump2.txt 2>&1 &
TP=$!; sleep 1; on fw python3 "$(dirname "$0")/tagframe.py" v-lan 20; wait $TP
grep -E 'vlan' /tmp/p08-tcpdump2.txt | sed -E 's/^[0-9:.]+ //' | head -2
rm -f /tmp/p08-tcpdump.txt /tmp/p08-tcpdump2.txt
lab_down

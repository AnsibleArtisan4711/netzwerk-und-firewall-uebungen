#!/usr/bin/env bash
# Modul 11: WAN, VPN, Virtualisierung, Cloud und Overlay. Echt: VXLAN-Overlay über ein Underlay (Linux), Namensräume als Grundlage von Containern, Topologierechnung mit networkx. Nicht ausgeführt: IPsec/IKE (im Container fehlt die Kernel-Unterstützung), GRE (fehlendes Modul), Hypervisor, Cloud, Controller.
. "$(dirname "$0")/../lab.sh"
lab_up
step "1. Overlay über Underlay: VXLAN (VNI 100) zwischen zwei Standorten, Transport über ein 10.100.0.0/30-Netz"
ns_up ccu1 ccu2
link ccu1 u1 ccu2 u2; ip -n ccu1 addr add 10.100.0.1/30 dev u1; ip -n ccu2 addr add 10.100.0.2/30 dev u2
ip -n ccu1 link add vx100 type vxlan id 100 dstport 4789 local 10.100.0.1 remote 10.100.0.2 dev u1
ip -n ccu2 link add vx100 type vxlan id 100 dstport 4789 local 10.100.0.2 remote 10.100.0.1 dev u2
ip -n ccu1 addr add 172.16.100.1/24 dev vx100; ip -n ccu2 addr add 172.16.100.2/24 dev vx100; ip -n ccu1 link set vx100 up; ip -n ccu2 link set vx100 up
run "ip -n ccu1 link show vx100 | grep -oE ' mtu [0-9]+' | sed 's/^ /Overlay-Schnittstelle vx100: /'"
run "ip -n ccu1 -d link show vx100 2>/dev/null | grep -oE 'vxlan id [0-9]+|dstport [0-9]+' | paste -sd' '"
run "ip -n ccu1 link show u1 | grep -oE 'mtu [0-9]+' | sed 's/^/Underlay-Schnittstelle u1: /'"
(ip netns exec ccu1 timeout 6 tcpdump -Z root -U -n -i u1 -w vx.pcap >/dev/null 2>&1 &); sleep 1
run "ip netns exec ccu1 ping -c2 -W1 172.16.100.2 | grep transmitted | sed 's/, time.*//'"
sleep 1; pkill -x tcpdump; sleep 0.4
run "tshark -r vx.pcap -Y 'icmp' -T fields -e ip.src -e ip.dst -e udp.dstport -e vxlan.vni -e icmp.type -e frame.len 2>/dev/null | head -2 | awk -F'\\t' '{split(\$1,a,\",\"); split(\$2,b,\",\"); print \"außen (Underlay): \" a[1] \" -> \" b[1] \", UDP-Port \" \$3 \", VNI \" \$4 \"  | innen (Overlay): \" a[2] \" -> \" b[2] \", ICMP-Typ \" \$5 \", Rahmenlänge außen \" \$6 \" Byte (ohne FCS)\"}'"
echo "--- MTU-Folgen: 50 Byte Mehraufwand (Ethernet 14 + IP 20 + UDP 8 + VXLAN 8)"
run "ip netns exec ccu1 ping -c1 -W1 -M do -s 1422 172.16.100.2 | grep -E 'transmitted|too long|Frag' | sed 's/, time.*//'"
run "ip netns exec ccu1 ping -c1 -W1 -M do -s 1472 172.16.100.2 2>&1 | grep -E 'transmitted|too long|Frag' | sed 's/, time.*//' | head -2"
echo "--- Underlay gestört: Verbindung u1 unterbrochen, Overlay fällt mit aus; die Ursache liegt im Underlay"
ip -n ccu1 link set u1 down
run "ip netns exec ccu1 ping -c1 -W1 172.16.100.2 2>&1 | grep -E 'transmitted|unreachable|Unreachable' | sed 's/, time.*//' | head -2"
ip -n ccu1 link set u1 up
step "2. Nicht ausführbar im Container: IPsec (ESP) und GRE"
run "ip netns exec ccu1 ip xfrm state add src 10.100.0.1 dst 10.100.0.2 proto esp spi 0x1000 reqid 1 mode transport enc 'cbc(aes)' 0x00112233445566778899aabbccddeeff auth 'hmac(sha256)' 0x00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"
run "ip netns exec ccu1 ip link add g0 type gre local 10.100.0.1 remote 10.100.0.2"
python3 - <<'PY'
print('Lehrbuchwissen (auf Geräten nicht bestätigt): IPsec nutzt ESP (IP-Protokoll 50) oder AH (51); IKE verhandelt über UDP 500, bei NAT-Traversal über UDP 4500; GRE ist IP-Protokoll 47.')
print('Site-to-Site-VPN: zwei Gateways verbinden zwei Netze dauerhaft; Remote-Access-VPN: ein Client verbindet sich einzeln. Der Tunnel kapselt, die Verschlüsselung (IPsec) schützt Vertraulichkeit und Integrität.')
PY
step "3. Virtualisierung und Container: Namensräume als technische Grundlage (Linux)"
run "echo -n 'Prozesse im Hauptnamensraum: '; ps -e --no-headers | wc -l"
run "echo -n 'Prozesse im neuen PID-Namensraum: '; unshare --pid --fork --mount-proc ps -e --no-headers | wc -l"
run "unshare --uts sh -c 'hostname lab-container; echo Hostname im Namensraum: \$(hostname)'; echo Hostname außen bleibt: \$(hostname)"
run "unshare -n sh -c 'ip -br link | awk \"{print \\\$1, \\\$2}\"'"
echo "Die letzte Zeile zeigt: ein neuer Netzwerk-Namensraum enthält nur lo und keine der Schnittstellen des Hosts. Container teilen den Kernel des Hosts; eine VM bringt ihren eigenen Kernel mit und läuft auf einem Hypervisor."
which podman docker qemu-img 2>/dev/null | sed 's/^/vorhanden (nicht gestartet): /'
step "4. WAN-Topologien im Vergleich (networkx): Verbindungen, Ausfall eines Standorts, Ausfall einer Leitung"
python3 - <<'PY'
import networkx as nx
n = 6
def hub(n): g = nx.star_graph(n - 1); return g
def voll(n): return nx.complete_graph(n)
def teil(n): g = nx.cycle_graph(n); g.add_edge(0, n // 2); return g
for name, g in (('Hub-and-Spoke (Knoten 0 = Zentrale)', hub(n)), ('Teilvermascht (Ring plus Querverbindung)', teil(n)), ('Vollvermascht', voll(n))):
    ausfall = []
    for v in g.nodes:
        h = g.copy(); h.remove_node(v)
        if not nx.is_connected(h): ausfall.append(v)
    leitung = sum(1 for e in g.edges if not nx.is_connected(nx.restricted_view(g, [], [e])))
    print('%-42s %2d Leitungen; Ausfall dieser Standorte trennt das Netz: %-10s; kritische Leitungen: %d' % (name, g.number_of_edges(), ausfall or 'keiner', leitung))
print('Faustformel: Vollvermaschung braucht n*(n-1)/2 Leitungen, bei n = 12 Standorten sind das', 12 * 11 // 2, 'gegen', 11, 'bei Hub-and-Spoke.')
PY
step "5. Cloud-Adressplanung: VPC-Netz mit Subnetzen je Zone und Überschneidung mit dem Standortnetz prüfen"
python3 - <<'PY'
import ipaddress
vpc = ipaddress.ip_network('10.20.0.0/16'); standort = ipaddress.ip_network('10.20.5.0/24')
subs = list(vpc.subnets(new_prefix=24))
plan = [('öffentlich', 'Zone A', subs[0]), ('privat', 'Zone A', subs[10]), ('öffentlich', 'Zone B', subs[1]), ('privat', 'Zone B', subs[11])]
for art, z, n in plan: print('%-11s %-7s %s' % (art, z, n))
print('Überschneidung mit dem Standortnetz', standort, ':', [str(n) for _, _, n in plan if n.overlaps(standort)] or 'keine geplanten Subnetze betroffen', '| das VPC-Netz als Ganzes überlappt:', vpc.overlaps(standort))
print('Folge: Ein Site-to-Site-VPN zwischen überlappenden Netzen braucht NAT oder eine Neuplanung der Adressen.')
PY

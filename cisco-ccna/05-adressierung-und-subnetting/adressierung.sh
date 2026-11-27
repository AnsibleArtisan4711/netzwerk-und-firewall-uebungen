#!/usr/bin/env bash
# Modul 5: IPv4- und IPv6-Adressierung und Subnetting. Rechnen mit Python (ipaddress), echte Fehlerbilder in Namensräumen (falsches Gateway, falsche Maske, doppelte Adresse). Der IPv6-Teil ist reine Rechnung; im Container ist IPv6 nicht aktiv.
. "$(dirname "$0")/../lab.sh"
lab_up
step "1. Adresse zerlegen: Netz, Broadcast, Hosts, Maske (Python ipaddress)"
python3 - <<'PY'
import ipaddress as ip
for a in ['192.168.10.77/26', '10.1.2.3/20', '172.16.5.9/30']:
    i = ip.ip_interface(a); n = i.network
    print('%-17s Netz %-16s Broadcast %-15s Maske %-15s Wildcard %-15s Hosts %d' % (a, n.network_address, n.broadcast_address, n.netmask, n.hostmask, n.num_addresses - 2))
print('Binär: 192.168.10.77 =', '.'.join(format(int(o), '08b') for o in '192.168.10.77'.split('.')))
PY
step "2. VLSM-Plan: Netze nach Größe von groß nach klein aus 192.168.100.0/24 verteilen"
python3 - <<'PY'
import ipaddress as ip, math
block = ip.ip_network('192.168.100.0/24'); bedarf = [('Verwaltung', 100), ('Labor', 50), ('Gäste', 25), ('Server', 12), ('Link R1-R2', 2)]
nxt = int(block.network_address)
for name, h in sorted(bedarf, key=lambda x: -x[1]):
    bits = math.ceil(math.log2(h + 2)); pre = 32 - bits
    n = ip.ip_network((nxt, pre)); nxt += 2 ** bits
    print('%-12s braucht %3d Hosts -> %-18s nutzbar %3d  Gateway-Vorschlag %s' % (name, h, n, n.num_addresses - 2, n.network_address + 1))
print('Rest im Block ab', ip.ip_address(nxt), 'bis', block.broadcast_address)
PY
step "3. Besondere Adressen erkennen"
python3 - <<'PY'
import ipaddress as ip
for a in ['127.0.0.1', '169.254.10.5', '10.0.0.1', '172.32.0.1', '192.0.2.10', '224.0.0.5', '255.255.255.255', '8.8.8.8']:
    i = ip.ip_address(a)
    art = 'Loopback' if i.is_loopback else 'Link-Local (APIPA)' if i.is_link_local else 'Multicast' if i.is_multicast else 'Broadcast' if a == '255.255.255.255' else 'privat (RFC 1918)' if any(i in ip.ip_network(n) for n in ('10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16')) else 'Dokumentationsnetz' if i in ip.ip_network('192.0.2.0/24') else 'öffentlich'
    print('%-16s %s' % (a, art))
PY
step "4. IPv6 als Rechnung: Kurzschreibweise, EUI-64, Solicited-Node, Aufteilung /48 in /64 (im Container nicht ausgeführt)"
python3 - <<'PY'
import ipaddress as ip
a = ip.ip_address('2001:0db8:0000:0000:0000:0000:0000:0001'); print('Kurzform:', a.compressed, ' Langform:', a.exploded)
mac = '00:1b:63:84:45:e6'; b = bytearray(int(x, 16) for x in mac.split(':')); b[0] ^= 2
eui = bytes(b[:3]) + b'\xff\xfe' + bytes(b[3:]); ll = ip.IPv6Address(b'\xfe\x80' + bytes(6) + eui)
print('EUI-64 aus MAC', mac, '->', ll.compressed, '(7. Bit des ersten Bytes invertiert, ff:fe in der Mitte)')
sn = ip.IPv6Address('ff02::1:ff00:0') + int.from_bytes(ll.packed[-3:], 'big'); print('Solicited-Node-Multicast dazu:', sn.compressed)
n = ip.ip_network('2001:db8:abcd::/48'); sub = list(n.subnets(new_prefix=64))[:3]
print('Ein /48 enthält', 2 ** 16, '/64-Netze, z. B.', ', '.join(str(x) for x in sub))
print('Adresstypen: fe80::/10 Link-Local, fc00::/7 Unique Local, ff00::/8 Multicast, 2000::/3 Global Unicast, ::1 Loopback')
PY
step "5. Zusammenfassen von Routen (Summarization)"
python3 - <<'PY'
import ipaddress as ip
nets = [ip.ip_network(x) for x in ['192.168.0.0/24', '192.168.1.0/24', '192.168.2.0/24', '192.168.3.0/24']]
print('Eingabe:', ', '.join(map(str, nets)), '->', list(ip.collapse_addresses(nets)))
nets.append(ip.ip_network('192.168.5.0/24')); print('Mit 192.168.5.0/24 dazu:', list(ip.collapse_addresses(nets)), '(Lücke bei .4, daher keine einzelne Summe)')
PY
step "6. Fehlerbilder real: Namensräume mit Router; Host A liegt in 192.168.1.0/24, Host B in 192.168.2.0/24"
ns_up cc5a cc5b cc5r; link cc5a a5 cc5r r5a; link cc5b b5 cc5r r5b
ip -n cc5r addr add 192.168.1.1/24 dev r5a; ip -n cc5r addr add 192.168.2.1/24 dev r5b; fwd cc5r
ip -n cc5b addr add 192.168.2.10/24 dev b5; ip -n cc5b route add default via 192.168.2.1
echo "--- 6a. richtig konfiguriert (Vergleich)"
ip -n cc5a addr add 192.168.1.10/24 dev a5; ip -n cc5a route add default via 192.168.1.1
run "ip netns exec cc5a ping -c1 -W1 192.168.2.10 | grep -E 'transmitted'"
echo "--- 6b. falsches Gateway (192.168.1.254 gibt es nicht)"
ip -n cc5a route replace default via 192.168.1.254
run "ip netns exec cc5a ping -c1 -W1 192.168.2.10 2>&1 | grep -E 'Unreachable|transmitted'"
run "ip netns exec cc5a ip neigh show 192.168.1.254 | awk '{print \$1, \$NF}'"
echo "Der Host fragt per ARP nach 192.168.1.254 und bekommt keine Antwort (INCOMPLETE); die Route zeigt auf ein Gateway, das nicht existiert."
echo "--- 6c. Maske /30 am Host: das Gateway liegt außerhalb des eigenen Netzes"
ip -n cc5a route del default; ip -n cc5a addr flush dev a5; ip -n cc5a addr add 192.168.1.10/30 dev a5
run "ip netns exec cc5a ip route add default via 192.168.1.1 2>&1"
echo "--- 6d. Maske /16 am Host: der Host hält 192.168.2.10 für direkt erreichbar und fragt per ARP statt über den Router"
ip -n cc5a addr flush dev a5; ip -n cc5a addr add 192.168.1.10/16 dev a5; ip -n cc5a route add default via 192.168.1.1 2>/dev/null
run "ip netns exec cc5a ping -c1 -W1 192.168.2.10 2>&1 | grep -E 'Unreachable|transmitted'"
run "ip netns exec cc5a ip neigh show 192.168.2.10 | awk '{print \$1, \$NF}'"
echo "--- 6e. doppelte Adresse: zwei Geräte mit 192.168.1.50 im selben Netz, Mitschnitt zeigt zwei Antworten mit verschiedenen MACs"
ns_up cc5c cc5d cc5e cc5s
link cc5c c5 cc5s s5c; link cc5d d5 cc5s s5d; link cc5e e5 cc5s s5e
ip -n cc5s link add br0 type bridge stp_state 0; for p in s5c s5d s5e; do ip -n cc5s link set $p master br0; done; ip -n cc5s link set br0 up
ip -n cc5c link set c5 address 02:00:00:00:05:0c; ip -n cc5d link set d5 address 02:00:00:00:05:0d; ip -n cc5e link set e5 address 02:00:00:00:05:0e
ip -n cc5c addr add 192.168.1.50/24 dev c5; ip -n cc5d addr add 192.168.1.50/24 dev d5; ip -n cc5e addr add 192.168.1.60/24 dev e5
(ip netns exec cc5e timeout 4 tcpdump -Z root -U -n -i e5 -w dup.pcap arp >/dev/null 2>&1 &); sleep 1
run "ip netns exec cc5e ping -c1 -W1 192.168.1.50 | grep -E 'transmitted'"; sleep 3
run "tshark -r dup.pcap -Y 'arp.opcode==2' -T fields -e arp.src.proto_ipv4 -e arp.src.hw_mac 2>/dev/null | sort -u"
echo "Zwei Antworten für dieselbe IP-Adresse mit verschiedenen MAC-Adressen: typisches Zeichen einer doppelten Adresse; der ARP-Cache des Fragenden wechselt zwischen beiden."

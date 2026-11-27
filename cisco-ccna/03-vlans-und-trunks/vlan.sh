#!/usr/bin/env bash
# Modul 3: VLANs, Trunks und Inter-VLAN-Routing. Der Container hat kein 8021q-Modul und keine VLAN-Filterung der Bridge: 802.1Q-Rahmen werden von Hand gebaut, das Switch-Verhalten ist ein Python-Modell, getrennte Broadcast-Domänen entstehen mit zwei Bridges. IOS-Text wird nur erzeugt, nicht ausgeführt.
. "$(dirname "$0")/../lab.sh"
lab_up
step "1. 802.1Q-Rahmen von Hand gebaut (AF_PACKET) und im Mitschnitt gelesen: VLAN-ID und Priorität (PCP) stehen im Tag"
ns_up cctx; ip link add cvt type veth peer name cvr; ip link set cvt netns cctx; ip -n cctx link set cvt up; ip link set cvr up
(timeout 5 tcpdump -Z root -U -n -e -i cvr -w v.pcap >/dev/null 2>&1 &); sleep 1
ip netns exec cctx python3 - <<'PY'
import socket, struct
s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW); s.bind(('cvt', 0))
dst = bytes.fromhex('0200000000aa'); src = bytes.fromhex('0200000000bb')
for vid, pcp in [(10, 0), (20, 0), (30, 5)]:
    tci = (pcp << 13) | vid
    s.send(dst + src + struct.pack('!HHH', 0x8100, tci, 0x0800) + b'\x45' + b'\x00' * 45)
PY
sleep 1; pkill -x tcpdump; sleep 0.5
run "tshark -r v.pcap -Y vlan -T fields -e vlan.id -e vlan.priority -e vlan.etype 2>/dev/null | awk '{print \"VLAN-ID \" \$1 \"  Priorität \" \$2 \"  EtherType darunter \" \$3}'"
echo "Das Tag (4 Byte) enthält TPID 0x8100, Priorität (3 Bit), DEI (1 Bit) und VLAN-ID (12 Bit, gültig 1 bis 4094). Ein Rahmen ohne Tag gehört im Trunk zum Native VLAN."
ip link del cvr 2>/dev/null
step "2. Verhalten eines Switch-Ports als Python-Modell: Access, Trunk, Native VLAN, erlaubte VLANs"
python3 - <<'PY'
ports = {'Fa0/1': dict(modus='access', vlan=10), 'Fa0/2': dict(modus='access', vlan=20),
         'Gi0/1': dict(modus='trunk', native=1, erlaubt={1, 10, 20})}
def eingang(p, vlan_tag):
    c = ports[p]
    if c['modus'] == 'access': return c['vlan'] if vlan_tag is None else None
    v = c['native'] if vlan_tag is None else vlan_tag
    return v if v in c['erlaubt'] else None
def ausgang(p, vlan):
    c = ports[p]
    if c['modus'] == 'access': return 'ohne Tag' if c['vlan'] == vlan else None
    if vlan not in c['erlaubt']: return None
    return 'ohne Tag (Native)' if vlan == c['native'] else 'mit Tag %d' % vlan
tests = [('Fa0/1', None), ('Fa0/2', None), ('Gi0/1', None), ('Gi0/1', 20), ('Gi0/1', 30), ('Fa0/1', 10)]
for p, t in tests:
    v = eingang(p, t)
    print('Eingang %-5s Tag %-5s -> VLAN %-5s' % (p, t, v), end='  ')
    if v is None: print('verworfen'); continue
    print('; '.join('%s: %s' % (q, ausgang(q, v)) for q in ports if q != p and ausgang(q, v)) or 'kein anderer Port in diesem VLAN')
PY
echo "Modellannahme: Ein getaggter Rahmen an einem Access-Port wird verworfen; das echte Verhalten hängt vom Gerät ab und wurde nicht geprüft."
echo "Kernaussage: Frames in VLAN 10 erscheinen nie an einem Access-Port von VLAN 20; VLAN 30 wird am Trunk verworfen, weil es nicht erlaubt ist."
step "3. VLAN-Plan prüfen (YAML) und daraus IOS-Text erzeugen (nur Text, nicht ausgeführt)"
cat > plan.yaml <<'C'
vlans:
  - {id: 10, name: Verwaltung, netz: 192.168.10.0/24}
  - {id: 20, name: Labor, netz: 192.168.20.0/24}
  - {id: 20, name: Gaeste, netz: 192.168.20.128/25}
  - {id: 4095, name: Fehler, netz: 192.168.40.0/24}
C
python3 - <<'PY'
import yaml, ipaddress, itertools
v = yaml.safe_load(open('plan.yaml'))['vlans']
for a in v:
    f = []
    if not 1 <= a['id'] <= 4094: f.append('ID außerhalb 1 bis 4094')
    if sum(1 for b in v if b['id'] == a['id']) > 1: f.append('ID doppelt')
    print('VLAN %-5d %-11s %-18s %s' % (a['id'], a['name'], a['netz'], '; '.join(f) or 'ok'))
for a, b in itertools.combinations(v, 2):
    if ipaddress.ip_network(a['netz']).overlaps(ipaddress.ip_network(b['netz'])): print('Subnetze überlappen:', a['name'], a['netz'], 'und', b['name'], b['netz'])
print('\nErzeugter IOS-Text für das gültige VLAN 10 und einen Trunk-Port (nicht ausgeführt):')
for a in v[:1]: print('vlan %d\n name %s' % (a['id'], a['name']))
print('interface GigabitEthernet0/1\n switchport mode trunk\n switchport trunk allowed vlan 10,20\n switchport trunk native vlan 99')
PY
step "4. Inter-VLAN-Routing real: zwei Netze = zwei Broadcast-Domänen, nur der Router verbindet sie (Router-on-a-stick-Modell ohne Tags)"
ns_up ccva ccvb ccvr ccsa ccsb
link ccva va0 ccsa pa1; link ccvb vb0 ccsb pb1; link ccvr ra0 ccsa pa2; link ccvr rb0 ccsb pb2
for b in "ccsa pa1 pa2" "ccsb pb1 pb2"; do set -- $b; ip -n $1 link add br0 type bridge; ip -n $1 link set $2 master br0; ip -n $1 link set $3 master br0; ip -n $1 link set br0 up; done
ip -n ccva addr add 192.168.10.10/24 dev va0; ip -n ccvr addr add 192.168.10.1/24 dev ra0; ip -n ccva route add default via 192.168.10.1
ip -n ccvb addr add 192.168.20.10/24 dev vb0; ip -n ccvr addr add 192.168.20.1/24 dev rb0; ip -n ccvb route add default via 192.168.20.1; fwd ccvr
run "ip netns exec ccva ping -c1 -W1 192.168.20.10 | grep -E 'transmitted'"
run "ip netns exec ccva ip neigh show | awk '{print \$1, \$5}'"
echo "Der Client in VLAN 10 kennt nur die MAC des Routers; die MAC des Clients in VLAN 20 bleibt ihm verborgen (ARP geht nicht über den Router)."
echo "--- Ausfall der Router-Seite von VLAN 20"
ip -n ccvr link set rb0 down
run "ip netns exec ccva ping -c1 -W1 192.168.20.10 2>&1 | grep -E 'transmitted|Unreachable'"
ip -n ccvr link set rb0 up
echo "Ohne Router-Schnittstelle in VLAN 20 meldet der Router „Destination Net Unreachable“; innerhalb von VLAN 10 bleibt alles erreichbar."

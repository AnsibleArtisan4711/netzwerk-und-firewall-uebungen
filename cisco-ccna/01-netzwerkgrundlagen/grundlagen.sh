#!/usr/bin/env bash
# Modul 1: Netzwerkgrundlagen und Architektur. Echte Linux-Namensräume als Modell: Mitschnitt einer HTTP-Abfrage mit Schichten, ARP, traceroute, Topologien, Befehlsmodus-Modell, Planprüfung. Es läuft kein Cisco IOS.
. "$(dirname "$0")/../lab.sh"
lab_up
ns_up cch1 cch2 ccr
link cch1 h1e ccr r1e; link cch2 h2e ccr r2e
ip -n cch1 link set h1e address 02:00:00:00:01:01; ip -n ccr link set r1e address 02:00:00:00:01:fe
ip -n cch2 link set h2e address 02:00:00:00:02:01; ip -n ccr link set r2e address 02:00:00:00:02:fe
ip -n cch1 addr add 192.168.1.10/24 dev h1e; ip -n ccr addr add 192.168.1.1/24 dev r1e
ip -n cch2 addr add 192.168.2.10/24 dev h2e; ip -n ccr addr add 192.168.2.1/24 dev r2e
ip -n cch1 route add default via 192.168.1.1; ip -n cch2 route add default via 192.168.2.1; fwd ccr
step "1. Aufbau: zwei Netze, ein Router (Modell der Rollen Endgerät und Router)"
run "ip -n cch1 -br addr show h1e; ip -n cch2 -br addr show h2e; ip -n ccr -br addr show | grep -v lo"
step "2. HTTP-Abfrage über den Router, mitgeschnitten am Server-Anschluss: Schichten 2, 3 und 4 in einem Paket"
mkdir -p www; echo "Hallo aus dem Labor" > www/index.html
bgstart cch2 web 8080 python3 -m http.server 8080 --bind 192.168.2.10 --directory $W/www
(ip netns exec cch2 timeout 5 tcpdump -Z root -U -n -i h2e -w http.pcap >/dev/null 2>&1 &); sleep 1
run "ip netns exec cch1 curl -s --local-port 40000 http://192.168.2.10:8080/ | head -1"
sleep 1; pkill -x tcpdump; sleep 0.5
echo "--- erstes TCP-Paket des Clients (SYN) mit Ethernet-, IP- und TCP-Feldern"
run "tshark -r http.pcap -Y 'tcp.flags.syn==1 && tcp.flags.ack==0' -T fields -e eth.src -e eth.dst -e ip.src -e ip.dst -e ip.ttl -e tcp.srcport -e tcp.dstport 2>/dev/null | head -1 | awk -F'\\t' '{print \"Eth \" \$1 \" -> \" \$2 \"\\nIP  \" \$3 \" -> \" \$4 \"  TTL \" \$5 \"\\nTCP \" \$6 \" -> \" \$7}'"
echo "Die Quell-MAC am Server ist die des Routers (02:00:00:00:02:fe), nicht die des Clients: Ethernet gilt nur bis zum nächsten Gerät, IP-Adressen bleiben Ende zu Ende. Der TTL-Wert ist um 1 gesunken."
echo "--- TCP-Flags der ersten Pakete (SYN, SYN/ACK, ACK = Dreiwege-Handshake)"
run "tshark -r http.pcap -Y tcp -T fields -e tcp.srcport -e tcp.flags.str 2>/dev/null | head -3 | awk -F'\\t' '{print \$1, \$2}'"
step "3. ARP-Tabellen: wer kennt wen (nur das jeweils nächste Gerät)"
run "ip -n cch1 neigh show | grep -v FAILED | awk '{print \$1, \$3, \$5}'"
run "ip -n cch2 neigh show | grep -v FAILED | awk '{print \$1, \$3, \$5}'"
step "4. traceroute: der Router erscheint als erster Hop"
run "ip netns exec cch1 traceroute -n -q1 -w1 192.168.2.10 | sed 's/ms.*/ms/'"
pkill -f "http.server" 2>/dev/null
step "5. Topologien: Kennzahlen mit networkx (Stern, Ring, Voll vermascht, Bus als Kette)"
python3 - <<'PY'
import networkx as nx
n = 5
T = {'Stern': nx.star_graph(n - 1), 'Ring': nx.cycle_graph(n), 'Voll vermascht': nx.complete_graph(n), 'Bus (Kette)': nx.path_graph(n)}
print('%-16s %-8s %-9s %-22s' % ('Topologie', 'Links', 'Ø Hops', 'Ausfall eines Links trennt?'))
for k, g in T.items():
    trennt = any(not nx.is_connected(nx.restricted_view(g, [], [e]).copy()) for e in list(g.edges))
    print('%-16s %-8d %-9.2f %s' % (k, g.number_of_edges(), nx.average_shortest_path_length(g), 'ja' if trennt else 'nein'))
print('Voll vermascht kostet bei n Geräten n(n-1)/2 Links (hier 10); der Ring übersteht den Ausfall eines Links.')
PY
step "6. Befehlsmodus-Modell: Abkürzungen eindeutig auflösen (eigenes Modell, kein Abbild von IOS)"
python3 - <<'PY'
B = {'user': ['enable', 'ping', 'show', 'traceroute'], 'privileged': ['configure', 'copy', 'disable', 'ping', 'reload', 'show'], 'config': ['hostname', 'interface', 'ip', 'exit', 'end']}
def aufloesen(modus, wort):
    t = [b for b in B[modus] if b.startswith(wort)]
    return t[0] if len(t) == 1 else ('mehrdeutig: ' + ', '.join(t) if t else 'unbekannt')
for m, w in [('privileged', 'conf'), ('privileged', 'co'), ('user', 'sh'), ('user', 'conf'), ('config', 'int')]: print('%-11s %-5s -> %s' % (m, w, aufloesen(m, w)))
print('Das Modell zeigt nur das Prinzip der eindeutigen Abkürzung; die echten Befehlsbäume von IOS wurden nicht geprüft.')
PY
step "7. Planprüfung: Namensschema und doppelte Adressen in einer Geräteliste"
cat > geraete.csv <<'C'
name,ip
sw-lab-01,192.168.10.2
sw-lab-02,192.168.10.3
rtr-lab-1,192.168.10.1
SW_Lab_03,192.168.10.3
C
python3 - <<'PY'
import csv, re, collections
rows = list(csv.DictReader(open('geraete.csv')))
ips = collections.Counter(r['ip'] for r in rows)
for r in rows:
    f = []
    if not re.fullmatch(r'(sw|rtr)-lab-\d+', r['name']): f.append('Name entspricht nicht dem Schema typ-lab-nr')
    if ips[r['ip']] > 1: f.append('IP-Adresse doppelt')
    print('%-10s %-14s %s' % (r['name'], r['ip'], '; '.join(f) or 'ok'))
PY

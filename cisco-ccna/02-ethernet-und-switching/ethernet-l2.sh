#!/usr/bin/env bash
# Modul 2: Ethernet, Verkabelung und Switching-Grundlagen. Linux-Bridge als Switch-Modell (Lernen, Fluten, Altern), LLDP und CDP-Rahmen mit lldpd, Verkabelungs- und Zählertabellen als Modell. Kein Cisco IOS.
. "$(dirname "$0")/../lab.sh"
lab_up
ns_up ccsw cca cchb cchc
link cca a0 ccsw p1; link cchb b0 ccsw p2; link cchc c0 ccsw p3
for x in "cca a0 1" "cchb b0 2" "cchc c0 3"; do set -- $x; ip -n $1 link set $2 address 02:00:00:00:00:0$3; ip -n $1 addr add 192.168.50.1$3/24 dev $2; done
ip -n ccsw link add br0 type bridge ageing_time 3000 stp_state 0; for p in p1 p2 p3; do ip -n ccsw link set $p master br0; done; ip -n ccsw link set br0 up
step "1. Aufbau: ein Switch (Linux-Bridge) mit drei Endgeräten"
run "ip -n ccsw -br link show | grep -E 'p[123]' | awk '{print \$1, \$2}'"
step "2. MAC-Adresse zerlegen (Python): Individual/Group-Bit, Universal/Local-Bit, OUI"
python3 - <<'PY'
for m in ['00:1b:63:84:45:e6', '01:00:5e:00:00:05', '02:00:00:00:00:01', 'ff:ff:ff:ff:ff:ff', '01:80:c2:00:00:00']:
    b = int(m.split(':')[0], 16)
    art = 'Broadcast' if m == 'ff:ff:ff:ff:ff:ff' else ('Multicast' if b & 1 else 'Unicast')
    rest = 'kein Herstellerbezug' if art != 'Unicast' else ('lokal vergeben (kein Hersteller)' if b & 2 else 'herstellerweit, OUI ' + ':'.join(m.split(':')[:3]))
    print('%s  %-9s %s' % (m, art, rest))
PY
step "3. Erster Austausch: der Switch flutet die ARP-Anfrage, die Antwort geht nur zum Fragenden"
mkdir -p cap
(ip netns exec cchc timeout 4 tcpdump -Z root -U -n -e -i c0 -w cap/c.pcap >/dev/null 2>&1 &); sleep 1
run "ip netns exec cca ping -c1 -W1 192.168.50.12 | grep -E 'transmitted'"
sleep 3; pkill -x tcpdump; sleep 0.5
echo "--- was Gerät 3 gesehen hat (es ist weder Sender noch Ziel)"
run "tshark -r cap/c.pcap -Y 'arp || icmp' -T fields -e eth.src -e eth.dst -e _ws.col.Info 2>/dev/null | sed 's/\\t/  /g' | cut -c1-90"
step "4. MAC-Tabelle (FDB) des Switches"
run "ip netns exec ccsw bridge fdb show br br0 | grep -v permanent | grep -v self | awk '{print \$1, \$3, \$5}' | sort"
step "5. Altern: Einträge verschwinden nach der Alterungszeit (hier 3 s; die Standardvorgabe von Linux ist 300 s)"
ip -n ccsw link set br0 type bridge ageing_time 300
run "ip netns exec cca ping -c1 -W1 192.168.50.12 | grep -E 'transmitted'"
run "ip netns exec ccsw bridge fdb show br br0 | grep -vE 'permanent|self' | wc -l | sed 's/^/Einträge direkt nach dem Verkehr: /'"
sleep 9
run "ip netns exec ccsw bridge fdb show br br0 | grep -vE 'permanent|self' | wc -l | sed 's/^/Einträge nach 9 s ohne Verkehr: /'"
run "ip netns exec cchb ping -c1 -W1 192.168.50.13 | grep -E 'transmitted'"
run "ip netns exec ccsw bridge fdb show br br0 | grep -vE 'permanent|self' | awk '{print \$1, \$3}' | sort"
echo "Der Switch lernt die Quell-MAC jedes Rahmens neu; Einträge, die nicht erneuert werden, altern aus."
step "6. Schnittstellenzustand und Geschwindigkeit mit ethtool (virtuelle Schnittstelle, Werte sind Modellwerte)"
run "ip netns exec cca ethtool a0 2>/dev/null | grep -E 'Speed|Duplex|Link detected'"
echo "--- Anschluss p2 des Switches ausfallen lassen: Endgerät 2 verliert den Link, das Gegenstück ebenso"
ip -n ccsw link set p2 down
run "ip netns exec cchb ethtool b0 2>/dev/null | grep 'Link detected'"
run "ip netns exec cca ping -c1 -W1 192.168.50.12 2>&1 | grep -E 'transmitted'"
ip -n ccsw link set p2 up; sleep 1
run "ip netns exec cca ping -c1 -W1 192.168.50.12 2>&1 | grep -E 'transmitted'"
step "7. LLDP: Nachbarn entdecken (lldpd, herstellerneutrales Protokoll, Standard IEEE 802.1AB)"
ns_up ccd1 ccd2; link ccd1 l1 ccd2 l2; mkdir -p l1 l2
ip netns exec ccd1 lldpd -u $W/l1/s -I l1 >/dev/null 2>&1; ip netns exec ccd2 lldpd -u $W/l2/s -I l2 >/dev/null 2>&1; sleep 1
lldpcli -u $W/l1/s configure system hostname sw-a >/dev/null; lldpcli -u $W/l2/s configure system hostname sw-b >/dev/null
lldpcli -u $W/l1/s update >/dev/null 2>&1; lldpcli -u $W/l2/s update >/dev/null 2>&1; sleep 4
run "lldpcli -u $W/l1/s show neighbors summary 2>&1 | grep -E 'Interface|ChassisID|SysName|PortID' | sed -E 's/^ +//'"
pkill -x lldpd; sleep 1
step "7b. CDP-Rahmen (Cisco Discovery Protocol) erzeugt lldpd nur mit dem Schalter -cc; hier nur der Rahmen im Mitschnitt"
ip netns exec ccd1 lldpd -cc -u $W/l1/s -I l1 >/dev/null 2>&1; ip netns exec ccd2 lldpd -cc -u $W/l2/s -I l2 >/dev/null 2>&1; sleep 1
lldpcli -u $W/l1/s configure system hostname sw-a >/dev/null; lldpcli -u $W/l2/s configure system hostname sw-b >/dev/null
(ip netns exec ccd2 timeout 9 tcpdump -Z root -U -n -i l2 -w cdp.pcap >/dev/null 2>&1 &); sleep 1
lldpcli -u $W/l1/s update >/dev/null 2>&1; sleep 7; pkill -x tcpdump; sleep 0.5
run "tshark -r cdp.pcap -Y cdp -T fields -e eth.dst -e cdp.deviceid -e cdp.portid 2>/dev/null | sort -u | head -2"
echo "Zieladresse 01:00:0c:cc:cc:cc ist die Cisco-Multicast-Adresse für CDP; ein echter Catalyst wurde nicht eingesetzt."
pkill -x lldpd
step "8. Verkabelung (Lehrbuchwissen) und Zählerauswertung (erfundene Beispielwerte)"
python3 - <<'PY'
print('T568B (Pin: Farbe): 1 weiß/orange, 2 orange, 3 weiß/grün, 4 blau, 5 weiß/blau, 6 grün, 7 weiß/braun, 8 braun')
print('Gerade Verbindung (Endgerät zu Switch): beide Enden T568B. Gekreuzt (gleichartige Geräte): ein Ende T568A; moderne Anschlüsse erkennen das mit Auto-MDI/MDIX.')
print('Medien: Kupfer bis 100 m (Cat 5e/6), Multimode-Glasfaser für Gebäude, Singlemode-Glasfaser für große Entfernungen (Faustwerte, Herstellerangaben prüfen).')
zaehler = {'Gi0/1': dict(crc=0, runts=0, giants=0, late=0, flaps=0), 'Gi0/2': dict(crc=1840, runts=12, giants=0, late=0, flaps=0), 'Gi0/3': dict(crc=0, runts=0, giants=0, late=37, flaps=0), 'Gi0/4': dict(crc=0, runts=0, giants=0, late=0, flaps=9)}
deut = {'crc': 'CRC-Fehler: schlechtes Kabel, Stecker oder Störung', 'runts': 'zu kurze Rahmen: Kollisionen oder Fehler beim Sender', 'giants': 'zu große Rahmen: MTU-Unterschied', 'late': 'späte Kollisionen: Duplexfehler oder zu langes Kabel', 'flaps': 'Link wechselt ständig: Kabel, Stecker oder Gegenstelle'}
print('\nAnschluss  Befund (Zählerwerte sind erfunden)')
for p, z in zaehler.items():
    f = [deut[k] for k, v in z.items() if v]
    print('%-9s  %s' % (p, '; '.join(f) or 'unauffällig'))
PY

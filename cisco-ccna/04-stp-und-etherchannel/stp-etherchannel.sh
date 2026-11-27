#!/usr/bin/env bash
# Modul 4: STP, EtherChannel und Layer-2-Redundanz. Echtes klassisches STP (802.1D) mit Linux-Bridges in drei Namensräumen; Rapid PVST+, PortFast, Loop Guard und LACP sind im Container nicht verfügbar und nur als Modell oder Text enthalten.
. "$(dirname "$0")/../lab.sh"
lab_up
for s in ccs1 ccs2 ccs3; do ns_up $s; done
# Dreieck: s1-s2 (p12a/p12b), s2-s3 (p23a/p23b), s3-s1 (p31a/p31b); feste Bridge-MACs, damit die Wahl der Root-Bridge nachvollziehbar ist
link ccs1 p12a ccs2 p12b; link ccs2 p23a ccs3 p23b; link ccs3 p31a ccs1 p31b
mac=1; for s in ccs1 ccs2 ccs3; do
  ip -n $s link add br0 type bridge stp_state 1 forward_delay 400 max_age 600 hello_time 100; ip -n $s link set br0 address 02:00:00:00:00:0$mac; mac=$((mac+1))
done
for p in "ccs1 p12a" "ccs2 p12b" "ccs2 p23a" "ccs3 p23b" "ccs3 p31a" "ccs1 p31b"; do set -- $p; ip -n $1 link set $2 master br0; done
for s in ccs1 ccs2 ccs3; do ip -n $s link set br0 up; done
zeige() { for s in ccs1 ccs2 ccs3; do printf '%s: ' $s; ip -n $s -d link show br0 | grep -oE 'bridge_id [^ ]+|root_port [0-9]+|root_path_cost [0-9]+' | tr '\n' ' '; echo -n "root_id "; ip netns exec $s cat /sys/class/net/br0/bridge/root_id; done; echo "Portzustände:"; for s in ccs1 ccs2 ccs3; do ip netns exec $s bridge -d link show | grep -oE '^[0-9]+: [a-z0-9]+|state [a-z]+' | paste -sd' ' | sed 's/ \([0-9]*:\)/\n\1/g' | sed "s/^[0-9]*: /  $s /"; done; }
step "1. Root-Bridge-Wahl: die kleinste Bridge-ID gewinnt (Priorität, dann MAC); alle Prioritäten sind gleich (32768)"
sleep 18; zeige
step "2. Priorität 4096 auf ccs3: ccs3 wird neue Root-Bridge, die Topologie wird neu berechnet"
ip -n ccs3 link set br0 type bridge priority 4096; sleep 14; zeige
step "3. Ausfall der Verbindung zwischen ccs2 und ccs1 (Anschluss p12b): ein gesperrter Port übernimmt, Wiederherstellungszeit gemessen (klassisches STP, mit verkürzten Zeiten)"
ip -n ccs1 link set br0 type bridge priority 4096 2>/dev/null; ip -n ccs3 link set br0 type bridge priority 32768; sleep 12
ip -n ccs2 addr add 10.40.0.2/24 dev br0; ip -n ccs3 addr add 10.40.0.3/24 dev br0 2>/dev/null; ip -n ccs1 addr add 10.40.0.1/24 dev br0; sleep 1
(ip netns exec ccs2 timeout -s INT 22 ping -D -i 0.2 -W1 10.40.0.1 > ping.txt 2>&1 &); sleep 3
T0=$(date +%s.%N); ip -n ccs2 link set p12b down; sleep 20
python3 - $T0 <<'PY'
import re, sys
t0 = float(sys.argv[1])
ts = [float(m.group(1)) for m in re.finditer(r'^\[(\d+\.\d+)\].*bytes from', open('ping.txt').read(), re.M)]
vor = [t for t in ts if t < t0]; nach = [t for t in ts if t > t0]
print('Antworten vor dem Ausfall: %d, nach dem Ausfall: %d' % (len(vor), len(nach)))
if nach: print('Zeit ohne Antwort ab dem Ausfall bis zur ersten neuen Antwort: %.1f s' % (nach[0] - t0))
else: print('keine Wiederherstellung innerhalb des Messfensters')
PY
ip -n ccs2 link set p12b up; sleep 8
step "4. BPDU Guard als Linux-Entsprechung: ein Port mit guard on wird bei einer BPDU abgeschaltet (kein BPDU Guard im Sinn von IOS)"
ns_up ccsx; link ccs2 s2x ccsx sx0; ip -n ccsx link add br0 type bridge stp_state 1 forward_delay 400 priority 0; ip -n ccsx link set sx0 master br0; ip -n ccsx link set br0 up
ip -n ccs2 link set s2x master br0; ip netns exec ccs2 bridge link set dev s2x guard on; sleep 12
run "ip netns exec ccs2 bridge -d link show dev s2x | grep -oE 'state [a-z]+|guard (on|off)' | paste -sd' '"
echo "Der angeschlossene „Switch“ (Priorität 0) sendet BPDUs; der Port s2x wird daraufhin gesperrt (disabled); das entspricht dem Zweck von BPDU Guard an Zugangsports."
step "4b. Root Guard als Linux-Entsprechung (root_block): ein Port nimmt keine überlegene Root-Information an"
ip -n ccs2 link set s2x nomaster; ip -n ccs2 link set s2x master br0; ip netns exec ccs2 bridge link set dev s2x guard off root_block on
ip -n ccsx link set br0 type bridge priority 0; sleep 12
run "ip netns exec ccs2 bridge -d link show dev s2x | grep -oE 'state [a-z]+|root_block (on|off)' | paste -sd' '"
run "ip -n ccs2 -d link show br0 | grep -oE 'bridge_id [^ ]+' >/dev/null; echo -n 'root_id von ccs2: '; ip netns exec ccs2 cat /sys/class/net/br0/bridge/root_id"
echo "Die angeschlossene Bridge hat Priorität 0 und wäre die bessere Root-Bridge; ccs2 behält ccs1 (Priorität 4096) als Root und übernimmt die bessere Information nicht, solange root_block aktiv ist."
step "5. Schleife ohne STP: eine einzige Broadcast-Anfrage kreist im Dreieck (Zähler eines Anschlusses)"
for s in ccl1 ccl2 ccl3; do ns_up $s; ip -n $s link add br0 type bridge stp_state 0; done
link ccl1 q12a ccl2 q12b; link ccl2 q23a ccl3 q23b; link ccl3 q31a ccl1 q31b
for p in "ccl1 q12a" "ccl2 q12b" "ccl2 q23a" "ccl3 q23b" "ccl3 q31a" "ccl1 q31b"; do set -- $p; ip -n $1 link set $2 master br0; done
for s in ccl1 ccl2 ccl3; do ip -n $s link set br0 up; done; ip -n ccl1 addr add 10.41.0.1/24 dev br0; sleep 1
a=$(ip netns exec ccl1 cat /sys/class/net/q12a/statistics/rx_packets)
(ip netns exec ccl1 ping -c1 -W1 10.41.0.99 >/dev/null 2>&1 &); sleep 2
b=$(ip netns exec ccl1 cat /sys/class/net/q12a/statistics/rx_packets); sleep 1; c=$(ip netns exec ccl1 cat /sys/class/net/q12a/statistics/rx_packets)
echo "Empfangene Pakete an q12a: vor der Anfrage $a, nach 2 s $b, eine Sekunde später $c (Zuwachs $((c-b)) pro Sekunde)"
echo "Der Zähler läuft schon vor der Anfrage hoch, weil beim Einschalten der Schnittstellen automatische Meldungen (zum Beispiel IPv6-Nachbarschaft) in die Schleife geraten. Ohne STP kreisen Broadcasts endlos; die Zähler wachsen dauerhaft, bis die Schleife entfernt wird."
for s in ccl1 ccl2 ccl3; do ip -n $s link del br0; done
step "6. EtherChannel: Lastverteilung per Hash (Modell) und Aushandlung (Lehrbuchwissen)"
python3 - <<'PY'
import zlib, collections
flows = [('192.168.10.%d' % i, '192.168.20.10', 40000 + i) for i in range(1, 41)]
for name, f in [('Quell-MAC (hier: Quell-IP als Ersatz)', lambda x: x[0]), ('Quell- und Ziel-IP', lambda x: x[0] + x[1]), ('nur Ziel-IP', lambda x: x[1])]:
    c = collections.Counter(zlib.crc32(f(x).encode()) % 2 for x in flows)
    print('%-40s Link0 %2d  Link1 %2d  (40 Flüsse)' % (name, c[0], c[1]))
print('Merke: Ein einzelner Fluss nutzt immer nur einen Link; die Verteilung hängt vom gewählten Hash ab.')
print('\nModus-Kombinationen (Lehrbuchwissen): LACP active/active, active/passive -> Channel; passive/passive -> kein Channel; PAgP desirable/auto; on/on ohne Protokoll; LACP mit PAgP -> kein Channel.')
print('Nicht ausgeführt: Rapid PVST+, PortFast, Loop Guard, LACP (kein bonding-Modul im Container), IOS-Befehle.')
PY

#!/usr/bin/env bash
# Modul 7b: NAT/PAT (nftables, echte Adressumsetzung mit Verbindungsverfolgung), Portweiterleitung (DNAT) und NTP (chrony). Linux-Werkzeuge; die Cisco-Befehle (ip nat inside/outside, ntp server) stehen nur in den Aufgaben.
. "$(dirname "$0")/../lab.sh"
lab_up
ns_up ccn1 ccn2 ccnat ccwan ccout ccsw7
link ccn1 n1 ccsw7 sp1; link ccn2 n2 ccsw7 sp2; link ccnat nin ccsw7 sp3; link ccnat nwan ccwan w1; link ccout o0 ccwan w2
ip -n ccsw7 link add br0 type bridge stp_state 0; for p in sp1 sp2 sp3; do ip -n ccsw7 link set $p master br0; done; ip -n ccsw7 link set br0 up
ip -n ccn1 addr add 192.168.1.11/24 dev n1; ip -n ccn2 addr add 192.168.1.12/24 dev n2; ip -n ccnat addr add 192.168.1.1/24 dev nin
for h in ccn1 ccn2; do ip -n $h route add default via 192.168.1.1; done
ip -n ccwan link add br0 type bridge stp_state 0; ip -n ccwan link set w1 master br0; ip -n ccwan link set w2 master br0; ip -n ccwan link set br0 up
ip -n ccnat addr add 203.0.113.1/24 dev nwan; ip -n ccwan addr add 203.0.113.10/24 dev br0; ip -n ccout addr add 203.0.113.60/24 dev o0; fwd ccnat
cat > srv.py <<'C'
import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(s):
        s.send_response(200); s.end_headers(); s.wfile.write(('Anfrage von %s:%d\n' % s.client_address).encode())
    def log_message(*a): pass
http.server.HTTPServer((sys.argv[1], int(sys.argv[2])), H).serve_forever()
C
bgstart ccwan wan 8080 python3 srv.py 203.0.113.10 8080
bgstart ccn1 in1 8080 python3 srv.py 192.168.1.11 8080
step "1. Ohne NAT: private Adressen werden im Internet nicht geroutet; der Server sieht keine Antwortmöglichkeit"
run "ip netns exec ccn1 curl -s -m 2 http://203.0.113.10:8080/ || echo 'keine Antwort (Zeitüberschreitung)'"
step "2. PAT (Masquerading): beide Hosts nutzen denselben lokalen Port 40000; der Router übersetzt die Adresse und weicht bei einem Portkonflikt auf einen anderen Port aus"
cat > nat.nft <<C
table ip nat {
  chain post {
    type nat hook postrouting priority 100;
    oifname "nwan" masquerade
  }
  chain pre {
    type nat hook prerouting priority -100;
    iifname "nwan" tcp dport 8081 dnat to 192.168.1.11:8080
  }
}
C
ip netns exec ccnat nft -f $W/nat.nft
for h in ccn1 ccn2; do run "ip netns exec $h curl -s -m 3 --local-port 40000 http://203.0.113.10:8080/"; done
echo "--- Verbindungstabelle des Routers (Quelle innen -> Quelle nach der Umsetzung)"
ip netns exec ccnat python3 - <<'PY'
import re
for l in open('/proc/net/nf_conntrack'):
    if 'dport=8080' not in l or 'tcp' not in l: continue
    f = re.findall(r'(src|dst|sport|dport)=(\S+)', l)
    o = dict(f[:4]); r = dict(f[4:8])
    print('innen %s:%s -> %s:%s | Antwort kommt von %s:%s an %s:%s' % (o['src'], o['sport'], o['dst'], o['dport'], r['src'], r['sport'], r['dst'], r['dport']))
PY
echo "Der Server sieht beide Hosts mit der Adresse 203.0.113.1 und je einem anderen Quellport; die Zuordnung steht in der Verbindungstabelle."
step "3. Portweiterleitung (DNAT): ein Gerät im Internet erreicht den internen Webserver über die öffentliche Adresse, Port 8081"
run "ip netns exec ccout curl -s -m 3 http://203.0.113.1:8081/"
echo "Der interne Server sieht den Client 203.0.113.60; erreicht wurde 192.168.1.11:8080 über die Adresse und den Port des Routers."
step "4. NTP mit chrony: ein Zeitserver (Schicht 8, im Labor ohne Referenz) und ein Client fragt einmalig ab"
mkdir -p ntp; chmod 777 ntp
cat > ntp/server.conf <<C
port 1123
local stratum 8
allow
bindaddress 203.0.113.10
cmdport 0
pidfile $W/ntp/s.pid
driftfile $W/ntp/drift
C
cat > ntp/client.conf <<C
server 203.0.113.10 port 1123 iburst maxsamples 2
cmdport 0
pidfile $W/ntp/c.pid
C
(ip netns exec ccwan chronyd -x -f $W/ntp/server.conf >$W/ntp/s.log 2>&1 &); sleep 2
(ip netns exec ccwan timeout 10 tcpdump -Z root -U -n -i w1 -w ntp.pcap udp >/dev/null 2>&1 &); sleep 1
run "ip netns exec ccn1 timeout 15 chronyd -Q -x -f $W/ntp/client.conf 2>&1 | sed -E 's/^[0-9-]+T[0-9:]+Z //' | tail -2"
sleep 1; pkill -x tcpdump; sleep 0.5
run "tshark -r ntp.pcap -d udp.port==1123,ntp -T fields -e ip.src -e ip.dst -e ntp.flags.mode -e ntp.stratum 2>/dev/null | awk -F'\\t' '!seen[\$0]++ {print \$1 \" -> \" \$2 \"  Modus \" \$3 \"  Schicht \" \$4}' | head -4"
echo "Modus 3 = Client-Anfrage, Modus 4 = Server-Antwort; der Client hat den Server hinter dem NAT-Router (203.0.113.1) angesprochen, die Quelladresse im Mitschnitt ist die umgesetzte."
pkill -x chronyd
echo "Nicht ausgeführt: IOS-NAT-Befehle (ip nat inside/outside, ip nat pool, overload), NTP-Authentifizierung, NTP auf einem Cisco-Gerät."

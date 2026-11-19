#!/usr/bin/env bash
# Rate Limiting mit limit/meter, Protokollierung mit log/nflog und Zähler; Auswertung mit tcpdump am nflog-Gerät.
. "$(dirname "$0")/../lab.sh"
lab_up
on srv nft -f - <<'RS'
table inet filter {
  set ssh_versuche { type ipv4_addr; size 128; flags dynamic,timeout; timeout 1m; }
  chain input {
    type filter hook input priority 0; policy drop;
    iif "lo" accept
    # 1. ICMP begrenzen, bevor "established" greift: alle Echo-Requests eines ping -i 0.02 gehören zu EINER Verbindung
    icmp type echo-request limit rate 10/second burst 5 packets accept
    icmp type echo-request counter name ping_ueberschuss drop
    ct state established,related accept
    # 2. Neue Verbindungen je Quelladresse begrenzen (meter): max. 3 pro Minute auf Port 8080
    tcp dport 8080 ct state new add @ssh_versuche { ip saddr limit rate over 3/minute burst 3 packets } log prefix "p09-ratelimit: " group 1 counter drop
    tcp dport 8080 accept
    tcp dport 80 log prefix "p09-web: " group 2 accept
  }
  counter ping_ueberschuss { }
}
RS
step "1. Ping-Flut: 40 Pakete mit 20 ms Abstand (50 Pakete pro Sekunde), Limit 10 pro Sekunde, Burst 5"
on cl ping -q -c 40 -i 0.02 -W1 10.0.2.2 | tail -2
on srv nft list counter inet filter ping_ueberschuss
step "2. Neue Verbindungen auf 8080: 6 Versuche in Folge, erwartet werden 3 Treffer und 3 Abweisungen"
for i in 1 2 3 4 5 6; do http_get cl 10.0.2.2 8080; done
step "3. Protokoll der Abweisungen (nflog Gruppe 1, gelesen mit tcpdump)"
( on srv timeout 6 tcpdump -n -l -v -i nflog:1 -c 3 2>/dev/null | sed -E 's/^[0-9:.]+ //' > /tmp/p09-nflog.txt & ) ; sleep 1
for i in 1 2 3; do http_get cl 10.0.2.2 8080 >/dev/null; done
sleep 2; cat /tmp/p09-nflog.txt | head -8
step "4. Web-Zugriffe werden getrennt protokolliert (nflog Gruppe 2; der Präfix ist in tcpdump nicht sichtbar)"
( on srv timeout 5 tcpdump -n -l -v -i nflog:2 -c 1 2>/dev/null | sed -E 's/^[0-9:.]+ //' > /tmp/p09-nflog2.txt & ) ; sleep 1
http_get cl 10.0.2.2 80
sleep 1.5; cat /tmp/p09-nflog2.txt
step "5. Dynamisches Set (Quelladressen, die das Limit überschritten haben)"
on srv nft list set inet filter ssh_versuche
lab_down

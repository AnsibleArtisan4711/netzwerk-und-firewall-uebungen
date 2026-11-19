#!/usr/bin/env bash
# Zeigt die Zustandsverfolgung: Verbindungseinträge, Zustände new/established/related/invalid, UDP und ICMP.
. "$(dirname "$0")/../lab.sh"
lab_up
on fw nft -f - <<'RS'
table inet z {
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state invalid counter drop
    ct state established,related counter accept
    iifname "v-fw1" ct state new tcp dport 80 counter accept
    iifname "v-fw1" ct state new icmp type echo-request counter accept
    iifname "v-fw1" ct state new udp dport 5353 counter accept
  }
}
RS
step "1. Client öffnet HTTP-Verbindung, Firewall-Tabelle danach (Verbindung wird nach Ende noch gehalten: TIME_WAIT)"
on cl curl -s -m 3 -o /dev/null http://10.0.2.2/
on fw conntrack -L -p tcp 2>/dev/null | sed -E 's/ (id|mark)=[0-9]+//; s/use=[0-9]+//'
step "2. Zähler der Regeln"
on fw nft list chain inet z forward | grep counter
step "3. Rückrichtung ohne vorherige Verbindung: Server -> Client wird verworfen"
if on srv curl -s -m 2 -o /dev/null http://10.0.1.2:80/; then echo "Server->Client: OK"; else echo "Server->Client: BLOCKIERT (kein established, kein new aus v-fw2 erlaubt)"; fi
step "4. UDP und ICMP: scheinbar verbindungslos, trotzdem mit Zustand"
on srv python3 -c "
import socket;s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.bind(('0.0.0.0',5353));s.settimeout(3)
d,a=s.recvfrom(100);s.sendto(b'echo:'+d,a)" &
sleep 0.5
on cl python3 -c "
import socket;s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.settimeout(3);s.sendto(b'hallo',('10.0.2.2',5353));print('UDP-Antwort:',s.recvfrom(100)[0])"
on cl ping -c1 -W1 10.0.2.2 >/dev/null
on fw conntrack -L -p udp 2>/dev/null | sed -E 's/ (id|mark)=[0-9]+//; s/use=[0-9]+//'
on fw conntrack -L -p icmp 2>/dev/null | sed -E 's/ (id|mark)=[0-9]+//; s/use=[0-9]+//; s/id=[0-9]+//g'
wait
step "5. Zähler, Zeitlimits und Tabellengröße"
on fw sysctl net.netfilter.nf_conntrack_tcp_timeout_established net.netfilter.nf_conntrack_udp_timeout net.netfilter.nf_conntrack_icmp_timeout 2>&1
on fw conntrack -C 2>&1
lab_down

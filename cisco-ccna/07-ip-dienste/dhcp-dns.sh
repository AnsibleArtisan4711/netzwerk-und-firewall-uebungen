#!/usr/bin/env bash
# Modul 7a: DHCP (Server, Relay, Reservierung) und DNS mit dnsmasq. Linux-Dienste als Modell; auf Cisco-Geräten heißt die Relay-Funktion „ip helper-address“ (hier nicht ausgeführt).
. "$(dirname "$0")/../lab.sh"
lab_up
ns_up ccsrv ccrt cccli
link ccsrv sv0 ccrt rt1; link cccli e0 ccrt rt2
ip -n ccsrv addr add 192.168.10.2/24 dev sv0; ip -n ccsrv route add default via 192.168.10.1
ip -n ccrt addr add 192.168.10.1/24 dev rt1; ip -n ccrt addr add 192.168.20.1/24 dev rt2; fwd ccrt
ip -n cccli link set e0 address 02:00:00:00:00:61
NS1=$(python3 -c "print(''.join('%02x%s' % (len(p), p.encode().hex()) for p in 'ns1.lab.example'.split('.')) + '00')")
cat > dnsmasq.conf <<C
port=53
listen-address=192.168.10.2
bind-interfaces
no-resolv
no-hosts
domain=lab.example
local=/lab.example/
dhcp-range=192.168.20.100,192.168.20.150,255.255.255.0,120s
dhcp-option=3,192.168.20.1
dhcp-option=6,192.168.10.2
dhcp-option=15,lab.example
dhcp-leasefile=$W/leases
dhcp-host=02:00:00:00:00:99,192.168.20.50
host-record=www.lab.example,192.168.10.80,2001:db8:10::80
host-record=mail.lab.example,192.168.10.25
host-record=ns1.lab.example,192.168.10.2
cname=web.lab.example,www.lab.example
mx-host=lab.example,mail.lab.example,10
txt-record=lab.example,"v=spf1 mx -all"
dns-rr=lab.example,2,$NS1
log-dhcp
C
cat > dhs.sh <<'C'
#!/bin/sh
case "$reason" in
 BOUND|REBOOT) echo "dhclient: BOUND -> Adresse $new_ip_address/$new_subnet_mask, Router $new_routers, DNS $new_domain_name_servers, Domäne $new_domain_name, Lease ${new_dhcp_lease_time} s, Server $new_dhcp_server_identifier";;
 *) echo "dhclient: $reason";;
esac
C
chmod +x dhs.sh; : > leases; chmod 666 leases
(ip netns exec ccsrv dnsmasq -k -C $W/dnsmasq.conf --pid-file=$W/dns.pid --log-facility=$W/dnsmasq.log >/dev/null 2>&1 &); sleep 1
dh() { ip netns exec cccli timeout $1 dhclient -1 -v -lf $W/c.lease -pf $W/c.pid -sf $W/dhs.sh e0 2>&1; }; export W; export -f dh
step "1. DHCP ohne Relay scheitert: der Client im Netz 192.168.20.0/24 erreicht den Server im Netz 192.168.10.0/24 nicht per Broadcast"
echo "Erwartung: nur DHCPDISCOVER an 255.255.255.255, kein DHCPOFFER (der Router leitet Broadcasts nicht weiter)."
run "dh 6 | grep -E 'DHCPDISCOVER|DHCPOFFER|DHCPREQUEST|DHCPACK|No DHCPOFFERS|bound|dhclient:' | sed -E 's/ interval [0-9]+//; s/ from 02.*//' | sort -u | head -5"
pkill -f "dhclient.*e0" 2>/dev/null; rm -f c.lease
step "2. Relay auf dem Router (dnsmasq --dhcp-relay), danach DORA im Mitschnitt"
(ip netns exec ccrt dnsmasq -k --conf-file=/dev/null --port=0 --dhcp-relay=192.168.20.1,192.168.10.2 --pid-file=$W/relay.pid >$W/relay.log 2>&1 &); sleep 1
(ip netns exec ccsrv timeout 12 tcpdump -Z root -U -n -i sv0 -w d.pcap "udp port 67 or udp port 68" >/dev/null 2>&1 &); sleep 1
run "dh 8 | grep -E 'DHCPOFFER|DHCPACK|dhclient:' | sed -E 's/ interval [0-9]+//' | sort -u"
sleep 1; pkill -x tcpdump; sleep 0.5; pkill -f "dhclient.*e0" 2>/dev/null
run "tshark -r d.pcap -T fields -e ip.src -e ip.dst -e bootp.option.dhcp -e bootp.ip.relay 2>/dev/null | awk -F'\\t' '!seen[\$0]++ {print \$1 \" -> \" \$2 \"  Typ \" \$3 \"  giaddr \" \$4}'"
echo "(Doppelte Pakete des Relays sind zusammengefasst.) Typ 1 = Discover, 2 = Offer, 3 = Request, 5 = Ack. Auf dem Server-Anschluss steht die Adresse des Relays (giaddr) als Quelle, nicht der Client."
run "cat $W/leases | awk '{print \$2, \$3}'"
step "3. Reservierung: ein Gerät mit der MAC 02:00:00:00:00:99 bekommt immer 192.168.20.50"
rm -f c.lease; ip -n cccli link set e0 down; ip -n cccli link set e0 address 02:00:00:00:00:99; ip -n cccli link set e0 up; ip -n cccli addr flush dev e0
run "dh 8 | grep -E 'dhclient:' | sed -E 's/, Lease.*//'"
pkill -f "dhclient.*e0" 2>/dev/null
step "4. Namensauflösung mit dig gegen den DNS-Server 192.168.10.2"
D="ip netns exec cccli dig +short +time=2 +tries=1 @192.168.10.2"
ip -n cccli link set e0 up; ip -n cccli addr add 192.168.20.77/24 dev e0 2>/dev/null; ip -n cccli route add default via 192.168.20.1 2>/dev/null
for q in "www.lab.example A" "www.lab.example AAAA" "web.lab.example CNAME" "lab.example MX" "lab.example TXT" "lab.example NS" "80.10.168.192.in-addr.arpa PTR"; do run "$D $q | sed 's/^/  /'"; done
run "ip netns exec cccli dig +time=2 +tries=1 @192.168.10.2 gibtesnicht.lab.example A | grep -E 'status:' | sed -E 's/.*(status: [A-Z]+).*/\\1/'"
echo "Hinweis: Der PTR-Eintrag für 80.10.168.192.in-addr.arpa wird von dnsmasq automatisch aus dem host-record erzeugt."
echo "Nicht ausgeführt: DHCPv6, SLAAC-Mitschnitt, „ip helper-address“ und „ip dhcp pool“ auf einem Cisco-Gerät."

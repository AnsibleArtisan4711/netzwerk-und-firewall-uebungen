#!/usr/bin/env bash
# Modul 6: DHCP und DNS auf der Firewall. OPNsense bringt eigene Dienste mit; hier wird dnsmasq als Stand-in verwendet.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
# Client ohne Adresse
on cl ip addr flush dev v-cl; on cl ip route flush all
# Upstream-DNS im WAN-Namespace
cat > /tmp/p08-upstream.conf <<'RS'
port=53
listen-address=10.8.9.1
bind-interfaces
no-resolv
no-hosts
address=/extern.test/10.8.9.1
pid-file=/tmp/p08-upstream.pid
RS
(setsid ip netns exec p08-wan dnsmasq -C /tmp/p08-upstream.conf >/dev/null 2>&1 &)
# DHCP/DNS auf der Firewall (LAN)
sed -e 's#@LEASES@#/tmp/p08-leases#' "$D/dnsmasq-lan.conf" > /tmp/p08-lan.conf
rm -f /tmp/p08-leases; (setsid ip netns exec p08-fw dnsmasq -C /tmp/p08-lan.conf >/dev/null 2>&1 &)
sleep 1
step "1. Konfiguration des Dienstes (dnsmasq-lan.conf)"
grep -v "^#" /tmp/p08-lan.conf | grep -v "^$"
step "2. DHCP-Client im LAN fordert eine Adresse an (Hook statt dhclient-script, damit /etc unberührt bleibt)"
rm -f /tmp/p08-hook.out
timeout 20 ip netns exec p08-cl dhclient -1 -4 -v -sf "$D/dhcp-hook.sh" -pf /tmp/p08-dhc.pid -lf /tmp/p08-dhc.leases v-cl 2>&1 | grep -E 'DHCP(DISCOVER|OFFER|REQUEST|ACK)|bound to' | sed -E 's/ \(xid=[^)]*\)//; s/ port [0-9]+//'
cat /tmp/p08-hook.out 2>/dev/null
cmd on cl ip -br addr show v-cl
step "3. Lease-Tabelle auf der Firewall (Zeitstempel entfernt)"
awk '{print $2, $3, $4}' /tmp/p08-leases
step "4. DNS: lokaler Eintrag, Weiterleitung an den Upstream und nicht vorhandener Name"
cmd on cl dig +short @10.8.1.1 srv.lab.test
cmd on cl dig +short @10.8.1.1 extern.test
cmd on cl dig @10.8.1.1 gibtsnicht.test +noall +comments | grep -o 'status: [A-Z]*'
step "5. Statische Zuordnung: Gerät mit bekannter MAC bekommt immer dieselbe Adresse"
on cl ip link set v-cl down; on cl ip link set v-cl address 02:00:00:aa:bb:01; on cl ip addr flush dev v-cl; on cl ip link set v-cl up
rm -f /tmp/p08-dhc.leases
timeout 20 ip netns exec p08-cl dhclient -1 -4 -sf "$D/dhcp-hook.sh" -pf /tmp/p08-dhc.pid -lf /tmp/p08-dhc.leases v-cl >/dev/null 2>&1
cmd on cl ip -br addr show v-cl
step "6. Ausfall des Dienstes: ohne DNS auf der Firewall keine Namensauflösung, Adressen bleiben nutzbar"
kill $(cat /tmp/p08-lan.pid 2>/dev/null) 2>/dev/null; sleep 0.5
cmd on cl dig +short +time=1 +tries=1 @10.8.1.1 srv.lab.test
test_ping cl 10.8.1.1
kill $(cat /tmp/p08-upstream.pid) 2>/dev/null
rm -f /tmp/p08-*.conf /tmp/p08-leases /tmp/p08-dhc.* /tmp/p08-hook.out /tmp/p08-*.pid
lab_down

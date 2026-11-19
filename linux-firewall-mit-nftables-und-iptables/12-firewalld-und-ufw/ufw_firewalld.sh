#!/usr/bin/env bash
# ufw (Server) und firewalld (Router) in Grundzügen: Dienste freigeben, Zonen, Richtlinien (policies), NAT; Blick auf die erzeugten Regeln.
. "$(dirname "$0")/../lab.sh"
PY=/usr/bin/python3.12      # firewall-cmd braucht die System-Python-Module (python3-dbus, python3-gi)
fwc() { on fw $PY /usr/bin/firewall-cmd "$@"; }
aufraeumen() { rm -f /etc/firewalld/policies/lan_zu_srv.xml* /etc/firewalld/zones/internal.xml* /etc/firewalld/zones/external.xml*; }
aufraeumen   # Reste früherer Läufe entfernen
lab_up
step "TEIL A: ufw auf dem Server"
cmd on srv ufw --force reset >/dev/null
cmd on srv ufw default deny incoming
cmd on srv ufw allow 80/tcp
cmd on srv ufw allow from 10.0.1.0/24 to any port 8080 proto tcp
cmd on srv ufw limit 22/tcp
cmd on srv ufw --force enable
cmd on srv ufw status numbered
http_get cl 10.0.2.2 80; http_get cl 10.0.2.2 8080
step "A2. Was ufw darunter anlegt (Auszug aus iptables -S, nur Regeln mit Port 80 und 8080)"
on srv iptables -S | grep -E "dpt:(80|8080)|--dport (80|8080)" | head -6
on srv ufw --force disable >/dev/null; on srv ufw --force reset >/dev/null
step "TEIL B: firewalld auf der Firewall (Zonen: internal = LAN, external = Server-Seite)"
( setsid ip netns exec $NS_FW $PY /usr/sbin/firewalld --nofork --nopid >/tmp/p09-firewalld.log 2>&1 < /dev/null & ); sleep 5
cmd fwc --state
cmd fwc --get-zones
cmd fwc --permanent --zone=internal --change-interface=v-fw1
cmd fwc --permanent --zone=external --change-interface=v-fw2
step "B2. Richtlinie internal -> external: nur Port 80 (rich rule); Policies lassen sich nur dauerhaft anlegen"
cmd fwc --permanent --new-policy lan_zu_srv
cmd fwc --permanent --policy lan_zu_srv --add-ingress-zone internal
cmd fwc --permanent --policy lan_zu_srv --add-egress-zone external
cmd fwc --permanent --policy lan_zu_srv --set-target REJECT
cmd fwc --permanent --policy lan_zu_srv --add-rich-rule 'rule family="ipv4" port port="80" protocol="tcp" accept'
step "B3. Vorher/nachher: Ohne reload ist die dauerhafte Konfiguration noch nicht aktiv"
http_get cl 10.0.2.2 80
cmd fwc --reload
cmd fwc --get-active-zones
http_get cl 10.0.2.2 80; http_get cl 10.0.2.2 8080
cmd fwc --zone=external --query-masquerade
step "B4. Dienst auf der Firewall selbst freigeben (SSH ist in internal schon erlaubt) und Laufzeit gegen Dauerhaft"
cmd fwc --zone=internal --add-service=http
cmd fwc --zone=internal --list-all
cmd fwc --zone=internal --add-port=3128/tcp --permanent
cmd fwc --zone=internal --query-port=3128/tcp
cmd fwc --reload
cmd fwc --zone=internal --query-port=3128/tcp
step "B5. Was firewalld daraus in nftables macht (nur Tabellen und Ketten-Anzahl)"
on fw nft list tables
echo "Ketten: $(on fw nft list chains | grep -c '^\s*chain')   Zeilen im Regelwerk: $(on fw nft list ruleset | wc -l)"
lab_down
aufraeumen

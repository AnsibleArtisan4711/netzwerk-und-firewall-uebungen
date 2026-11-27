#!/usr/bin/env bash
# Modul 9: Zugriffskontrolle und Sicherheit. Echt: SSH-Härtung mit OpenSSH (Schlüssel, sshd -T), Paketfilter mit nftables als Modell für ACLs. Modell (Python): ACL-Auswertung mit Wildcard-Masken, Port-Security, DHCP Snooping, DAI, AAA-Vergleich.
# Nicht ausgeführt: IOS-Befehle (ip access-list, switchport port-security, ip dhcp snooping, ip arp inspection, aaa new-model).
. "$(dirname "$0")/../lab.sh"
lab_up
chmod 755 $W   # sshd prüft die Rechte der Verzeichnisse (StrictModes)
step "1. SSH-Härtung: Schlüssel erzeugen, Server prüfen (sshd -T), Anmeldung mit Schlüssel, Passwort abgelehnt"
mkdir -p ssh; ssh-keygen -q -t ed25519 -N '' -f ssh/hostkey; ssh-keygen -q -t ed25519 -N '' -f ssh/admin -C admin@lab
cat > ssh/sshd.conf <<C
Port 2222
ListenAddress 127.0.0.1
HostKey $W/ssh/hostkey
PidFile $W/ssh/sshd.pid
AuthorizedKeysFile $W/ssh/authorized_keys
PermitRootLogin prohibit-password
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
StrictModes no   # nur im Labor: die Schlüssel liegen unter /tmp (auf Produktivsystemen bleibt StrictModes yes)
MaxAuthTries 2
LoginGraceTime 20
ClientAliveInterval 60
ClientAliveCountMax 3
LogLevel VERBOSE
C
cp ssh/admin.pub ssh/authorized_keys; chmod 600 ssh/authorized_keys
run "/usr/sbin/sshd -t -f $W/ssh/sshd.conf && echo Syntax-OK"
run "/usr/sbin/sshd -T -f $W/ssh/sshd.conf 2>/dev/null | grep -E '^(port|permitrootlogin|passwordauthentication|pubkeyauthentication|maxauthtries|logingracetime|clientaliveinterval|clientalivecountmax) '"
mkdir -p /run/sshd; ip netns add ccssh 2>/dev/null; ip -n ccssh link set lo up
ip netns exec ccssh /usr/sbin/sshd -f $W/ssh/sshd.conf -E $W/ssh/sshd.log; sleep 1
run "ip netns exec ccssh ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -i $W/ssh/admin -p 2222 root@127.0.0.1 'echo Anmeldung mit Schlüssel erfolgreich; id -un' 2>&1 | grep -v Warning"
run "ip netns exec ccssh ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o PreferredAuthentications=password -o PubkeyAuthentication=no -o BatchMode=yes -p 2222 root@127.0.0.1 true 2>&1 | grep -v Warning"
run "grep -E 'Accepted publickey|Connection closed|no authentication|Failed' $W/ssh/sshd.log | sed -E 's/^.*sshd(\\[[0-9]+\\])?: //; s/ port [0-9]+//; s/SHA256:[A-Za-z0-9+\\/]+/SHA256:.../' | sort -u | head -4"
pkill -f "$W/ssh/sshd.conf"
step "2. ACL-Auswertung als Python-Modell: Reihenfolge, Wildcard-Maske, implizites Deny am Ende"
python3 - <<'PY'
import ipaddress
def wild_to_net(addr, wild):
    a = int(ipaddress.ip_address(addr)); w = int(ipaddress.ip_address(wild)); return a & ~w & 0xFFFFFFFF, ~w & 0xFFFFFFFF
def match(ip, addr, wild):
    if addr == 'any': return True
    n, mask = wild_to_net(addr, wild); return (int(ipaddress.ip_address(ip)) & mask) == n
class Ace:
    def __init__(s, aktion, proto, src, sw, dst='any', dw='0.0.0.0', port=None): s.__dict__.update(locals())
    def trifft(s, p):
        return s.proto in ('ip', p['proto']) and match(p['src'], s.src, s.sw) and match(p['dst'], s.dst, s.dw) and (s.port is None or s.port == p['dport'])
def pruefe(acl, p):
    for i, e in enumerate(acl, 1):
        if e.trifft(p): return e.aktion, 'Zeile %d' % (i * 10)
    return 'deny', 'implizites Deny'
acl = [Ace('deny', 'tcp', '192.168.10.50', '0.0.0.0', '192.168.20.0', '0.0.0.255', 80),
       Ace('permit', 'tcp', '192.168.10.0', '0.0.0.255', '192.168.20.0', '0.0.0.255', 80),
       Ace('permit', 'icmp', '192.168.10.0', '0.0.0.255')]
tests = [('192.168.10.50', '192.168.20.10', 'tcp', 80), ('192.168.10.51', '192.168.20.10', 'tcp', 80), ('192.168.10.51', '192.168.20.10', 'tcp', 22), ('192.168.30.5', '192.168.20.10', 'tcp', 80), ('192.168.10.51', '192.168.20.10', 'icmp', None)]
print('ACL: 10 deny tcp host 192.168.10.50 -> 192.168.20.0/24 eq 80 | 20 permit tcp 192.168.10.0/24 -> 192.168.20.0/24 eq 80 | 30 permit icmp 192.168.10.0/24 -> any')
for s, d, pr, po in tests:
    a, w = pruefe(acl, dict(src=s, dst=d, proto=pr, dport=po)); print('%-14s -> %-14s %-4s %-5s : %-6s (%s)' % (s, d, pr, po or '-', a, w))
acl2 = [acl[1], acl[0], acl[2]]
a, w = pruefe(acl2, dict(src='192.168.10.50', dst='192.168.20.10', proto='tcp', dport=80))
print('Reihenfolge vertauscht (permit vor deny): 192.168.10.50 -> Port 80 :', a, '(%s, jetzt als erste Zeile) – die Reihenfolge entscheidet.' % w)
for addr, w in (('192.168.10.0', '0.0.0.255'), ('10.1.4.0', '0.0.3.255'), ('172.16.0.0', '0.15.255.255'), ('192.168.1.64', '0.0.0.31')):
    n, m = wild_to_net(addr, w); net = ipaddress.ip_network('%s/%d' % (ipaddress.ip_address(n), bin(m).count('1')), strict=False)
    print('Wildcard %-12s mit %-12s entspricht %s' % (w, addr, net))
print('Merkregel (Lehrbuchwissen): Standard-ACLs prüfen nur die Quelladresse und stehen nahe am Ziel; erweiterte ACLs prüfen Quelle, Ziel und Port und stehen nahe an der Quelle.')
PY
step "3. Paketfilter als Gegenstück (nftables, echter Lauf): Reihenfolge der Regeln, Standard-Verwerfen, Zähler"
ns_up ccacl1 ccacl2 ccrt ccweb
link ccacl1 e0 ccrt g0; link ccacl2 e0 ccrt g1; link ccweb e0 ccrt g2
ip -n ccacl1 addr add 192.168.10.51/24 dev e0; ip -n ccacl2 addr add 192.168.10.50/24 dev e0
ip -n ccrt link add br0 type bridge; ip -n ccrt link set br0 up; ip -n ccrt link set g0 master br0; ip -n ccrt link set g1 master br0; ip -n ccrt addr add 192.168.10.1/24 dev br0
ip -n ccrt addr add 192.168.20.1/24 dev g2; ip -n ccweb addr add 192.168.20.10/24 dev e0
ip -n ccacl1 route add default via 192.168.10.1; ip -n ccacl2 route add default via 192.168.10.1; ip -n ccweb route add default via 192.168.20.1; fwd ccrt
bgstart ccweb web 80 python3 -m http.server 80 --bind 192.168.20.10
cat > acl.nft <<'N'
table inet filter {
  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    ip saddr 192.168.10.50 tcp dport 80 counter drop comment "Zeile 10"
    ip saddr 192.168.10.0/24 ip daddr 192.168.20.0/24 tcp dport 80 counter accept comment "Zeile 20"
    ip saddr 192.168.10.0/24 icmp type echo-request counter accept comment "Zeile 30"
  }
}
N
ip netns exec ccrt nft -f acl.nft
run "ip netns exec ccacl1 curl -s -o /dev/null -w 'HTTP %{http_code}\\n' --max-time 2 http://192.168.20.10/"
run "ip netns exec ccacl2 curl -s -o /dev/null -w 'HTTP %{http_code}\\n' --max-time 2 http://192.168.20.10/ ; echo curl-Rückgabewert \$?"
run "ip netns exec ccacl1 ping -c1 -W1 192.168.20.10 | grep transmitted | sed 's/, time.*//'"
run "ip netns exec ccacl1 curl -s -o /dev/null -w 'HTTP %{http_code}\\n' --max-time 2 http://192.168.20.10:22/ ; echo curl-Rückgabewert \$?"
run "ip netns exec ccrt nft list chain inet filter forward | grep -E 'counter' | sed -E 's/^[ \\t]+//; s/ bytes [0-9]+//'"
step "4. Port-Security als Python-Modell: maximale Adressen, Sticky, Violation-Modi"
python3 - <<'PY'
class Port:
    def __init__(s, maxmac=1, modus='shutdown', sticky=True): s.max, s.modus, s.sticky, s.macs, s.zustand, s.verletzungen = maxmac, modus, sticky, [], 'up', 0
    def frame(s, mac):
        if s.zustand != 'up': return 'Port err-disabled: Rahmen verworfen'
        if mac in s.macs: return 'weitergeleitet'
        if len(s.macs) < s.max:
            s.macs.append(mac); return 'weitergeleitet (MAC gelernt%s)' % (', sticky' if s.sticky else '')
        s.verletzungen += 1
        if s.modus == 'protect': return 'verworfen (still)'
        if s.modus == 'restrict': return 'verworfen, Meldung und Zähler %d' % s.verletzungen
        s.zustand = 'err-disabled'; return 'Verstoß: Port wird abgeschaltet (err-disabled)'
for modus in ('protect', 'restrict', 'shutdown'):
    p = Port(1, modus); print('--- Modus %s, Maximum 1' % modus)
    for mac in ('aa:aa:aa:00:00:01', 'aa:aa:aa:00:00:02', 'aa:aa:aa:00:00:01'): print('   Rahmen von %s: %s' % (mac, p.frame(mac)))
print('Grenze der Methode: MAC-Adressen lassen sich fälschen; Port-Security ersetzt keine 802.1X-Anmeldung.')
PY
step "5. DHCP Snooping und Dynamic ARP Inspection als Python-Modell"
python3 - <<'PY'
vertraut = {'Gi0/24'}
bindings = {}
def dhcp(port, typ, mac, ip=None):
    if typ in ('offer', 'ack') and port not in vertraut: return 'verworfen: Serverantwort auf nicht vertrauenswürdigem Port %s' % port
    if typ == 'ack': bindings[ip] = (mac, port)
    return 'weitergeleitet' + (' (Binding %s -> %s auf %s)' % (ip, mac, port) if typ == 'ack' else '')
def arp(port, src_ip, src_mac):
    if port in vertraut: return 'weitergeleitet (vertrauenswürdig)'
    b = bindings.get(src_ip)
    return 'weitergeleitet' if b == (src_mac, port) else 'verworfen: ARP-Absender passt nicht zum DHCP-Binding'
print('Angreifer auf Fa0/5 sendet DHCP-Offer:', dhcp('Fa0/5', 'offer', 'aa:aa:aa:00:00:66'))
print('Echter Server an Gi0/24 sendet ACK:   ', dhcp('Gi0/24', 'ack', 'aa:aa:aa:00:00:10', '192.168.10.20'))
bindings['192.168.10.20'] = ('aa:aa:aa:00:00:20', 'Fa0/2')
print('Client Fa0/2 sendet ARP mit eigener Adresse:       ', arp('Fa0/2', '192.168.10.20', 'aa:aa:aa:00:00:20'))
print('Angreifer Fa0/5 gibt sich als 192.168.10.1 aus:   ', arp('Fa0/5', '192.168.10.1', 'aa:aa:aa:00:00:66'))
print('Statisch konfigurierte Hosts ohne DHCP haben kein Binding und würden von DAI verworfen, wenn kein ARP-ACL-Eintrag besteht.')
PY
step "5b. Storm Control als Python-Modell: Schwellwert für Broadcast je Sekunde (RA Guard ist IPv6 und hier nicht ausgeführt)"
python3 - <<'PY'
def storm(rate_pps, linie=148810, schwelle=0.10, aktion='drop'):
    anteil = rate_pps / linie
    if anteil <= schwelle: return 'Broadcast %.1f %% der Leitungskapazität: unter der Schwelle, alles wird weitergeleitet' % (anteil * 100)
    return 'Broadcast %.1f %% der Leitungskapazität: über der Schwelle (%d %%), Aktion %s' % (anteil * 100, schwelle * 100, aktion)
print('Annahme: 100-Mbit/s-Port mit rund 148810 kleinen Paketen je Sekunde als volle Kapazität, Schwelle 10 %')
for r in (500, 8000, 90000): print('  %6d pps: %s' % (r, storm(r)))
print('Hinweis: Storm Control begrenzt Broadcast, Multicast oder unbekanntes Unicast je Port; es ersetzt keine Schleifenvermeidung durch Spanning Tree (Modul 4). RA Guard (v2.0 4.7.d) filtert unerwünschte IPv6-Router-Advertisements an Zugangsports und ist im Container nicht ausführbar.')
PY
step "6. AAA: Protokollvergleich (Lehrbuchwissen) und Kennwortspeicherung"
python3 - <<'PY'
tab = [('Merkmal', 'RADIUS', 'TACACS+'), ('Transport', 'UDP (1812/1813, früher 1645/1646)', 'TCP 49'), ('AAA-Trennung', 'Authentifizierung und Autorisierung gemeinsam', 'getrennt'), ('Verschlüsselung', 'nur das Kennwort im Paket', 'der gesamte Paketinhalt'), ('typischer Einsatz', 'Netzzugang (802.1X, VPN, WLAN)', 'Geräteadministration')]
for r in tab: print('%-18s %-45s %s' % r)
print('Kennwortspeicherung auf Cisco-Geräten (Lehrbuchwissen, auf IOS nicht bestätigt): Typ 0 Klartext, Typ 7 umkehrbare Verschleierung, Typ 5 MD5-Hash, Typ 8 PBKDF2-SHA-256, Typ 9 scrypt.')
PY

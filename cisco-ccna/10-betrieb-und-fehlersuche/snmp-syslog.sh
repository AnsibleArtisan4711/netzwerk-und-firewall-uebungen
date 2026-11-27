#!/usr/bin/env bash
# Modul 10a: Überwachung und Protokollierung mit SNMP (snmpd, Net-SNMP) und Syslog (rsyslog), plus Konfigurationssicherung. Linux-Dienste; die IOS-Befehle (snmp-server, logging host) stehen nur in der Aufgabe.
. "$(dirname "$0")/../lab.sh"
lab_up
chmod 755 $W
ns_up ccmon ccpeer
link ccmon m0 ccpeer m1
ip -n ccmon addr add 10.7.0.1/24 dev m0; ip -n ccpeer addr add 10.7.0.2/24 dev m1
mkdir -p snmp
cat > snmp/snmpd.conf <<C
agentAddress udp:127.0.0.1:1161
rocommunity labro 127.0.0.1
sysLocation Labor Raum 1
sysContact admin@lab.example
sysName sw-lab-01
persistentDir $W/snmp
createUser labv3 SHA authpass123 AES privpass123
rouser labv3 priv
C
bgstart ccmon snmpd 1161 snmpd -f -C -c $W/snmp/snmpd.conf -p $W/snmp/snmpd.pid -Lf $W/snmp/snmpd.log
step "1. SNMPv2c: Geräteangaben lesen (numerische OIDs, keine MIB-Dateien installiert)"
G="ip netns exec ccmon snmpget -v2c -c labro -On -Oqv -t1 -r1 127.0.0.1:1161"
for o in "1.3.6.1.2.1.1.5.0 sysName" "1.3.6.1.2.1.1.6.0 sysLocation" "1.3.6.1.2.1.1.4.0 sysContact"; do set -- $o; run "$G $1 | sed 's/^/$2 ($1): /'"; done
run "ip netns exec ccmon snmpget -v2c -c labro -On -Oqv -t1 -r1 127.0.0.1:1161 1.3.6.1.2.1.1.1.0 | cut -c1-60 | sed 's/^/sysDescr (1.3.6.1.2.1.1.1.0): /'"
run "ip netns exec ccmon snmpwalk -v2c -c labro -On -Oqv -t1 -r1 127.0.0.1:1161 1.3.6.1.2.1.2.2.1.2 | tr '\n' ' '; echo"
echo "--- falsche Community: keine Antwort (Zeitüberschreitung)"
run "ip netns exec ccmon snmpget -v2c -c falsch -t1 -r0 127.0.0.1:1161 1.3.6.1.2.1.1.5.0 2>&1 | head -1"
step "2. SNMPv3 mit Authentifizierung und Verschlüsselung (authPriv: SHA und AES)"
run "ip netns exec ccmon snmpget -v3 -l authPriv -u labv3 -a SHA -A authpass123 -x AES -X privpass123 -On -Oqv -t1 -r0 127.0.0.1:1161 1.3.6.1.2.1.1.5.0"
run "ip netns exec ccmon snmpget -v3 -l authPriv -u labv3 -a SHA -A falsches-pw -x AES -X privpass123 -t1 -r0 127.0.0.1:1161 1.3.6.1.2.1.1.5.0 2>&1 | head -1"
run "ip netns exec ccmon snmpget -v3 -l noAuthNoPriv -u labv3 -t1 -r0 127.0.0.1:1161 1.3.6.1.2.1.1.5.0 2>&1 | head -1"
step "3. Polling und Auslastung: Zähler zweimal lesen (Verkehr von ccpeer über m1 nach m0 erzeugen)"
IFI=$(ip netns exec ccmon snmpwalk -v2c -c labro -On -t1 127.0.0.1:1161 1.3.6.1.2.1.2.2.1.2 | grep 'STRING: "m0"' | sed -E 's/.*2\.2\.1\.2\.([0-9]+) .*/\1/')
echo "Schnittstelle m0 hat den Index $IFI (aus ifDescr)"
p() { ip netns exec ccmon snmpget -v2c -c labro -On -Oqv -t1 127.0.0.1:1161 1.3.6.1.2.1.2.2.1.10.$IFI 1.3.6.1.2.1.31.1.1.1.15.$IFI | tr '\n' ' '; }
(ip netns exec ccpeer timeout 8 ping -q -f -s 1000 10.7.0.1 >/dev/null 2>&1 &) ; sleep 2; t0=$(date +%s.%N); a=$(p); sleep 3; b=$(p); t1=$(date +%s.%N)
python3 - "$a" "$b" "$t0" "$t1" <<'PY'
import sys
a, b = [list(map(int, x.split())) for x in sys.argv[1:3]]; dt = float(sys.argv[4]) - float(sys.argv[3])
rate = (b[0] - a[0]) * 8 / dt
print('ifInOctets: %d -> %d in %.1f s = %.1f Mbit/s; ifHighSpeed meldet %d Mbit/s -> Auslastung %.3f %%' % (a[0], b[0], dt, rate / 1e6, a[1], rate / 1e6 / a[1] * 100))
print('Zählerüberlauf: ein 32-Bit-Zähler (ifInOctets) läuft bei 4294967296 über; bei 1 Gbit/s nach rund %.0f Sekunden. Daher bei schnellen Schnittstellen 64-Bit-Zähler (ifHCInOctets) verwenden.' % (4294967296 * 8 / 1e9))
PY
pkill ping
step "4. SNMP-Trap an einen Empfänger (snmptrapd) – wichtiges Ereignis ohne Abfrage"
if which snmptrapd >/dev/null 2>&1; then
  printf 'authCommunity log,execute,net labtrap\n' > snmp/snmptrapd.conf
  (ip netns exec ccmon snmptrapd -f -Lf $W/snmp/trap.log -c $W/snmp/snmptrapd.conf -p $W/snmp/trapd.pid udp:127.0.0.1:1162 >/dev/null 2>&1 &); sleep 2
  ip netns exec ccmon snmptrap -v2c -c labtrap 127.0.0.1:1162 '' 1.3.6.1.6.3.1.1.5.3 1.3.6.1.2.1.2.2.1.1.2 i 2 >/dev/null 2>&1; sleep 1.5
  run "grep -c 'iso.3.6.1.6.3.1.1.5.3' $W/snmp/trap.log | sed 's/^/Einträge zum linkDown-Trap (iso.3.6.1.6.3.1.1.5.3) im Trap-Protokoll: /'"
  run "tr '\\t' '\\n' < $W/snmp/trap.log | grep -E 'snmpTrapOID|1.1.4.1.0|2.2.1.1.2' | sed 's/^/  /'"
else echo "snmptrapd ist nicht installiert: Trap-Empfang nicht ausgeführt."; fi
pkill snmptrapd; pkill snmpd
step "5. Syslog: Schweregrade (0 bis 7) und zentrale Sammlung mit rsyslog"
cat > rsyslog.conf <<C
module(load="imudp")
input(type="imudp" port="5514" address="127.0.0.1")
template(name="Z" type="string" string="%syslogfacility-text%.%syslogseverity-text% %hostname% %syslogtag%%msg%\n")
if \$syslogseverity <= 4 then action(type="omfile" file="$W/warn.log" template="Z")
action(type="omfile" file="$W/alle.log" template="Z")
C
bgstart ccmon rsyslogd 5514 rsyslogd -n -f $W/rsyslog.conf -i $W/rsyslog.pid
ip netns exec ccmon python3 - <<'PY'
import socket, time
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
msgs = [(23, 3, 'sw-lab-01', '%LINK-3-UPDOWN: Interface GigabitEthernet0/1, changed state to down'),
        (23, 5, 'sw-lab-01', '%SYS-5-CONFIG_I: Configured from console by admin'),
        (23, 4, 'sw-lab-01', '%SPANTREE-4-BLOCK_BPDUGUARD: Received BPDU on port Fa0/5 with BPDU Guard enabled'),
        (23, 6, 'sw-lab-01', '%LINEPROTO-6-UPDOWN: Line protocol on Interface Vlan10, changed state to up'),
        (23, 7, 'sw-lab-01', 'debug: ARP packet received'),
        (23, 2, 'sw-lab-01', '%SYS-2-MALLOCFAIL: Memory allocation failed')]
for fac, sev, host, text in msgs:
    s.sendto(('<%d>%s %s %s' % (fac * 8 + sev, time.strftime('%b %d %H:%M:%S'), host, text)).encode(), ('127.0.0.1', 5514))
PY
sleep 1.5
run "echo 'alle.log:'; sed 's/^/  /' $W/alle.log"
run "echo 'warn.log (Schweregrad 4 und niedriger = Warning bis Emergency):'; sed 's/^/  /' $W/warn.log"
pkill rsyslogd
echo "Meldungsformat der Cisco-Texte (Lehrbuchwissen): %FACILITY-SEVERITY-MNEMONIC: Text. Die Nachrichten oben sind von mir gebildet, nicht von einem Gerät erzeugt."
python3 - <<'PY'
print('Schweregrade: ' + ', '.join('%d %s' % (i, n) for i, n in enumerate(['emergencies', 'alerts', 'critical', 'errors', 'warnings', 'notifications', 'informational', 'debugging'])))
print('Ein Schwellwert "logging trap warnings" bedeutet: Schweregrad 0 bis 4 werden gesendet (Lehrbuchwissen, nicht auf IOS ausgeführt).')
PY
step "6. Konfigurationssicherung und Änderungsvergleich (diff, Prüfsumme)"
mkdir -p cfg; cat > cfg/sw-lab-01.v1 <<'C'
hostname sw-lab-01
interface GigabitEthernet0/1
 description Uplink
 switchport mode trunk
interface GigabitEthernet0/2
 switchport access vlan 10
ntp server 203.0.113.80
C
sed 's/switchport access vlan 10/switchport access vlan 20/; s/ntp server 203.0.113.80/ntp server 203.0.113.81/' cfg/sw-lab-01.v1 > cfg/sw-lab-01.v2
run "sha256sum cfg/sw-lab-01.v1 cfg/sw-lab-01.v2 | cut -c1-16,65-"
run "diff -u cfg/sw-lab-01.v1 cfg/sw-lab-01.v2 | tail -n +3"
echo "Sicherung ohne Zugangsdaten: Konfigurationen können Kennwörter oder Community-Strings enthalten und gehören in ein zugriffsgeschütztes Archiv."
step "7. Sichere Dateiübertragung der Sicherung per SFTP und SCP (OpenSSH, Linux); unverschlüsselte Verfahren wie TFTP und FTP kommen nicht zum Einsatz"
mkdir -p ssh sicherung; ssh-keygen -q -t ed25519 -N '' -f ssh/hostkey; ssh-keygen -q -t ed25519 -N '' -f ssh/admin -C backup@lab; cp ssh/admin.pub ssh/authorized_keys
cat > ssh/sshd.conf <<C
Port 2223
ListenAddress 127.0.0.1
HostKey $W/ssh/hostkey
PidFile $W/ssh/sshd.pid
AuthorizedKeysFile $W/ssh/authorized_keys
PasswordAuthentication no
StrictModes no
Subsystem sftp /usr/lib/openssh/sftp-server
C
mkdir -p /run/sshd; ip netns exec ccmon /usr/sbin/sshd -f $W/ssh/sshd.conf -E $W/ssh/sshd.log; sleep 1
O="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o LogLevel=ERROR -i $W/ssh/admin"
run "ip netns exec ccmon scp $O -P 2223 cfg/sw-lab-01.v2 root@127.0.0.1:$W/sicherung/sw-lab-01.cfg && echo SCP-Upload-OK"
run "echo 'get $W/sicherung/sw-lab-01.cfg $W/zurueck.cfg' | ip netns exec ccmon sftp $O -P 2223 -b - root@127.0.0.1 2>&1 | tail -1 | sed -E 's/^sftp> //'"
run "sha256sum cfg/sw-lab-01.v2 zurueck.cfg | awk '{print substr(\$1,1,16), \$2}'"
run "ip netns exec ccmon ssh $O -p 2223 root@127.0.0.1 'ls -l $W/sicherung | tail -1 | awk \"{print \\\$5, \\\$9}\"'"
pkill -f "$W/ssh/sshd.conf"
echo "Auf einem Cisco-Gerät übernimmt die SCP-Funktion der Gerätesoftware diese Rolle (ip scp server enable, copy scp:); die IOS-Befehle sind hier nicht ausgeführt und nicht bestätigt."

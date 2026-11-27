#!/usr/bin/env bash
# Modul 8: Wireless LAN und Netzwerkintegration. Es gibt im Container keine Funkhardware: alles ist Rechnung oder Planprüfung (Python). Controller-Konfigurationen sind Modelle, keine Cisco-Software.
. "$(dirname "$0")/../lab.sh"
step "1. Kanalplanung 2,4 GHz: Mittenfrequenzen und Überlappung (Modell: Kanalbreite 22 MHz wie bei 802.11b/DSSS)"
python3 - <<'PY'
import itertools
f = lambda c: 2407 + 5 * c
print('Kanal  Mittenfrequenz')
for c in (1, 6, 11, 13): print('%5d  %d MHz' % (c, f(c)))
for a, b in [(1, 6), (1, 5), (6, 11), (1, 11), (3, 8), (4, 8)]:
    d = abs(f(a) - f(b)); print('Kanal %2d und %2d: Abstand %2d MHz -> %s' % (a, b, d, 'überlappungsfrei' if d >= 22 else 'überlappen'))
g = lambda r: [t for t in itertools.combinations(r, 3) if all(abs(f(x) - f(y)) >= 22 for x, y in itertools.combinations(t, 2))]
print('Überlappungsfreie Dreiergruppen mit den Kanälen 1 bis 11:', g(range(1, 12)))
print('Mit den Kanälen 1 bis 13 (Europa) gibt es mehr Gruppen:', len(g(range(1, 14))), '- die übliche Wahl bleibt 1, 6, 11.')
PY
step "2. Dämpfung im freien Raum (FSPL), Sendeleistung, Empfangspegel, SNR (Modell)"
python3 - <<'PY'
import math
dbm = lambda mw: 10 * math.log10(mw); mw = lambda d: 10 ** (d / 10)
print('Umrechnung: 20 dBm = %d mW, 17 dBm = %d mW, 0 dBm = %d mW, -70 dBm = %.2e mW' % (mw(20), mw(17), mw(0), mw(-70)))
print('Verdopplung der Leistung = +3 dB, Zehnfache = +10 dB: %.2f dB und %.1f dB' % (dbm(2), dbm(10)))
eirp = 17 + 3 - 1; print('EIRP des AP: 17 dBm Sender + 3 dBi Antenne - 1 dB Kabel = %d dBm (%d mW)' % (eirp, mw(eirp)))
fspl = lambda d, mhz: 20 * math.log10(d / 1000) + 20 * math.log10(mhz) + 32.44
print('Entfernung  FSPL 2,4 GHz  FSPL 5 GHz  RSSI 2,4 GHz  RSSI 5 GHz  (Client-Antenne 0 dBi, freier Raum)')
for d in (5, 10, 20, 40, 80): print('%7d m  %9.1f dB  %8.1f dB  %9.1f dBm  %8.1f dBm' % (d, fspl(d, 2437), fspl(d, 5180), eirp - fspl(d, 2437), eirp - fspl(d, 5180)))
print('SNR bei -67 dBm und Rauschboden -95 dBm: %d dB' % (-67 + 95))
print('5 GHz dämpft bei gleicher Entfernung um %.1f dB mehr als 2,4 GHz (Wände zusätzlich, hier nicht modelliert).' % (fspl(10, 5180) - fspl(10, 2437)))
PY
step "3. WPA2-Personal: aus Passphrase und SSID wird der 256-Bit-Schlüssel (PBKDF2-HMAC-SHA1, 4096 Runden)"
python3 - <<'PY'
import hashlib
pmk = lambda p, s: hashlib.pbkdf2_hmac('sha1', p.encode(), s.encode(), 4096, 32).hex()
print('Testvektor aus dem Standard (Passphrase "password", SSID "IEEE"):', 'stimmt überein' if pmk('password', 'IEEE').startswith('f42c6fc52df0ebef9ebb4b90b38a5f90') else 'ABWEICHUNG')
print('Lab-Gast   ', pmk('Gast-Passwort-1', 'Lab-Gast')[:32] + '...')
print('Lab-Intern ', pmk('Gast-Passwort-1', 'Lab-Intern')[:32] + '...')
print('Gleiche Passphrase, andere SSID -> anderer Schlüssel: die SSID dient als Salt. Kurze oder bekannte Passphrasen lassen sich offline erraten, sobald der Handshake mitgeschnitten wurde.')
print('Länge der Passphrase im Standard: 8 bis 63 Zeichen; WPA3-Personal ersetzt das Verfahren durch SAE (hier nicht ausgeführt).')
PY
step "4. SSID, VLAN und Subnetz: Plan prüfen (Modell einer Controller-Konfiguration)"
python3 - <<'PY'
import ipaddress as ip, itertools, collections
s = [('Lab-Intern', 10, 'wpa2-enterprise', '192.168.10.0/24'), ('Lab-Gast', 30, 'offen', '192.168.30.0/24'), ('Lab-IoT', 30, 'wep', '192.168.31.0/24'), ('Lab-Test', 5000, 'wpa3-personal', '192.168.30.0/25')]
n = collections.Counter(x[1] for x in s)
for name, v, sec, net in s:
    f = []
    if sec == 'offen': f.append('Sicherheit: keine Verschlüsselung')
    if sec == 'wep': f.append('Sicherheit: WEP gilt als gebrochen')
    if not 1 <= v <= 4094: f.append('VLAN-ID außerhalb 1 bis 4094')
    if n[v] > 1: f.append('VLAN %d wird von mehreren SSIDs benutzt' % v)
    print('%-11s VLAN %-5d %-16s %s' % (name, v, sec, '; '.join(f) or 'ok'))
for a, b in itertools.combinations(s, 2):
    if ip.ip_network(a[3]).overlaps(ip.ip_network(b[3])): print('Subnetze überlappen: %s %s und %s %s' % (a[0], a[3], b[0], b[3]))
PY
step "5. PoE-Budget eines Access-Switches (Standard-Leistungsklassen nach Lehrbuchwissen)"
python3 - <<'PY'
g = [('AP Typ A (af-fähig)', 10, 12.95), ('AP Typ B (at nötig)', 8, 25.5), ('Kamera (af)', 6, 12.95)]; b = 370; t = 0
print('Switch-Budget %d W; Verbrauch (Annahmen, Herstellerangaben prüfen):' % b)
for n, k, w in g: print('  %-22s %2d x %5.2f W = %6.1f W' % (n, k, w, k * w)); t += k * w
print('  Summe %.1f W -> %s (Reserve %.1f W)' % (t, 'ÜBERSCHRITTEN' if t > b else 'ok', b - t))
for n, w in [('802.3af', 15.4), ('802.3at', 30.0), ('802.3bt Typ 3', 60.0), ('802.3bt Typ 4', 90.0)]: print('  Port-Maximum %-13s %5.1f W' % (n, w))
PY
step "6. Fehlerbild einordnen: Pegel, Rauschen, Authentifizierung (Faustregeln, keine Herstellerwerte)"
python3 - <<'PY'
for r, n in [(-45, -95), (-72, -95), (-62, -70), (-85, -90)]:
    snr = r - n; w = 'ausreichend' if snr >= 40 else 'grenzwertig' if snr >= 20 else 'kritisch'
    ur = 'gutes Signal' if r > -67 and snr >= 25 else 'schwaches Signal, aber sauber' if snr >= 20 else 'gutes Signal bei hohem Rauschboden' if r > -67 else 'sehr schwach und verrauscht'
    print('RSSI %4d dBm, Rauschen %4d dBm -> SNR %2d dB (%s): %s' % (r, n, snr, w, ur))
print('Authentifizierungsfehler erzeugen kein Pegelproblem: Prüfreihenfolge Verbindung -> Pegel/SNR -> Kanal/Störer -> Authentifizierung -> DHCP/DNS.')
PY
step "7. Clientseitige Fehlersuche: gleiche Fragen, andere Befehle (Windows und macOS als Lehrbuchwissen, nicht ausgeführt)"
python3 - <<'PY'
tab = [('Frage', 'Linux (Module 5 und 6 ausgeführt)', 'Windows (nicht ausgeführt)', 'macOS (nicht ausgeführt)'),
       ('IP-Konfiguration', 'ip addr', 'ipconfig /all', 'ifconfig oder networksetup -getinfo "Wi-Fi"'),
       ('Standardgateway/Routen', 'ip route', 'route print', 'netstat -rn'),
       ('Erreichbarkeit', 'ping', 'ping', 'ping'),
       ('Weg zum Ziel', 'traceroute', 'tracert', 'traceroute'),
       ('Namensauflösung', 'dig, getent hosts', 'nslookup', 'dig oder scutil --dns'),
       ('Nachbarn (ARP)', 'ip neigh', 'arp -a', 'arp -a')]
for r in tab: print('%-24s %-34s %-26s %s' % r)
print('Reihenfolge bei WLAN-Clients: 1. Funkverbindung und SSID, 2. Sicherheitsparameter (WPA-Variante, Passphrase), 3. DHCP-Adresse, 4. Gateway, 5. DNS, 6. Ziel.')
PY

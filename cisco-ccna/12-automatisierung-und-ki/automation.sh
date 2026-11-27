#!/usr/bin/env bash
# Modul 12: Automatisierung, Programmierbarkeit und KI-Grundlagen. Echt: Vorlagen mit Jinja2 und YAML, Abweichungsprüfung (difflib), REST gegen einen Mock-Controller (Flask, kein Cisco-Controller), Ansible im lokalen Modus, ein Spielzeug-Verfahren zur Anomalieerkennung.
# Nicht ausgeführt: Cisco-Controller, NETCONF/RESTCONF auf Geräten, generative KI (kein Modellzugriff im Container).
. "$(dirname "$0")/../lab.sh"
lab_up
export ANSIBLE_LOCAL_TEMP=$W/ans-tmp ANSIBLE_REMOTE_TEMP=$W/ans-tmp ANSIBLE_NOCOLOR=1 ANSIBLE_FORCE_COLOR=0 ANSIBLE_RETRY_FILES_ENABLED=0 ANSIBLE_HOME=$W/ansible HOME=$W
step "1. Datenmodell (YAML) und Vorlage (Jinja2): Konfigurationstexte für drei Switches erzeugen"
mkdir -p out; cat > geraete.yaml <<'Y'
vlans:
  - {id: 10, name: Verwaltung}
  - {id: 20, name: Technik}
  - {id: 30, name: Gaeste}
switches:
  - {name: sw-eg-01, mgmt: 192.168.99.11/24, uplink: Gi0/24, access: {Fa0/1: 10, Fa0/2: 10, Fa0/3: 20}}
  - {name: sw-og-01, mgmt: 192.168.99.12/24, uplink: Gi0/24, access: {Fa0/1: 20, Fa0/2: 30}}
  - {name: sw-og-02, mgmt: 192.168.99.13/24, uplink: Gi0/24, access: {Fa0/1: 30}}
ntp: 203.0.113.80
Y
cat > switch.j2 <<'J'
hostname {{ sw.name }}
{% for v in vlans %}vlan {{ v.id }}
 name {{ v.name }}
{% endfor %}interface {{ sw.uplink }}
 description Uplink
 switchport mode trunk
 switchport trunk allowed vlan {{ vlans | map(attribute='id') | join(',') }}
{% for port, vlan in sw.access.items() %}interface {{ port }}
 description Zugang VLAN {{ vlan }}
 switchport mode access
 switchport access vlan {{ vlan }}
{% endfor %}interface Vlan99
 ip address {{ ip(sw.mgmt) }} {{ mask(sw.mgmt) }}
ntp server {{ ntp }}
J
cat > render.py <<'PY'
import yaml, ipaddress, jinja2, sys
d = yaml.safe_load(open('geraete.yaml')); ids = {v['id'] for v in d['vlans']}
fehler = []
for s in d['switches']:
    for p, v in s['access'].items():
        if v not in ids: fehler.append('%s %s: VLAN %d ist nicht definiert' % (s['name'], p, v))
if fehler: print('\n'.join(fehler)); sys.exit(1)
env = jinja2.Environment(trim_blocks=False, lstrip_blocks=False, undefined=jinja2.StrictUndefined, keep_trailing_newline=True)
env.globals['ip'] = lambda x: ipaddress.ip_interface(x).ip; env.globals['mask'] = lambda x: ipaddress.ip_interface(x).netmask
t = env.from_string(open('switch.j2').read())
for s in d['switches']:
    open('out/%s.cfg' % s['name'], 'w').write(t.render(sw=s, vlans=d['vlans'], ntp=d['ntp']))
    print('geschrieben: out/%s.cfg (%d Zeilen)' % (s['name'], len(open('out/%s.cfg' % s['name']).read().splitlines())))
PY
run "python3 render.py"
run "cat out/sw-og-02.cfg"
echo "--- Fehlerprüfung: ein Port verweist auf ein nicht definiertes VLAN"
sed 's/Fa0\/1: 30}}/Fa0\/1: 40}}/' geraete.yaml > geraete_fehler.yaml; run "sed 's/geraete.yaml/geraete_fehler.yaml/' render.py | python3 -"
step "2. Abweichung vom Sollstand (Drift): Soll-Konfiguration gegen eine abgeänderte Ist-Konfiguration"
cp out/sw-eg-01.cfg ist.cfg; sed -i 's/switchport access vlan 20/switchport access vlan 30/; s/^ntp server 203.0.113.80/ntp server 198.51.100.5/' ist.cfg; echo "snmp-server community public RO" >> ist.cfg
python3 - <<'PY'
import difflib
soll = open('out/sw-eg-01.cfg').read().splitlines(); ist = open('ist.cfg').read().splitlines()
fehlt = [l for l in soll if l not in ist]; extra = [l for l in ist if l not in soll]
print('Zeilen laut Soll, die im Ist fehlen:', len(fehlt)); [print('  - ' + l) for l in fehlt]
print('Zeilen im Ist, die nicht im Soll stehen:', len(extra)); [print('  + ' + l) for l in extra]
print('Hinweis: "snmp-server community public RO" ist eine unsichere Standardgemeinschaft; solche Zusatzzeilen sind ein Compliance-Befund.')
print('Ähnlichkeit Soll/Ist: %.2f' % difflib.SequenceMatcher(None, soll, ist).ratio())
PY
step "3. Datenformate: dieselben Daten als YAML, JSON und XML"
python3 - <<'PY'
import yaml, json, xml.etree.ElementTree as ET
d = yaml.safe_load('name: sw-eg-01\nmgmt: 192.168.99.11/24\nvlans: [10, 20]\n')
print('JSON:', json.dumps(d))
r = ET.Element('switch', name=d['name']); ET.SubElement(r, 'mgmt').text = d['mgmt']
for v in d['vlans']: ET.SubElement(r, 'vlan').text = str(v)
print('XML: ', ET.tostring(r, encoding='unicode'))
print('Zurück aus JSON:', json.loads(json.dumps(d)) == d, '- Schlüssel/Wert-Paare in {} (Objekt) und Listen in [] sind die Bausteine von JSON.')
PY
step "4. REST gegen einen Mock-Controller (Flask, lokal, kein Cisco-Produkt): Verben, Statuscodes, Token"
cat > mock.py <<'PY'
from flask import Flask, jsonify, request, abort
import logging; logging.getLogger('werkzeug').setLevel(logging.ERROR)
app = Flask(__name__); geraete = {1: {'id': 1, 'name': 'sw-eg-01', 'status': 'up'}}
@app.before_request
def auth():
    if request.headers.get('X-Token') != 'lab-token': abort(401)
@app.get('/api/v1/devices')
def liste(): return jsonify(list(geraete.values()))
@app.get('/api/v1/devices/<int:i>')
def eins(i): return jsonify(geraete[i]) if i in geraete else abort(404)
@app.post('/api/v1/devices')
def neu():
    i = max(geraete) + 1; geraete[i] = dict(request.get_json(), id=i); return jsonify(geraete[i]), 201
@app.patch('/api/v1/devices/<int:i>')
def aendern(i):
    if i not in geraete: abort(404)
    geraete[i].update(request.get_json()); return jsonify(geraete[i])
@app.delete('/api/v1/devices/<int:i>')
def weg(i): geraete.pop(i, None); return '', 204
app.run('127.0.0.1', 8081)
PY
ns_up ccrest
bgstart ccrest mock 8081 python3 mock.py
A="ip netns exec ccrest curl -s -H X-Token:lab-token -w ' [HTTP %{http_code}]\\n'"
run "ip netns exec ccrest curl -s -o /dev/null -w 'ohne Token: HTTP %{http_code}\\n' http://127.0.0.1:8081/api/v1/devices"
run "$A http://127.0.0.1:8081/api/v1/devices"
run "$A -X POST -H 'Content-Type: application/json' -d '{\"name\":\"sw-og-01\",\"status\":\"up\"}' http://127.0.0.1:8081/api/v1/devices"
run "$A -X PATCH -H 'Content-Type: application/json' -d '{\"status\":\"down\"}' http://127.0.0.1:8081/api/v1/devices/2"
run "ip netns exec ccrest curl -s -H X-Token:lab-token http://127.0.0.1:8081/api/v1/devices | jq -c '.[] | {name, status}'"
run "$A -X DELETE http://127.0.0.1:8081/api/v1/devices/2"
run "ip netns exec ccrest curl -s -o /dev/null -H X-Token:lab-token -w 'GET /devices/2 nach DELETE: HTTP %{http_code}\\n' http://127.0.0.1:8081/api/v1/devices/2"
echo "Zuordnung (Lehrbuchwissen): GET lesen, POST anlegen, PUT ersetzen, PATCH teilweise ändern, DELETE löschen; 2xx Erfolg, 4xx Fehler des Aufrufers (401 nicht angemeldet, 404 nicht gefunden), 5xx Fehler des Servers."
pkill -f mock.py
step "5. Ansible im lokalen Modus: Konfigurationsdatei aus Vorlage, Trockenlauf, Wiederholung (Idempotenz)"
mkdir -p pb; cp switch.j2 pb/; cp geraete.yaml pb/
cat > pb/site.yml <<'Y'
- hosts: localhost
  connection: local
  gather_facts: false
  vars_files: [geraete.yaml]
  tasks:
    - name: Prüfen, dass jeder Port ein definiertes VLAN nutzt
      ansible.builtin.assert:
        that: "(switches | map(attribute='access') | map('dict2items') | flatten | map(attribute='value') | unique | list) | difference(vlans | map(attribute='id') | list) | length == 0"
        quiet: true
    - name: Konfigurationsdatei je Switch aus der Vorlage erzeugen
      ansible.builtin.template:
        src: switch.j2
        dest: "{{ playbook_dir }}/{{ item.name }}.cfg"
        mode: "0644"
      vars: { sw: "{{ item }}" }
      loop: "{{ switches }}"
      loop_control: { label: "{{ item.name }}" }
Y
cat > pb/switch.j2 <<'J'
hostname {{ sw.name }}
{% for v in vlans %}vlan {{ v.id }}
 name {{ v.name }}
{% endfor %}ntp server {{ ntp }}
J
run "ansible --version | head -1"
(cd pb; run "ansible-playbook -i localhost, site.yml --check --diff 2>&1 | grep -E 'TASK|changed|ok=|^\\+hostname' | sed -E 's/\\*+$//; s/^(\\+hostname.*)$/  \\1/' | head -12")
(cd pb; run "ansible-playbook -i localhost, site.yml 2>&1 | grep -E 'PLAY RECAP|localhost' | sed -E 's/ +/ /g' | tail -1")
(cd pb; run "ansible-playbook -i localhost, site.yml 2>&1 | grep -E 'localhost' | sed -E 's/ +/ /g' | tail -1")
cp -r pb pb2; sed -i 's/Fa0\/1: 30}/Fa0\/1: 40}/' pb2/geraete.yaml
(cd pb2; run "ansible-playbook -i localhost, site.yml 2>&1 | grep -E 'FAILED|Assertion|failed=1' | sed -E 's/ +/ /g; s/\\{.*//' | head -3")
echo "Zweiter Lauf: changed=0, weil die Dateien dem Sollstand schon entsprechen (idempotent). Die Playbooks erzeugen hier nur Dateien; ein Gerät wird nicht angesprochen. Der Lauf mit dem nicht definierten VLAN 40 bricht an der Prüfaufgabe ab, bevor eine Datei geschrieben wird."
step "6. KI-Grundlagen als Spielzeug: Anomalieerkennung auf einer Auslastungsreihe (prädiktiv/statistisch) und Prüfung von KI-Ausgaben"
python3 - <<'PY'
import random, statistics
random.seed(42)
reihe = [random.gauss(30, 4) for _ in range(120)]; reihe[90] = 95; reihe[91] = 88
basis = reihe[:60]; mu = statistics.mean(basis); sd = statistics.stdev(basis)
print('Basislinie aus den ersten 60 Messwerten: Mittelwert %.1f %%, Standardabweichung %.1f' % (mu, sd))
for i, w in enumerate(reihe):
    z = (w - mu) / sd
    if abs(z) > 4: print('Messpunkt %3d: %5.1f %% -> z = %.1f -> Auffälligkeit melden' % (i, w, z))
print('Das ist ein einfaches statistisches Verfahren und ein Beispiel für prädiktive/analytische KI im Betrieb: Es lernt aus Daten (hier: Mittelwert und Streuung), erkennt Abweichungen und kann Fehlalarme erzeugen.')
PY
cat > ki_vorschlag.txt <<'C'
vlan 10
 name Verwaltung
vlan 5000
 name Test
interface Vlan10
 ip address 192.168.10.1 255.255.255.0
interface Vlan20
 ip address 192.168.10.1 255.255.255.0
interface GigabitEthernet0/1
 switchport access vlan 20
C
python3 - <<'PY'
import re, ipaddress
# Beispiel: ein (erfundener) KI-generierter Konfigurationsvorschlag wird mit einfachen, überprüfbaren Regeln geprüft.
txt = open('ki_vorschlag.txt').read().splitlines(); defined = set(); adressen = {}
befunde = []
for i, z in enumerate(txt, 1):
    m = re.match(r'vlan (\d+)$', z)
    if m:
        v = int(m.group(1)); defined.add(v)
        if not 1 <= v <= 4094: befunde.append('Zeile %d: VLAN-ID %d außerhalb 1 bis 4094' % (i, v))
    m = re.match(r' ip address (\S+) (\S+)$', z)
    if m:
        ip = m.group(1); ifz = txt[i - 2]
        if ip in adressen: befunde.append('Zeile %d: Adresse %s doppelt vergeben (%s und %s)' % (i, ip, adressen[ip], ifz))
        adressen[ip] = ifz
    m = re.match(r' switchport access vlan (\d+)$', z)
    if m and int(m.group(1)) not in defined: befunde.append('Zeile %d: VLAN %s wird benutzt, aber nicht angelegt' % (i, m.group(1)))
print('Prüfung des KI-Vorschlags (ki_vorschlag.txt):'); [print('  Befund -', b) for b in befunde]
print('Regel: Ausgaben generativer KI sind Entwürfe. Sie werden gelesen, gegen Soll und Dokumentation geprüft und erst im Labor getestet, bevor sie auf ein Gerät gehen; Betriebsdaten und Kennwörter gehören nicht in öffentliche Dienste.')
PY
step "7. Agentische KI als Spielzeugmodell: Freigabeliste, Genehmigungsschritt, Protokoll (kein echtes KI-Modell)"
python3 - <<'PY'
ERLAUBT = {'show_vlan': 'lesen', 'backup_config': 'lesen', 'set_description': 'schreiben', 'delete_vlan': 'schreiben'}
FREIGABE_NOETIG = {'schreiben'}
protokoll = []
def agent(aktion, freigegeben=False):
    art = ERLAUBT.get(aktion)
    if art is None: erg = 'abgelehnt: Aktion nicht auf der Freigabeliste'
    elif art in FREIGABE_NOETIG and not freigegeben: erg = 'angehalten: wartet auf menschliche Freigabe'
    else: erg = 'ausgeführt (Simulation)'
    protokoll.append((aktion, art or '-', erg)); return erg
for a, f in [('show_vlan', False), ('set_description', False), ('set_description', True), ('reload_device', True)]:
    print('%-16s freigegeben=%-5s -> %s' % (a, f, agent(a, f)))
print('Protokoll (%d Einträge) wird unveränderlich abgelegt, damit Entscheidungen nachvollziehbar bleiben.' % len(protokoll))
PY
step "8. Prompt-Bausteine prüfen (Datenklassifizierung, Ausgabeformat, Rolle, Anweisungen)"
python3 - <<'PY'
bausteine = {'Rolle': 'Du bist Netzwerk-Assistent für das Labor.', 'Anweisungen': 'Erkläre die Ausgabe von show vlan.', 'Ausgabeformat': 'Antworte als JSON mit den Feldern ursache und schritt.', 'Datenklassifizierung': ''}
for k, v in bausteine.items(): print('%-20s %s' % (k, 'vorhanden' if v else 'FEHLT: keine Angabe, ob Konfigurationsdaten das Haus verlassen dürfen'))
print('Hinweis: Das prüft nur die Vollständigkeit eines Textes; es ist kein generatives Modell und trifft keine Aussage über die Qualität einer KI-Antwort.')
PY

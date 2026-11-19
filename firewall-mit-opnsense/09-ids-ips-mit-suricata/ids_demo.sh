#!/usr/bin/env bash
# Modul 9: IDS/IPS mit Suricata. OPNsense nutzt Suricata als Plugin-Dienst; hier: Suricata 7.0.3 im Offline-Modus auf einem Mitschnitt.
# Inline-Betrieb (IPS, Netmap/NFQ) wird NICHT ausgeführt; die Aktion „drop“ wird nur in der Auswertung gezeigt.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
W=$(mktemp -d /tmp/p08-ids.XXXX)
step "1. Verkehr erzeugen und auf der Firewall (LAN-Seite) mitschneiden"
timeout 12 ip netns exec p08-fw tcpdump -nn -i v-lan -w "$W/lan.pcap" -U tcp >/dev/null 2>&1 &
TP=$!; sleep 1
test_http cl 10.8.2.2 80
on cl curl -s -m 2 -o /dev/null http://10.8.2.2:80/geheim/plan.txt
on cl curl -s -m 2 -o /dev/null -A "sqlmap/1.7" http://10.8.2.2:80/index.html
on cl curl -s -m 2 -o /dev/null --path-as-is "http://10.8.2.2:80/../../etc/passwd"
on cl curl -s -m 2 -o /dev/null http://10.8.2.2:22/ || true
sleep 1; kill $TP 2>/dev/null; wait $TP 2>/dev/null
echo "Mitschnitt: $(tcpdump -nn -r "$W/lan.pcap" 2>/dev/null | wc -l) Pakete"
step "2. Eigene Regeln (ids.rules, ohne Kommentare)"
grep -v '^#' "$D/ids.rules" | sed -E 's/ \(msg:/\n    (msg:/'
step "3. Suricata im Offline-Modus auf dem Mitschnitt starten"
mkdir -p "$W/log"
suricata -c /etc/suricata/suricata.yaml -S "$D/ids.rules" -r "$W/lan.pcap" -l "$W/log" -k none --set vars.address-groups.HOME_NET="[10.8.0.0/16]" >"$W/suri.out" 2>&1
step "4. Meldungen (fast.log, Zeitstempel entfernt)"
sed -E 's/^[0-9\/]+-[0-9:.]+  //' "$W/log/fast.log" | sort
step "5. Aktion je Meldung aus eve.json (im Offline-Modus steht immer „allowed“; die drop-Regel erkennt man in fast.log an „[wDrop]“ = würde verworfen)"
python3 - "$W/log/eve.json" <<'PY'
import json,sys
z=[]
for l in open(sys.argv[1]):
    e=json.loads(l)
    if e.get("event_type")=="alert":
        a=e["alert"]; z.append(f'sid={a["signature_id"]} aktion={a["action"]} {a["signature"]}')
print("\n".join(sorted(z)))
PY
step "6. Ohne passende Regel keine Meldung: derselbe Mitschnitt mit leerer Regeldatei"
: > "$W/leer.rules"; mkdir -p "$W/log2"
suricata -c /etc/suricata/suricata.yaml -S "$W/leer.rules" -r "$W/lan.pcap" -l "$W/log2" -k none --set vars.address-groups.HOME_NET="[10.8.0.0/16]" >/dev/null 2>&1
echo "Meldungen: $(wc -l < "$W/log2/fast.log")"
rm -rf "$W"
lab_down

#!/usr/bin/env bash
# Modul 10b: Methodische Fehlersuche. Fünf Fehler werden nacheinander in ein funktionierendes Netz eingebaut; ein Prüfskript arbeitet von unten nach oben (Bottom-up) und meldet die erste Ebene, die versagt. Linux-Werkzeuge statt IOS-Befehle.
. "$(dirname "$0")/../lab.sh"
lab_up
ns_up cccl ccrt ccsv
link cccl e0 ccrt g0; link ccsv e0 ccrt g1
ip -n cccl addr add 192.168.10.10/24 dev e0; ip -n ccrt addr add 192.168.10.1/24 dev g0; ip -n ccrt addr add 192.168.20.1/24 dev g1; ip -n ccsv addr add 192.168.20.10/24 dev e0
ip -n cccl route add default via 192.168.10.1; ip -n ccsv route add default via 192.168.20.1; fwd ccrt
bgstart ccsv web 8080 python3 -m http.server 8080 --bind 192.168.20.10
cat > diag.sh <<'D'
#!/usr/bin/env bash
# Bottom-up-Prüfung vom Client cccl zum Webserver 192.168.20.10:8080. Gibt die erste fehlerhafte Ebene aus.
x() { ip netns exec cccl "$@"; }
st=$(x cat /sys/class/net/e0/operstate); [ "$st" = up ] || { echo "Ebene 1 (Verbindung): e0 ist $st"; exit 1; }
x ip -4 addr show dev e0 | grep -q 'inet ' || { echo "Ebene 3 (IP): e0 hat keine Adresse"; exit 1; }
gw=$(x ip route | awk '/^default/ {print $3}'); [ -n "$gw" ] || { echo "Ebene 3 (IP): kein Standard-Gateway"; exit 1; }
x ping -c1 -W1 "$gw" >/dev/null 2>&1 || { echo "Ebene 3 (Gateway): $gw antwortet nicht auf Ping (falsche Adresse, falsche Maske oder Router-Schnittstelle down?)"; exit 1; }
x ping -c1 -W1 192.168.20.10 >/dev/null 2>&1 || { echo "Ebene 3 (Ziel): Gateway erreichbar, aber 192.168.20.10 nicht (Routing, Rückweg oder Filter?)"; exit 1; }
x timeout 3 bash -c 'exec 3<>/dev/tcp/192.168.20.10/8080' 2>/dev/null || { echo "Ebene 4 (TCP): Ping geht, Port 8080 nicht (Dienst gestoppt oder Port gefiltert?)"; exit 1; }
code=$(x curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://192.168.20.10:8080/); [ "$code" = 200 ] || { echo "Ebene 7 (Anwendung): HTTP-Status $code"; exit 1; }
echo "alle Ebenen in Ordnung (HTTP $code)"
D
chmod +x diag.sh
step "0. Ausgangslage: alles in Ordnung"
run "./diag.sh"
step "1. Fehler 1: falsches Standard-Gateway am Client (192.168.10.254 statt .1)"
ip -n cccl route replace default via 192.168.10.254 2>/dev/null; run "./diag.sh"; ip -n cccl route replace default via 192.168.10.1
step "2. Fehler 2: Router-Schnittstelle zum Server ist ausgefallen"
ip -n ccrt link set g1 down; run "./diag.sh"
echo "--- Eingrenzen (Divide-and-Conquer): wie weit kommt ein Paket?"
run "ip netns exec cccl traceroute -I -n -q1 -w1 -m 3 192.168.20.10 | sed 1d | awk '{print \$1, \$2}'"
run "ip -n ccrt -br link show g1 | awk '{print \$1, \$2}' | sed 's/@if[0-9]*//'"
ip -n ccrt link set g1 up; sleep 0.5
step "3. Fehler 3: Server kennt den Rückweg nicht (Standardroute fehlt)"
ip -n ccsv route del default; run "./diag.sh"
echo "--- Eingrenzen: Hinweg ist in Ordnung (Router erreichbar), also den Rückweg des Servers prüfen"
run "ip -n ccsv route"
ip -n ccsv route add default via 192.168.20.1
step "4. Fehler 4: Filter auf dem Router blockiert TCP 8080"
ip netns exec ccrt nft add table inet f; ip netns exec ccrt nft 'add chain inet f fw { type filter hook forward priority 0; policy accept; }'; ip netns exec ccrt nft add rule inet f fw tcp dport 8080 drop
run "./diag.sh"
echo "--- Eingrenzen: der Dienst läuft (Server hört auf 8080), also den Weg prüfen: Zähler der Filterregel auf dem Router"
run "ip netns exec ccsv ss -ltn | grep -c ':8080' | sed 's/^/Zuhörer auf Port 8080 am Server: /'"
run "ip netns exec ccrt nft list ruleset | grep -E 'dport 8080' | sed -E 's/^[ \t]+//; s/ bytes [0-9]+//'"
ip netns exec ccrt nft delete table inet f
step "5. Fehler 5: Webdienst auf dem Server gestoppt"
pkill -f 'http.server 8080'; sleep 0.5; run "./diag.sh"
echo "--- Eingrenzen: kein Filter auf dem Weg, aber auch kein Zuhörer am Server"
run "ip netns exec ccsv ss -ltn | grep -c ':8080' | sed 's/^/Zuhörer auf Port 8080 am Server: /'"
bgstart ccsv web 8080 python3 -m http.server 8080 --bind 192.168.20.10
step "6. Wieder in Ordnung"
run "./diag.sh"
step "7. Typische Auswertung: Fehlerbild und wahrscheinliche Ursache (Tabelle aus der Praxis, keine Messung)"
python3 - <<'PY'
rows = [('Ping auf Gateway geht nicht, Link ist up', 'falsche IP, Maske oder VLAN; Adresskonflikt'), ('Gateway geht, Ziel im anderen Netz nicht', 'fehlende Route oder Rückroute, ACL, NAT'),
        ('Ping geht, TCP-Verbindung nicht', 'Dienst gestoppt, Portfilter, falsche Portnummer'), ('Nur große Pakete scheitern', 'MTU-Problem (Tunnel, Overlay), Fragmentierung blockiert'),
        ('Verbindung bricht sporadisch ab', 'Duplex-Mismatch (CRC-Fehler), doppelte IP, flappender Port, STP-Umschaltung')]
for a, b in rows: print('%-44s -> %s' % (a, b))
PY

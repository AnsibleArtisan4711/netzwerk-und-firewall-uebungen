#!/usr/bin/env bash
# Gemeinsame Hilfen der Übungsreihe Cisco CCNA (Linux-Modelle). Nur im Testlabor als root ausführen (virtuelle Maschine, nicht auf einem Produktivsystem).
# Alle Dateien liegen unter /tmp/ccna; Namensräume (Präfix cc), Hintergrunddienste und Dateien werden am Ende wieder entfernt.
# Hinweis: Das sind Linux-Werkzeuge. Es läuft kein Cisco IOS und kein Packet Tracer; Cisco-Befehle stehen nur in den Aufgaben und sind nicht ausgeführt.
W=/tmp/ccna
step() { echo; echo "## $*"; }
cmd() { echo "\$ $*"; "$@" 2>&1; return $?; }             # einzelner Befehl, Ausgabe samt Fehlermeldung
run() { echo "\$ $1"; bash -c "$1" 2>&1; return $?; }       # Zeile mit Pipe oder Umleitung als Text
ns_up() { for n in "$@"; do ip netns add "$n" 2>/dev/null; ip -n "$n" link set lo up; done; }
# Verbindung zweier Namensräume: link NS1 IF1 NS2 IF2   (Namensraum "-" = Hauptnamensraum wird nicht verwendet)
link() { ip link add "$2" type veth peer name "$4"; ip link set "$2" netns "$1"; ip link set "$4" netns "$3"; ip -n "$1" link set "$2" up; ip -n "$3" link set "$4" up; }
fwd() { for n in "$@"; do ip netns exec "$n" sysctl -qw net.ipv4.ip_forward=1 net.ipv4.conf.all.ignore_routes_with_linkdown=1; done; }   # Router: Weiterleiten an, Routen auf ausgefallenen Verbindungen nicht benutzen
lab_down() {
  pkill -f "$W/" 2>/dev/null; pkill -x lldpd 2>/dev/null; pkill -x keepalived 2>/dev/null
  for p in zebra ospfd; do pkill -f "/usr/lib/frr/$p" 2>/dev/null; done
  for n in $(ip netns list 2>/dev/null | awk '{print $1}' | grep '^cc'); do ip netns pids "$n" 2>/dev/null | xargs -r kill 2>/dev/null; ip netns del "$n" 2>/dev/null; done
  rm -rf "$W"
}
lab_up() { lab_down >/dev/null 2>&1; mkdir -p "$W"; chmod 777 "$W"; cd "$W" || exit 1; }
trap 'lab_down >/dev/null 2>&1' EXIT
# Dienst im Hintergrund starten und auf den Port warten: bgstart NAMENSRAUM NAME PORT BEFEHL...
bgstart() { local ns=$1 n=$2 p=$3; shift 3; (ip netns exec "$ns" "$@" >"$W/$n.log" 2>&1 &); for i in $(seq 1 40); do ip netns exec "$ns" ss -ltnu 2>/dev/null | grep -q ":$p " && return 0; sleep 0.25; done; echo "Dienst $n kam nicht hoch (siehe $W/$n.log)"; return 1; }

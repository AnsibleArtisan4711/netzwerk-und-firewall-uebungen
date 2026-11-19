#!/usr/bin/env bash
# Führt alle Modulskripte aus und schreibt die Ausgaben nach NN-name/beispiele/SKRIPT.ausgabe.txt.
# Nur im Testlabor als root ausführen (legt Netzwerk-Namespaces mit Präfix p08- an, startet dnsmasq, keepalived, suricata).
cd "$(dirname "$0")" || exit 1
for d in [0-9][0-9]-*/; do
  for s in "$d"*.sh; do
    [ -f "$s" ] || continue
    b=$(basename "$s" .sh); [ "$b" = dhcp-hook ] && continue; mkdir -p "${d}beispiele"
    bash "$s" 2>&1 | grep -v '^Terminated$' > "${d}beispiele/$b.ausgabe.txt"
    echo "$s -> $(wc -l < "${d}beispiele/$b.ausgabe.txt") Zeilen"
  done
done

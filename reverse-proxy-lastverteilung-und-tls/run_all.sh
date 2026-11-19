#!/usr/bin/env bash
# Führt alle Modulskripte aus und schreibt die Ausgaben nach NN-name/beispiele/SKRIPT.ausgabe.txt.
# Nur im Testlabor als root ausführen (legt Netzwerk-Namespaces an und startet nginx, HAProxy und Test-Backends; Modul 7 benötigt PEBBLE_BIN, PEBBLE_SRC und CERTBOT).
cd "$(dirname "$0")" || exit 1
for d in [0-9][0-9]-*/; do
  for s in "$d"*.sh; do
    [ -f "$s" ] || continue
    b=$(basename "$s" .sh); mkdir -p "${d}beispiele"
    bash "$s" 2>&1 | grep -v '^Terminated$' > "${d}beispiele/$b.ausgabe.txt"
    echo "$s -> $(wc -l < "${d}beispiele/$b.ausgabe.txt") Zeilen"
  done
done
# Hinweis: Modul 7 (acme_pebble.sh) erwartet die Umgebungsvariablen PEBBLE_BIN (Programm), PEBBLE_SRC (Quelltext mit test/-Ordner) und CERTBOT (Programm, Python 3.12).

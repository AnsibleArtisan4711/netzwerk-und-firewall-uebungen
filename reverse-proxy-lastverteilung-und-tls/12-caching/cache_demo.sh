#!/usr/bin/env bash
# Caching im nginx-Proxy: MISS/HIT/EXPIRED/BYPASS/STALE, Cache-Datei, Verhalten bei Ausfall des Backends.
. "$(dirname "$0")/../lab.sh"
D=$(cd "$(dirname "$0")" && pwd)
lab_up
nginx_start "$D/cache.conf"
U=http://shop.lab.test
step "1. Erste Anfrage MISS (geht ans Backend), die folgenden HIT (aus dem Cache: gleiche Antwortnummer)"
for i in 1 2 3; do on cl curl -s -m 3 -D /tmp/p11-h.txt $U/cache | tr -d '\n'; echo " | $(grep -i '^x-cache-status' /tmp/p11-h.txt | tr -d '\r')"; done
step "2. Ohne Cache (/roh): jede Anfrage erreicht das Backend, die Nummer steigt"
for i in 1 2 3; do on cl curl -s -m 3 $U/roh; done
step "3. Cache-Datei auf dem Proxy"
echo "Dateien im Cache-Ordner: $(find /tmp/p11-nginx/cache -type f | wc -l)"
step "4. Bypass: mit X-Refresh geht die Anfrage ans Backend (BYPASS), die Antwort ersetzt den Cache-Eintrag"
on cl curl -s -m 3 -D /tmp/p11-h.txt -H "X-Refresh: 1" $U/cache | tr -d '\n'; echo " | $(grep -i '^x-cache-status' /tmp/p11-h.txt | tr -d '\r')"
on cl curl -s -m 3 -D /tmp/p11-h.txt $U/cache | tr -d '\n'; echo " | $(grep -i '^x-cache-status' /tmp/p11-h.txt | tr -d '\r')"
step "5. Ablauf: nach mehr als 10 s (max-age des Backends; nginx rechnet auf ganze Sekunden) ist der Eintrag veraltet; die nächste Anfrage holt eine neue Antwort (EXPIRED)"
sleep 12
on cl curl -s -m 3 -D /tmp/p11-h.txt $U/cache | tr -d '\n'; echo " | $(grep -i '^x-cache-status' /tmp/p11-h.txt | tr -d '\r')"
step "6. Backend fällt aus: nach Ablauf liefert nginx die veraltete Antwort (STALE) statt eines Fehlers"
on b1 pkill -f "backend.py b1"; sleep 12
on cl curl -s -m 5 -D /tmp/p11-h.txt $U/cache | tr -d '\n'; echo " | $(grep -i '^x-cache-status' /tmp/p11-h.txt | tr -d '\r')"
echo "- ohne Cache (/roh) in derselben Lage:"; on cl curl -s -m 5 -o /dev/null -w "HTTP %{http_code}\n" $U/roh
lab_down

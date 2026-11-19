# 02 nginx-Proxy

Übung **02.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skript im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `02.1-nginx-als-reverse-proxy.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `nginx_proxy.sh` | nginx als Reverse Proxy: Host-Header, X-Forwarded-*, Pfadumschreibung, virtuelle Server und eine fehlerhafte Konfiguration. |
| `proxy.conf` | nginx als Reverse Proxy: Header, Pfade, Zeitlimits, zwei virtuelle Server |
| `proxy_defekt.conf` | absichtlich fehlerhaft: Semikolon fehlt, Upstream unbekannt |
| `beispiele/nginx_proxy.ausgabe.txt` | Echte Ausgabe des Laufs von `nginx_proxy` |

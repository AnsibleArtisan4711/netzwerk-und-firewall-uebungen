# 05 nginx TLS

Übung **05.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skript im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `05.1-tls-terminierung-nginx.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `nginx_tls.sh` | TLS-Terminierung mit nginx: Zertifikat, Weiterleitung auf HTTPS, HSTS, Protokollversionen, HTTP/2, Weitergabe von X-Forwarded-Proto. |
| `tls.conf` | TLS-Terminierung mit nginx: HTTPS am Proxy, HTTP zum Backend; Weiterleitung 80 -> 443; HSTS |
| `beispiele/nginx_tls.ausgabe.txt` | Echte Ausgabe des Laufs von `nginx_tls` |

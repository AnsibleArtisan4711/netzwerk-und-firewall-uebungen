# 06 HAProxy TLS

Übung **06.1** (Priorität 1). Geschätzte Zeit: 5 bis 6 Stunden (Schätzung; Lehrplan: 8 UE zu 45 Minuten = 6 Stunden).

> Skript im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `06.1-tls-terminierung-haproxy.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `haproxy_tls.cfg` | TLS-Terminierung mit HAProxy: zwei Zertifikate (SNI), HTTP/2, Weiterleitung auf HTTPS, HSTS; dazu TLS-Durchleitung (Passthrough) |
| `haproxy_tls.sh` | TLS-Terminierung mit HAProxy: mehrere Zertifikate (SNI), HTTP/2, Weiterleitung, HSTS und TLS-Durchleitung. |
| `beispiele/haproxy_tls.ausgabe.txt` | Echte Ausgabe des Laufs von `haproxy_tls` |

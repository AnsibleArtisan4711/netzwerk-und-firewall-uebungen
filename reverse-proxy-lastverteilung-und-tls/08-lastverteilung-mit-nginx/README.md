# 08 nginx-Verteilung

Übung **08.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skript im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `08.1-lastverteilung-mit-nginx.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `lb.conf` | Lastverteilung mit nginx: ein Upstream je Verfahren |
| `nginx_lb.sh` | Lastverteilung mit nginx: Round Robin, Gewichte, least_conn, ip_hash, passive Gesundheitsprüfung mit max_fails/fail_timeout. |
| `beispiele/nginx_lb.ausgabe.txt` | Echte Ausgabe des Laufs von `nginx_lb` |

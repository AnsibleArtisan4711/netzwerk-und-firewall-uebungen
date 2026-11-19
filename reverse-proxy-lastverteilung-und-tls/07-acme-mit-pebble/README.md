# 07 ACME

Übung **07.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skript im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `07.1-acme-mit-pebble.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `acme_pebble.sh` | ACME mit einem lokalen Testserver (Pebble) und certbot: Zertifikat ausstellen (standalone und webroot), einbinden, erneuern. |
| `nginx_acme.conf` | HTTP-Server für die Webroot-Methode (ACME HTTP-01) und anschließend HTTPS mit dem ausgestellten Zertifikat |
| `nginx_acme_tls.conf` | Skript |
| `beispiele/acme_pebble.ausgabe.txt` | Echte Ausgabe des Laufs von `acme_pebble` |

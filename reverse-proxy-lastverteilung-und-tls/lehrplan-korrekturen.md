# Anmerkungen zum Lehrplan P11

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Laborbeschreibung:** Der Lehrplan nennt „einen privaten Hyper-V-Switch“; für Client-Netz und Backend-Netz ohne Umgehung durch Routing sind zwei private Switches nötig. | Im Lehrplan „zwei private Switches“ nennen. |
| 2 | 05 | **nginx-Version:** `http2 on;` gibt es erst ab nginx 1.25.1; in Ubuntu 24.04 (1.24.0) und Debian 12 (1.22) gilt `listen 443 ssl http2;`. | Hinweis in Einheit 5.1 ergänzen. |
| 3 | 05 | **Proxy-Variablen:** Eine gesetzte Umgebung mit `https_proxy` lässt curl lokale Namen über einen Proxy auflösen; die Skripte entfernen die Variablen. | Hinweis in Einheit 5.3 ergänzen. |
| 4 | 07 | **ACME-Werkzeuge:** Pebble und certbot sind nicht in den Debian-Paketquellen; certbot 5.10.0 scheiterte mit Python 3.13 an Pebbles Test-CA („Missing Authority Key Identifier“), mit Python 3.12 nicht. | Beschaffung und Python-Version im Lehrplan nennen. |
| 5 | 07 | **certbot renew:** Ohne `--no-random-sleep-on-renew` wartet certbot bei nicht interaktivem Aufruf zufällig mehrere Minuten. | Hinweis in Einheit 7.4 ergänzen. |
| 6 | 10 | **X-Forwarded-For:** `$proxy_add_x_forwarded_for` am äußersten Proxy übernimmt gefälschte Ketten des Clients. | Vertrauensgrenze in Einheit 10.1 ergänzen. |
| 7 | 13 | **Abschlussprojekt:** Die Aufgabe hat mehrere Lösungen; der Lehrplan nennt keine Abnahmekriterien. | Testkatalog als Abnahmekriterium im Lehrplan aufnehmen. |

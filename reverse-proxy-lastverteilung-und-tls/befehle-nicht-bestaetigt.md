# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Aufbau des Hyper-V-Labors mit zwei privaten Switches und vier VMs, Internetphase für Pakete | – | laut Lehrplan aufbauen und prüfen |
| alle | Beschaffung von Pebble (Bau mit Go) und certbot (pip) in der VM | – | in `px01` nachvollziehen; Debian-12-Paketquellen prüfen |
| 01 | Minimaler nginx-Proxy, `ss`-Ausgabe der zwei Verbindungen | L (nginx 1.24.0) | in der VM wiederholen |
| 02 | `proxy_pass` mit und ohne Schrägstrich, Header, 502/504, `nginx -t` | L | mit nginx 1.22 (Debian 12) wiederholen |
| 03 | HAProxy-Konfiguration, ACLs, tcp-Modus, Admin-Socket (`show info`, `show stat`) | L (HAProxy 2.8.30) | mit HAProxy 2.6 (Debian 12) wiederholen |
| 04 | Interne CA mit openssl, `verify`, `-checkhost`, `-checkend`, `s_client`-Rückgabecodes | L (OpenSSL 3.0.13) | mit OpenSSL 3.0 der VM wiederholen |
| 05 | nginx-TLS, Weiterleitung, HSTS, Protokollversionen | L | `listen … http2` und `http2 on;` je Version prüfen |
| 06 | HAProxy-TLS mit SNI, HTTP/2, Passthrough | L | wiederholen |
| 07 | Pebble und certbot (standalone, webroot, Erneuerung mit Hook) | L (Pebble v2.6.0, certbot 5.10.0, Python 3.12) | Verhalten mit anderen Versionen prüfen; Fristen von Let’s Encrypt gegen Dokumentation prüfen |
| 08 | nginx-Verteilverfahren und passive Prüfung (Ausfall, Rückkehr) | L | wiederholen |
| 08 | Aussage „nginx Open Source hat keine aktive Prüfung“ | – (Fachwissen) | gegen Dokumentation prüfen |
| 09 | HAProxy-Verteilung, Cookie, aktive Prüfung, Backup, `drain` | L; `disable` – | `disable` ausführen; Wiederholung in der VM |
| 10 | X-Forwarded-For-Fälschung, Sicherheits-Header, PROXY-Protokoll | L; Wirkung im Browser – | Header im Browser prüfen |
| 11 | WebSocket (`ws_client.py`), Leerlaufzeiten nginx und HAProxy | L; Standardwert von `proxy_read_timeout` – | Standardwerte gegen Dokumentation prüfen |
| 12 | nginx-Cache: MISS, HIT, BYPASS, EXPIRED, STALE | L; `Vary` und `Set-Cookie` – | Verhalten bei Cookies prüfen |
| 13 | `fehlersuche.sh`, `abschluss.conf`, `abschluss_test.sh` | L | wiederholen; Testkatalog erweitern |

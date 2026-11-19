# Reverse Proxy, Lastverteilung und TLS (P11)

Übungsreihe zu Reverse Proxys: Konzept, nginx und HAProxy als Proxy, TLS-Grundlagen und interne CA, TLS-Terminierung, ACME mit lokalem Testserver (Pebble), Lastverteilung und Health Checks, Header und PROXY-Protokoll, WebSocket, Caching sowie Fehlersuche. 13 Module, 110 Unterrichtseinheiten zu 45 Minuten, davon 2 Module mit Priorität 2 (Vertiefung). Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P11 (Reihe „Lehrplan-Prompts“, Datei `P11-reverse-proxy-lastverteilung-und-tls.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **In einem Namespace-Labor (Cloud-Container) ausgeführt, nicht unter Hyper-V, nicht auf Debian 12.** Alle Skripte der Module 1 bis 13 wurden mit nginx 1.24.0, HAProxy 2.8.30, OpenSSL 3.0.13, curl 8.5.0, Pebble v2.6.0 und certbot 5.10.0 (Ubuntu 24.04) ausgeführt; die Ausgaben stehen in den Ordnern `beispiele/` der Module. Dokumentation und Quellen wurden nicht gelesen; das Verhalten der Debian-12-Pakete und das Hyper-V-Labor sind ungeprüft. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Vier VMs unter **Hyper-V** (Lehrplan): `px01` (Proxy, zwei Netzwerkkarten), `web01`, `web02` (Backends) und `cl01` (Client) an zwei privaten Switches (`10.1.1.0/24` und `10.1.2.0/24`, statisch). Das Labor wurde **nicht** aufgebaut. Die Skripte bauen es als vier Netzwerk-Namespaces auf einer einzelnen Linux-Maschine nach: `lab.sh` (Hilfsfunktionen, `on px …` = „im Namespace des Proxys“) und `backend.py` (Test-Backend) liegen im Kursordner, `run_all.sh` führt alle Skripte aus. Voraussetzungen auf der Maschine: root, `ip`, `nginx` (mit Stream-Modul), `haproxy`, `openssl`, `curl`, `socat`, `python3`, `ss`; für Modul 7 zusätzlich Pebble (aus dem Quelltext gebaut), certbot (Python 3.12) und die Umgebungsvariablen `PEBBLE_BIN`, `PEBBLE_SRC`, `CERTBOT`. Namespaces und Hintergrunddienste werden am Ende jedes Skripts entfernt.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Reverse-Proxy-Konzept und Laborumgebung](01-reverse-proxy-konzept/) | 5,25 h | Skript im Container ausgeführt. |
| 02 | [nginx als Reverse Proxy](02-nginx-als-reverse-proxy/) | 6,75 h | Skript im Container ausgeführt. |
| 03 | [HAProxy als Reverse Proxy](03-haproxy-als-reverse-proxy/) | 6,75 h | Skript im Container ausgeführt. |
| 04 | [TLS-Grundlagen und eine interne CA mit openssl](04-tls-und-interne-ca/) | 6,75 h | Skript im Container ausgeführt. |
| 05 | [TLS-Terminierung mit nginx](05-tls-terminierung-nginx/) | 6,75 h | Skript im Container ausgeführt. |
| 06 | [TLS-Terminierung mit HAProxy und TLS-Durchleitung](06-tls-terminierung-haproxy/) | 6 h | Skript im Container ausgeführt. |
| 07 | [Let’s Encrypt und ACME mit einem lokalen Testserver (Pebble)](07-acme-mit-pebble/) | 6,75 h | Skript im Container ausgeführt. |
| 08 | [Lastverteilung mit nginx](08-lastverteilung-mit-nginx/) | 6,75 h | Skript im Container ausgeführt. |
| 09 | [Lastverteilung und Health Checks mit HAProxy](09-lastverteilung-und-health-checks-haproxy/) | 6,75 h | Skript im Container ausgeführt. |
| 10 | [Header, HSTS und das PROXY-Protokoll](10-header-hsts-und-proxy-protokoll/) | 6 h | Skript im Container ausgeführt. |
| 11 | [WebSocket hinter dem Proxy](11-websocket/) (Priorität 2) | 5,25 h | Skript im Container ausgeführt. |
| 12 | [Caching im Reverse Proxy](12-caching/) (Priorität 2) | 6 h | Skript im Container ausgeführt. |
| 13 | [Sicherheit, Fehlersuche und Abschlussprojekt](13-sicherheit-fehlersuche-abschluss/) | 6,75 h | Skripte im Container ausgeführt. |

Summe 82,5 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein.

## Hinweise

- Nur im Testlabor ausführen: Die Skripte legen Namespaces mit dem Präfix `p11-` an, tragen die Namen `shop.lab.test` und `api.lab.test` in `/etc/hosts` ein (Markierung `# p11-lab`, wird am Ende entfernt) und legen Dateien unter `/tmp/p11-*` an; nicht auf einem produktiven Rechner ausführen.
- Die CA-Schlüssel und Zertifikate sind Laborwerte; Pebbles Test-Wurzelschlüssel ist öffentlich bekannt. Keine dieser Dateien in Produktion verwenden.
- In den VMs entfallen das Präfix `on <rolle>` und die Hilfsfunktionen; Konfigurationsdateien und Befehle sind dieselben. Vor Änderungen an `px01` einen Prüfpunkt anlegen.
- Zeitstempel, Seriennummern und Ports in den Ausgaben wechseln von Lauf zu Lauf.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*

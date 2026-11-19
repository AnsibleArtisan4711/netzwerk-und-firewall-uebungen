# Firewall mit OPNsense (P08)

Übungsreihe zur Firewall OPNsense: Konzept und Labor, Interfaces und VLANs, Aliase, Regeln und Reihenfolge, NAT, DHCP und DNS, Zertifikate, VPN-Überblick, IDS/IPS mit Suricata, Hochverfügbarkeit, Sicherung der Konfiguration, Logging und Plugins sowie Fehlersuche. 13 Module, 108 Unterrichtseinheiten zu 45 Minuten, davon 2 Module mit Priorität 2 (Vertiefung). **OPNsense wurde nicht ausgeführt**; die zugrunde liegende Technik wird mit Linux-Werkzeugen nachgebildet. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P08 (Reihe „Lehrplan-Prompts“, Datei `P08-firewall-mit-opnsense.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **OPNsense nicht installiert und nicht ausgeführt. In einem Namespace-Labor (Cloud-Container) wurde das Verhalten mit Linux nachgebildet, nicht unter Hyper-V.** Ausgeführt wurden alle Skripte der Module 1 bis 13 mit nftables 1.0.9, dnsmasq, dhclient, Suricata 7.0.3 (Offline), keepalived 2.2.8, OpenSSL 3.0.13, WireGuard-Werkzeugen (ohne Tunnel), xmllint und tcpdump (Ubuntu 24.04); die Ausgaben stehen in den Ordnern `beispiele/` der Module. Handbücher und Quellen wurden nicht gelesen. Alle Aussagen zu Menüs, Regelverarbeitung, Plugins, CARP und Dateiformaten von OPNsense sind ungeprüft („nicht bestätigt“). Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Drei bis vier VMs unter **Hyper-V** (Lehrplan): `fw01` (OPNsense, drei Netzwerkkarten), `cl01` (Client), `srv01` (Server) und optional `wan01` an drei privaten Switches (`10.8.1.0/24`, `10.8.2.0/24`, `10.8.9.0/24`, statisch). Das Labor wurde **nicht** aufgebaut. Die Skripte bauen es als Netzwerk-Namespaces auf einer einzelnen Linux-Maschine nach, mit Linux (nftables) anstelle von OPNsense: `lab.sh` (Hilfsfunktionen, `on fw …` = „im Namespace der Firewall“) und `echo_server.py` (Testserver) liegen im Kursordner, `run_all.sh` führt alle Skripte aus. Voraussetzungen auf der Maschine: root, `ip`, `nft`, `conntrack`, `tcpdump`, `curl`, `python3`, `dig`, `dnsmasq`, `dhclient`, `suricata`, `keepalived`, `openssl`, `wg`, `xmllint`. Die Namespaces und Hintergrunddienste werden am Ende jedes Skripts entfernt.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Konzept, Installation und Labor](01-konzept-installation-und-labor/) | 5,25 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 02 | [Interfaces, VLANs und Zonen](02-interfaces-vlans-und-zonen/) | 6,75 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 03 | [Aliase](03-aliase/) | 6 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 04 | [Firewall-Regeln und Reihenfolge](04-firewall-regeln-und-reihenfolge/) | 7,5 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 05 | [NAT: ausgehend, Portweiterleitung und 1:1](05-nat/) | 6,75 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 06 | [DHCP und DNS auf der Firewall](06-dhcp-und-dns/) | 6,75 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 07 | [Zertifikate und interne CA](07-zertifikate-und-ca/) | 6 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 08 | [VPN-Dienste: Überblick](08-vpn-dienste-ueberblick/) (Priorität 2) | 4,5 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 09 | [IDS/IPS mit Suricata](09-ids-ips-mit-suricata/) | 7,5 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 10 | [Hochverfügbarkeit (CARP-Prinzip)](10-hochverfuegbarkeit/) (Priorität 2) | 6 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 11 | [Sicherung der Konfiguration](11-sicherung-der-konfiguration/) | 5,25 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 12 | [Logging und Plugins](12-logging-und-plugins/) | 6 h | Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |
| 13 | [Fehlersuche und Abschlussprojekt](13-fehlersuche-und-abschluss/) | 6,75 h | Skripte im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft. |

Summe 81 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein.

## Hinweise

- Nur im Testlabor ausführen: Die Skripte legen Namespaces mit dem Präfix `p08-` an und starten `dnsmasq`, `suricata` und `keepalived` in Namespaces; Hilfsdateien liegen unter `/tmp/p08-*`.
- Die Schlüssel, Zertifikate und das Kennwort in den Skripten sind Laborwerte und entstehen in temporären Ordnern; nichts davon in Produktion verwenden.
- In den VMs entfallen das Präfix `on <rolle>` und die Hilfsfunktionen; die Firewall ist dort OPNsense, deren Regeln über die Oberfläche entstehen. Vor Änderungen an `fw01` einen Prüfpunkt anlegen.
- Adressen, Ports, Seriennummern und Zeitangaben in den Ausgaben wechseln von Lauf zu Lauf.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*

# Linux-Firewall mit nftables und iptables (P09)

Übungsreihe zu Linux-Firewalls: Netfilter-Architektur, nftables (Tabellen, Ketten, Regeln, Sets und Maps), Host-Firewall, Zustandsverfolgung, NAT, Router-Firewall mit Zonen, Rate Limiting und Protokollierung, Sichern und Laden von Regelsätzen, iptables, Migration zu nftables, firewalld und ufw sowie Fehlersuche. 13 Module, 106 Unterrichtseinheiten zu 45 Minuten, davon 2 Module mit Priorität 2 (Vertiefung). Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P09 (Reihe „Lehrplan-Prompts“, Datei `P09-linux-firewall-mit-nftables-und-iptables.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **In einem Namespace-Labor (Cloud-Container) ausgeführt, nicht unter Hyper-V, nicht auf Debian 12.** Alle Skripte der Module 1 bis 13 wurden mit nftables 1.0.9, iptables 1.8.10 (nf_tables), conntrack-tools 1.4.8, tcpdump, ufw 0.36.2 und firewalld 2.1.1 (Ubuntu 24.04) ausgeführt; die Ausgaben stehen in den Ordnern `beispiele/` der Module. Handbücher und Quellen wurden nicht gelesen; das Verhalten der Debian-12-Pakete und das Hyper-V-Labor sind ungeprüft. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Drei VMs unter **Hyper-V** (Lehrplan): `fw01` (Firewall, zwei Netzwerkkarten), `cl01` (Client) und `srv01` (Server) an zwei privaten Switches (`10.0.1.0/24` und `10.0.2.0/24`, statisch). Das Labor wurde **nicht** aufgebaut. Die Skripte bauen es als drei Netzwerk-Namespaces auf einer einzelnen Linux-Maschine nach: `lab.sh` (Hilfsfunktionen, Schreibweise `on fw …` = „im Namespace der Firewall“) liegt im Kursordner, `run_all.sh` führt alle Skripte aus und schreibt die Ausgaben. Voraussetzungen auf der Maschine: root, `ip`, `nft`, `iptables`, `conntrack`, `tcpdump`, `curl`, `python3`; für Modul 12 zusätzlich `ufw` und `firewalld`. Die Namespaces und Hintergrunddienste werden am Ende jedes Skripts entfernt.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Netfilter-Architektur und Laborumgebung](01-netfilter-architektur/) | 5,25 h | Skript im Container ausgeführt. |
| 02 | [nftables: Tabellen, Ketten und Regeln](02-tabellen-ketten-regeln/) | 6,75 h | Skript im Container ausgeführt. |
| 03 | [Host-Firewall für einen Server](03-host-firewall/) | 6,75 h | Skripte im Container ausgeführt. |
| 04 | [Zustandsverfolgung (Connection Tracking)](04-zustandsverfolgung/) | 6,75 h | Skript im Container ausgeführt. |
| 05 | [Sets, Maps und Verdict-Maps](05-sets-maps-verdict-maps/) (Priorität 2) | 6 h | Skript im Container ausgeführt. |
| 06 | [NAT: Masquerade, Port-Weiterleitung und Redirect](06-nat/) | 6,75 h | Skript im Container ausgeführt. |
| 07 | [Router-Firewall mit Zonen (forward)](07-forward-und-zonen/) | 6,75 h | Skripte im Container ausgeführt. |
| 08 | [Rate Limiting und Protokollierung](08-rate-limiting-und-protokollierung/) | 6 h | Skript im Container ausgeführt; Kernel-Log nicht geprüft. |
| 09 | [Regelsätze sichern, laden und dauerhaft machen](09-regelsaetze-sichern-und-laden/) | 5,25 h | Skript im Container ausgeführt; systemd nicht geprüft. |
| 10 | [iptables: Grundlagen und das Verhältnis zu nftables](10-iptables-grundlagen/) | 6 h | Skript im Container ausgeführt; legacy nicht geprüft. |
| 11 | [Migration von iptables zu nftables](11-migration-von-iptables-zu-nftables/) | 6 h | Skript im Container ausgeführt. |
| 12 | [firewalld und ufw in Grundzügen](12-firewalld-und-ufw/) (Priorität 2) | 4,5 h | Skript im Container ausgeführt. |
| 13 | [Fehlersuche und Abschlussprojekt](13-fehlersuche/) | 6,75 h | Skript im Container ausgeführt. |

Summe 79,5 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein.

## Hinweise

- Nur im Testlabor ausführen: Die Skripte legen Namespaces mit dem Präfix `p09-` an; `ufw` und `firewalld` (Modul 12) ändern zusätzlich Dateien unter `/etc` (`/etc/ufw`, `/etc/firewalld`); nicht auf einem produktiven Rechner ausführen.
- Das Skript `ufw_firewalld.sh` setzt ufw im Server-Namespace zurück (`ufw --force reset`) und löscht anschließend die Richtlinie `lan_zu_srv`.
- In den VMs entfallen das Präfix `on <rolle>` und die Hilfsfunktionen; die Befehle `nft` und `iptables` sind dieselben. Vor Änderungen an `fw01` einen Prüfpunkt anlegen.
- Die Ports in den Ausgaben von conntrack und tcpdump wechseln von Lauf zu Lauf.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*

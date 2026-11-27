# Cisco CCNA (A19)

Übungsreihe zur Vorbereitung auf Cisco CCNA 200-301 (Prüfungsthemen Version 2.0): Netzwerkgrundlagen, Ethernet und Switching, VLANs, Spanning Tree, IP-Adressierung, Routing und OSPF, IP-Dienste, WLAN, Sicherheit, Betrieb und Fehlersuche, Overlay und Virtualisierung, Automatisierung und KI. 12 Module, 106 Unterrichtseinheiten zu 45 Minuten, davon 4 Module mit Priorität 2 (Vertiefung); Modul 12 ist der Abschluss und entfällt bei Zeitmangel zuerst. Keine Prüfungsfragen. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan A19 (Reihe „Lehrplan-Prompts“, Datei `A19-cisco-ccna.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Im Cloud-Container ausgeführt (Ubuntu 24.04.5), nicht auf Cisco-Geräten.** Es lief **weder Cisco IOS noch Packet Tracer**; die Skripte zeigen die Konzepte an Linux-Werkzeugen und Python-Modellen. Die Ausgaben in den Ordnern `beispiele/` stammen von echten Läufen dieser Werkzeuge; Cisco-Befehle sind Fachwissen und nicht bestätigt. Von cisco.com wurden nur die Prüfungsthemen Version 2.0 gelesen (27.11.2026, ohne Gültigkeitsdatum). Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Linux-VMs und Cisco-Geräte oder ein Simulator auf einem privaten Hyper-V-Switch ohne Heimnetz, Snapshots vor jeder Übung. Das Labor wurde **nicht** aufgebaut. Die Skripte arbeiten als root unter `/tmp/ccna`.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Netzwerkgrundlagen und Cisco-Architektur](01-netzwerkgrundlagen/) | 6 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 02 | [Ethernet, Verkabelung und Switching-Grundlagen](02-ethernet-und-switching/) | 6 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 03 | [VLANs, Trunks und Inter-VLAN Routing](03-vlans-und-trunks/) | 6,75 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 04 | [STP, EtherChannel und Layer-2-Redundanz](04-stp-und-etherchannel/) (Priorität 2) | 6 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 05 | [IPv4/IPv6-Adressierung und Subnetting](05-adressierung-und-subnetting/) | 7,5 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 06 | [Routing-Grundlagen, Statische Routen und OSPF](06-routing-und-ospf/) | 7,5 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 07 | [IP-Services und Netzwerkdienste](07-ip-dienste/) (Priorität 2) | 6,75 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 08 | [Wireless LAN und Netzwerkintegration](08-wlan/) (Priorität 2) | 6 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 09 | [Security, Hardening und Zugriffskontrolle](09-sicherheit-und-zugriffskontrolle/) | 7,5 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 10 | [Betrieb, Monitoring, Logging und Troubleshooting](10-betrieb-und-fehlersuche/) | 6,75 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 11 | [WAN, Virtualisierung, Cloud und SDN-Grundlagen](11-wan-overlay-und-virtualisierung/) (Priorität 2) | 6 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |
| 12 | [Automation, Programmability, Migration und BCDR](12-automatisierung-und-ki/) (Priorität 3) | 6,75 h | Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut. |

Summe 79,5 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein. Benötigt: Bash, iproute2, tshark/tcpdump, Python 3 mit networkx, PyYAML, Jinja2 und Flask, FRRouting, dnsmasq, nftables, chrony, keepalived, Net-SNMP, rsyslog, lldpd, OpenSSH, ansible-core, jq (siehe `befehle-nicht-bestaetigt.md`). Nur im Testlabor ausführen. Cisco, Cisco IOS und Packet Tracer sind Marken von Cisco Systems, Inc.; dieses Dokument steht in keiner Verbindung zu Cisco.

## Hinweise

- Alle Namen, Adressen und Kennwörter sind erfunden (Laborwerte).
- Die Skripte arbeiten unter `/tmp/ccna` und räumen am Ende auf; nie auf einem Produktivsystem ausführen.
- Die Ausgaben stammen aus dem Cloud-Container; Adressen, Zähler und Zeiten weichen ab.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Cisco, Cisco IOS und Packet Tracer sind Marken von Cisco Systems, Inc.; dieses Dokument steht in keiner Verbindung zu Cisco und enthält keine Prüfungsfragen.*

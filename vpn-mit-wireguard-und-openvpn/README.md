# VPN mit WireGuard und OpenVPN (P10)

Übungsreihe zu VPN-Konzepten, WireGuard (Road Warrior, Split/Full Tunnel, Site-to-Site), OpenVPN (EasyRSA, Server, Inline-Profile, ccd/iroute, Site-to-Site), Firewall und NAT mit nftables sowie Fehlersuche. Zwölf Module mit je einer ausgearbeiteten Übung (Steckbrief, Lernziele, Voraussetzungen, Grundbegriffe, Aufgabe mit Zuordnung zu Lerneinheiten, Hinweise, Kontrollfragen, Musterlösung, Erweiterungen, Quellen). Gesamtumfang: 82,5 Stunden (110 Unterrichtseinheiten zu 45 Minuten; Priorität 1: 9 Module, Priorität 2: 3 Module).

> **Prüfstand, ehrlich:** **Teilweise in einer Testumgebung ausgeführt, nicht auf Debian 12 und nicht unter Hyper-V.** Die Linux-Befehle der Module 2 bis 12 wurden in zwei Netzwerk-Namespaces eines Cloud-Containers nachgestellt (Ubuntu 24.04, wireguard-tools 1.0.20210914, wireguard-go v0.0.20230223 statt Kernelmodul, OpenVPN 2.6.19, EasyRSA 3.1.7, nftables 1.0.9, tcpdump 4.99.4). **Nicht geprüft:** Debian 12, Hyper-V und Prüfpunkte, `apt install`, `/etc/network/interfaces`, systemd-Dienste (`wg-quick@wg0`, `openvpn-server@server`), SSH/`scp`/`sudo`, das Kernelmodul `dummy`, das WireGuard-Kernelmodul, `dynamic_debug`. Modul 1 ist eine Fallstudie und wurde nicht erprobt. Die Ausgaben im Ordner `beispiele/` der Module stammen aus der Testumgebung. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Zwei **Debian-12-VMs** unter Hyper-V: `vpn-a` (VM 1, Server, Gateway Site A: WAN `10.0.0.1/24`, `dummy0` `192.168.10.1/24`) und `vpn-b` (VM 2, Client, Gateway Site B: WAN `10.0.0.100/24`, `dummy0` `192.168.20.1/24`), Benutzer `labadmin`. Privater vSwitch `VPN-Lab-WAN` (`10.0.0.0/24`); der `Default Switch` nur für die Internet-Phase in Modul 2. Tunnelnetze: WireGuard `10.8.0.0/24`, OpenVPN `10.9.0.0/24`. WireGuard und OpenVPN laufen **nie gleichzeitig**. Prüfpunkte `Basis`, `M2-fertig`, `M11-Start`. Das Labor wurde **nicht** aufgebaut; getestet wurde in Namespaces (siehe `testlabor-namespaces.sh`).

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [VPN-Konzepte und technologische Grundlagen](01-vpn-konzepte/) | 6 h | Entwurf, ohne Labor (Fallstudie) |
| 02 | [Vorbereitung der Laborumgebung und Linux-Routing](02-laborumgebung-und-linux-routing/) | 6 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 03 | [WireGuard – Grundlagen und Architektur](03-wireguard-grundlagen/) | 6 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 04 | [WireGuard – Road-Warrior-Konzepte und Split Tunneling](04-wireguard-road-warrior/) | 7,5 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 05 | [WireGuard – Site-to-Site-Verbindungen](05-wireguard-site-to-site/) (Priorität 2) | 6 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 06 | [OpenVPN – Grundlagen und PKI-Vorbereitung (EasyRSA)](06-openvpn-grundlagen-und-easyrsa/) | 6 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 07 | [OpenVPN – Server-Konfiguration und Basisbetrieb](07-openvpn-server-konfiguration/) | 7,5 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 08 | [OpenVPN – Road-Warrior-Clients und Inline-Profile](08-openvpn-road-warrior-clients/) | 7,5 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 09 | [OpenVPN – Fortgeschrittenes Routing (ccd, iroute)](09-openvpn-ccd-und-iroute/) (Priorität 2) | 7,5 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 10 | [OpenVPN – Site-to-Site-Verbindungen](10-openvpn-site-to-site/) (Priorität 2) | 7,5 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 11 | [Firewalling, NAT und Sicherheit für VPN-Gateways](11-firewall-und-nat/) | 7,5 h | Entwurf, teilweise in Testumgebung ausgeführt |
| 12 | [Troubleshooting, Logging und Fehlerbehebung](12-troubleshooting-und-logging/) | 7,5 h | Entwurf, teilweise in Testumgebung ausgeführt |

Summe 82,5 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md`, gegebenenfalls Skripten und einem Ordner `beispiele/` mit Ausgaben der Testumgebung. Das Hilfsskript [`testlabor-namespaces.sh`](testlabor-namespaces.sh) baut das Zwei-Standorte-Labor ohne Hyper-V in Namespaces nach; es ist nicht Teil des Lehrplans.

## Hinweise

- Nur im Labor ausführen; die Übungen ändern Netzwerk, Routen, Firewall und erzeugen Schlüssel und Zertifikate.
- Schlüssel, Zertifikate und `ta.key` gehören nie in ein Repository. Die Schlüssel in den Beispielen sind Laborwerte.
- Alle Firmen, Namen und Adressen sind frei erfunden (Domänen nach RFC 2606, Adressen nach RFC 1918).

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

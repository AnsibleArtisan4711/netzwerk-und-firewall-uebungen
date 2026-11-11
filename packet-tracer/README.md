# Netzwerktechnik: Übungsreihe mit Cisco Packet Tracer

Eine Sammlung von Übungen zur Netzwerktechnik, von den absoluten Grundlagen bis zu Routing, Sicherheit, VPN und IPv6. Jede Übung erklärt nicht nur die Befehle, sondern auch, was dabei im Netzwerk passiert, und beschreibt jeden Schritt sowohl über die grafische Oberfläche als auch über die Kommandozeile.

## Beschreibung

Das Repository ist ein Übungsvorrat und gleichzeitig ein Lernportfolio. Die Übungen bauen modulweise aufeinander auf, sind in sich abgeschlossen und können jederzeit wiederholt werden. Jede Übung trägt eine Stufe (Grundlage, Aufbau oder Fortgeschritten), damit sich gezielt einzelne Übungen aus früheren Modulen wiederholen lassen.

Die Übungen sind eigene Entwürfe und nicht aus Kursmaterial übernommen.

## Ziele

- Netzwerkgrundlagen von Grund auf verstehen: Adressierung, Subnetting, Switching, Routing
- Konfiguration auf Cisco-IOS-Geräten sicher beherrschen, nicht nur Befehle abtippen
- Dienste und Absicherung kennen: DHCP, DNS, NAT, SSH, Port Security, ACLs
- Standorte verbinden (WAN, VPN) und IPv6 einsetzen
- Fehler systematisch eingrenzen und beheben
- Ein durchgehendes, nachvollziehbares Portfolio aufbauen

## Module

| Nr. | Modul | Inhalt | Stand |
|---|---|---|---|
| 1 | [01-grundlagen](01-grundlagen/README.md) | Adressierung, Subnetting, erste Konfiguration von Router und Switch | in Arbeit |
| 2 | [02-switching](02-switching/README.md) | VLANs, Trunks, STP, EtherChannel | in Arbeit |
| 3 | [03-routing](03-routing/README.md) | Statisches Routing, Inter-VLAN-Routing, OSPF | in Arbeit |
| 4 | [04-netzdienste](04-netzdienste/README.md) | DHCP, DHCP-Relay, DNS, NAT, PAT | in Arbeit |
| 5 | [05-sicherheit](05-sicherheit/README.md) | Grundabsicherung, SSH, Port Security, ACLs | in Arbeit |
| 6 | [06-wan-vpn](06-wan-vpn/README.md) | Serielle WAN-Verbindung, Standortkopplung, GRE, IPsec | in Arbeit |
| 7 | [07-ipv6](07-ipv6/README.md) | IPv6-Adressierung, SLAAC, Routing, OSPFv3 | in Arbeit |
| 8 | [08-fehlersuche](08-fehlersuche/README.md) | Fehlersuche: Vorgehen und Aufgaben mit eingebauten Fehlern | in Arbeit |

Eine Liste aller Übungen steht jeweils in der README des Moduls.

## Nutzung

Repository klonen, in den Ordner `packet-tracer` wechseln und im gewünschten Modulordner die Übung als Markdown-Datei öffnen. Die zugehörige Packet-Tracer-Datei (`.pkt`) hat denselben Namen und liegt daneben.

```text
git clone https://github.com/AnsibleArtisan4711/netzwerk-und-firewall-uebungen.git
cd netzwerk-und-firewall-uebungen/packet-tracer
```

## Hinweise

**Werkzeug:** Benötigt wird Cisco Packet Tracer (kostenlos über die Cisco Networking Academy). Router und Switches laufen dort mit Cisco IOS. Die PCs haben kein IOS, ihre Eingabeaufforderung kennt eigene Befehle.

**Aufbau jeder Übung:** Lernziel, Voraussetzungen, Topologie mit Adressplan, Aufgabe, Hintergrund, Hinweise, Prüfbefehle, Musterlösung (getrennt von der Aufgabe), Erweiterungen, geschätzte Zeit, Stufe und Quellen.

**Zwei Wege pro Schritt:** Jeder Schritt wird über die GUI und über die CLI beschrieben. Wo es in Packet Tracer keinen CLI-Weg gibt (z. B. Geräte platzieren und verkabeln), steht das ausdrücklich dabei. Alle Befehle stehen in Codeblöcken.

**Geprüft oder nicht:** Befehle stammen aus offiziellen Quellen (Packet-Tracer-Hilfe, Cisco-Labs, Cisco-Dokumentation). Ausgaben, die noch nicht in Packet Tracer nachgebaut und bestätigt wurden, sind als *nicht bestätigt* oder *sinngemäß* gekennzeichnet. Der Stand einer Übung steht in der Modul-README.

**Dateien:** Zu jeder Übung gehören die Anleitung als Markdown-Datei und, sobald nachgebaut, die Packet-Tracer-Datei mit demselben Namen. Namensschema: `mm.n-titel-mit-bindestrichen`, z. B. `01.1-erstes-netzwerk.md` und `01.1-erstes-netzwerk.pkt`. Alle Ordner- und Dateinamen bestehen nur aus Kleinbuchstaben, Ziffern, Punkt und Bindestrich. Ausnahme sind die Standarddateien `README.md` und `LICENSE`. Die Dateien liegen flach im Modulordner, zusammen mit dessen `README.md`.

**Datenschutz:** Alle Adressen sind private bzw. frei gewählte Beispieladressen. Es kommen keine echten Netze, Domains oder Zugangsdaten vor.

## Lizenz

Dieses Werk steht unter der Lizenz [Creative Commons Namensnennung – Nicht kommerziell – Weitergabe unter gleichen Bedingungen 4.0 International (CC BY-NC-SA 4.0)](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.de). Das bedeutet: Du darfst die Inhalte teilen und bearbeiten, wenn du

- den Urheber nennst (**AnsibleArtisan4711**) und angibst, ob du Änderungen vorgenommen hast,
- sie **nicht kommerziell** nutzt, z. B. nicht in bezahlten Kursen oder Produkten,
- Bearbeitungen unter **derselben Lizenz** weitergibst.

Der vollständige Lizenztext steht in der Datei [LICENSE](LICENSE). Die Lizenz gilt für die Texte, Anleitungen und Packet-Tracer-Dateien dieses Repositorys, nicht für Marken und Produkte Dritter.

## Marken

Cisco, Cisco IOS und Cisco Packet Tracer sind Marken oder eingetragene Marken von Cisco Systems, Inc. und/oder ihrer Tochtergesellschaften. Dieses Repository steht in keiner Verbindung zu Cisco und wird von Cisco weder unterstützt noch gefördert.

## Struktur

```text
netzwerk-uebungen-packet-tracer/
├── LICENSE
├── README.md
├── 01-grundlagen/
│   ├── README.md
│   ├── 01.1-erstes-netzwerk.md
│   └── 01.1-erstes-netzwerk.pkt
├── 02-switching/
│   └── README.md
├── 03-routing/
│   └── README.md
├── 04-netzdienste/
│   └── README.md
├── 05-sicherheit/
│   └── README.md
├── 06-wan-vpn/
│   └── README.md
├── 07-ipv6/
│   └── README.md
└── 08-fehlersuche/
    └── README.md
```

# 07 IP-Dienste

Übung **07.1** (Priorität 2, Vertiefung, kann bei Zeitmangel entfallen). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut.

| Datei | Zweck |
|---|---|
| `07.1-ip-dienste.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `dhcp-dns.sh` | Modul 7a: DHCP (Server, Relay, Reservierung) und DNS mit dnsmasq. Linux-Dienste als Modell; auf Cisco-Geräten heißt die Relay-Funktion „ip helper-address“ (hier nicht ausgeführt). |
| `fhrp.sh` | Modul 7c: First Hop Redundancy mit VRRP (keepalived). HSRP und GLBP sind Cisco-Verfahren und hier nur als Text beschrieben; VRRP ist der herstellerneutrale Standard mit derselben Idee. |
| `nat-ntp.sh` | Modul 7b: NAT/PAT (nftables, echte Adressumsetzung mit Verbindungsverfolgung), Portweiterleitung (DNAT) und NTP (chrony). Linux-Werkzeuge; die Cisco-Befehle (ip nat inside/outside, ntp server) stehen nur in den Aufgaben. |
| `beispiele/dhcp-dns.ausgabe.txt` | Echte Ausgabe des Laufs von `dhcp-dns` |
| `beispiele/fhrp.ausgabe.txt` | Echte Ausgabe des Laufs von `fhrp` |
| `beispiele/nat-ntp.ausgabe.txt` | Echte Ausgabe des Laufs von `nat-ntp` |

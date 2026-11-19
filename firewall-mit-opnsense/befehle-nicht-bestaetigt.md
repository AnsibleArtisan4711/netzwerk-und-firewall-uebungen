# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Aufbau des Hyper-V-Labors mit drei privaten Switches, Internetphase für die Installationsabbilder | – | laut Lehrplan aufbauen und prüfen |
| alle | **Installation und Oberfläche von OPNsense** (Menüs, Namen, Standardwerte, Version) | – (nicht ausgeführt) | OPNsense in der VM installieren und jede Beschreibung gegen die Oberfläche prüfen |
| 01 | `labor_pruefen.sh` (Linux als Stand-in) | L | in den VMs wiederholen |
| 02 | VLAN-Schnittstellen (`ip link add … type vlan`) | L: scheitert (kein `8021q`) | in OPNsense VLANs anlegen und im Mitschnitt prüfen |
| 02 | Rahmen mit 802.1Q-Tag im Mitschnitt (`tagframe.py`, `tcpdump -e`) | L | wiederholen |
| 03 | Aliase als nftables-Sets | L (nftables 1.0.9); Aliase und Verschachtelung in OPNsense – | Aliasverwaltung von OPNsense prüfen |
| 04 | Regelreihenfolge („erste passende Regel gilt“), Zähler, Block und Reject | L; Auswertung in OPNsense (pf) – | Reihenfolge, „Quick“-Verhalten, floating Regeln in OPNsense prüfen |
| 05 | Masquerade, DNAT, 1:1-NAT, Reihenfolge der NAT-Regeln | L; NAT-Menüs von OPNsense – | in OPNsense wiederholen |
| 06 | DHCP und DNS mit dnsmasq (`dhclient`-Hook, `dig`) | L; Dienste von OPNsense – | Dienste von OPNsense prüfen |
| 07 | Interne CA, Server- und Clientzertifikat, CRL, `s_client`-Rückgabecodes | L (OpenSSL 3.0.13); Zertifikatsverwaltung von OPNsense – | Import in OPNsense prüfen |
| 08 | WireGuard-Schlüssel und Konfiguration (`wg`, `wg-quick strip`) | L; Tunnel: nicht möglich (kein WireGuard im Kernel) | Tunnel in den VMs aufbauen (Kurs „VPN“) |
| 09 | Suricata-Regeln, Offline-Auswertung (`fast.log`, `eve.json`) | L (Suricata 7.0.3); Inline-Betrieb, Einbindung in OPNsense – | IPS-Betrieb in OPNsense prüfen |
| 10 | Adressübernahme mit keepalived (VRRP) | L (keepalived 2.2.8); CARP und pfsync – | CARP in OPNsense einrichten und prüfen |
| 11 | Prüfen, Vergleichen, Verschlüsseln, Schwärzen, Aufbewahrung (Beispieldatei) | L (Beispieldatei frei erfunden); Export und Dateiformat von OPNsense – | echte Sicherung der Konfiguration verwenden |
| 12 | Protokollierung mit nflog, Auswertung | L; Protokoll und Plugins von OPNsense – | Plugin-Verwaltung und Protokollansicht prüfen |
| 13 | `fehlersuche.sh`, `abschluss_loesung.nft`, `abschluss_test.sh` | L | in den VMs mit OPNsense-Regeln wiederholen |

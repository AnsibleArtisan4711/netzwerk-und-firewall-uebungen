# 02 Interfaces und VLANs

Übung **02.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft.

| Datei | Zweck |
|---|---|
| `02.1-interfaces-vlans-und-zonen.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `tagframe.py` | Sendet einen von Hand gebauten Ethernet-Rahmen mit 802.1Q-Tag (VLAN-ID) auf eine Schnittstelle (nur Labor, benötigt root). |
| `vlan_demo.sh` | Modul 2: Interfaces, VLANs, Zonen. Die Linux-Maschine des Labors hat KEIN VLAN-Modul (8021q) und keine Bridge; deshalb: (1) getrennte Netze je Zone als eigene Schnittstellen, (2) ein VLAN-Rahmen von Hand gebaut und mit tcpdump gelesen. |
| `beispiele/vlan_demo.ausgabe.txt` | Echte Ausgabe des Laufs von `vlan_demo` |

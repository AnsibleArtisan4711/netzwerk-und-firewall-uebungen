# 03 VLANs

Übung **03.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut.

| Datei | Zweck |
|---|---|
| `03.1-vlans-und-trunks.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `vlan.sh` | Modul 3: VLANs, Trunks und Inter-VLAN-Routing. Der Container hat kein 8021q-Modul und keine VLAN-Filterung der Bridge: 802.1Q-Rahmen werden von Hand gebaut, das Switch-Verhalten ist ein Python-Modell, getrennte Broadcast-Domänen entstehen mit zwei Bridges. IOS-Text wird nur erzeugt, nicht ausgeführt. |
| `beispiele/vlan.ausgabe.txt` | Echte Ausgabe des Laufs von `vlan` |

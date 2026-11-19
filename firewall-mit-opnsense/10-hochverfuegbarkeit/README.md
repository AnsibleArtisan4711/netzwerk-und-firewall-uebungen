# 10 Hochverfügbarkeit

Übung **10.1** (Priorität 2, Vertiefung, kann bei Zeitmangel entfallen). Geschätzte Zeit: 5 bis 6 Stunden (Schätzung; Lehrplan: 8 UE zu 45 Minuten = 6 Stunden).

> Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft.

| Datei | Zweck |
|---|---|
| `10.1-hochverfuegbarkeit.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `keepalived.conf.vorlage` | keepalived als Stand-in für CARP (VRRP-Verfahren; kein CARP, andere Protokolle!) |
| `vrrp_demo.sh` | Modul 10 (Priorität 2): Hochverfügbarkeit. OPNsense verwendet CARP und pfsync (FreeBSD); beides ist im Labor NICHT verfügbar. |
| `beispiele/vrrp_demo.ausgabe.txt` | Echte Ausgabe des Laufs von `vrrp_demo` |

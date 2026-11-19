# 09 IDS/IPS

Übung **09.1** (Priorität 1). Geschätzte Zeit: 6 bis 8 Stunden (Schätzung; Lehrplan: 10 UE zu 45 Minuten = 7,5 Stunden).

> Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft.

| Datei | Zweck |
|---|---|
| `09.1-ids-ips-mit-suricata.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `ids.rules` | Eigene Testregeln (Suricata-Regelsyntax). SIDs ab 1000000 sind für lokale Regeln üblich. |
| `ids_demo.sh` | Modul 9: IDS/IPS mit Suricata. OPNsense nutzt Suricata als Plugin-Dienst; hier: Suricata 7.0.3 im Offline-Modus auf einem Mitschnitt. |
| `beispiele/ids_demo.ausgabe.txt` | Echte Ausgabe des Laufs von `ids_demo` |

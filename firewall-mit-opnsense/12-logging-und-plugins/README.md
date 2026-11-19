# 12 Logging und Plugins

Übung **12.1** (Priorität 1). Geschätzte Zeit: 5 bis 6 Stunden (Schätzung; Lehrplan: 8 UE zu 45 Minuten = 6 Stunden).

> Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft.

| Datei | Zweck |
|---|---|
| `12.1-logging-und-plugins.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `log_auswertung.sh` | Modul 12: Logging. OPNsense protokolliert Filterereignisse über pf (FreeBSD) – hier nicht verfügbar. Nachbildung: nftables-Regeln mit „log group“ (nflog), Mitschnitt mit tcpdump, Auswertung mit awk. Plugins (Teil des Moduls) werden nur beschrieben, nicht ausgeführt. |
| `beispiele/log_auswertung.ausgabe.txt` | Echte Ausgabe des Laufs von `log_auswertung` |

# 03 Host-Firewall

Übung **03.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skripte im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `03.1-host-firewall.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `host_firewall.nft` | Basis-Regelwerk für einen Server (Host-Firewall): alles verwerfen, was nicht erlaubt ist. |
| `host_firewall_test.sh` | Lädt host_firewall.nft in den Server-Namespace und prüft sie vom Client (und von einer nicht erlaubten Adresse) aus. |
| `beispiele/host_firewall_test.ausgabe.txt` | Echte Ausgabe des Laufs von `host_firewall_test` |

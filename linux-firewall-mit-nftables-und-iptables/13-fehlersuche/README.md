# 13 Fehlersuche

Übung **13.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skript im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `13.1-fehlersuche.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `abschluss_loesung.nft` | Musterlösung Abschlussprojekt: Router-Firewall für das Labor (LAN v-fw1, Server v-fw2). |
| `abschluss_test.sh` | Testkatalog für die Musterlösung des Abschlussprojekts (abschluss_loesung.nft): jede Anforderung ein Test mit erwartetem Ergebnis. |
| `fehlersuche.sh` | Fehlersuche an vier eingebauten Fehlern: Reihenfolge, falscher Schnittstellenname, fehlende Rückrichtung, ip_forward; dazu nft trace und tcpdump. |
| `beispiele/abschluss_test.ausgabe.txt` | Echte Ausgabe des Laufs von `abschluss_test` |
| `beispiele/fehlersuche.ausgabe.txt` | Echte Ausgabe des Laufs von `fehlersuche` |

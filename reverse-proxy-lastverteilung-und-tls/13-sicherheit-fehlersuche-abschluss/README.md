# 13 Fehlersuche

Übung **13.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skripte im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `13.1-sicherheit-fehlersuche-abschluss.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `abschluss.conf` | Musterlösung Abschlussprojekt: HTTPS-Reverse-Proxy mit Lastverteilung, Schutz und gehärteten Headern (nginx) |
| `abschluss_test.sh` | Testkatalog für die Musterlösung des Abschlussprojekts (abschluss.conf): jede Anforderung ein Test mit erwartetem Ergebnis. |
| `fehler.conf` | Absichtlich eingebaute Fehler- und Schutzfälle für die Fehlersuche |
| `fehlersuche.sh` | Fehlersuche und Schutz am Proxy: 502, 504, 413, 429, 444 bei nginx; 503 bei HAProxy; was Zugriffs- und Fehlerprotokoll verraten. |
| `haproxy_503.cfg` | Skript |
| `beispiele/abschluss_test.ausgabe.txt` | Echte Ausgabe des Laufs von `abschluss_test` |
| `beispiele/fehlersuche.ausgabe.txt` | Echte Ausgabe des Laufs von `fehlersuche` |

# 13 Fehlersuche

Übung **13.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skripte im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft.

| Datei | Zweck |
|---|---|
| `13.1-fehlersuche-und-abschluss.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `abschluss_loesung.nft` | Musterlösung Abschlussprojekt (Linux-nftables als Stand-in für die OPNsense-Regeln) |
| `abschluss_test.sh` | Abschlussprojekt: Testkatalog. Lädt abschluss_loesung.nft (oder die Datei aus $1) in die Firewall und prüft die Anforderungen. |
| `fehlersuche.sh` | Modul 13: Fehlersuche an fünf typischen Fehlern (Regelreihenfolge, fehlendes NAT, Portweiterleitung ohne Filterregel, falsches Gateway im Server, Tippfehler im Alias). Jeweils: Symptom → Diagnose → Korrektur → erneuter Test. |
| `beispiele/abschluss_test.ausgabe.txt` | Echte Ausgabe des Laufs von `abschluss_test` |
| `beispiele/fehlersuche.ausgabe.txt` | Echte Ausgabe des Laufs von `fehlersuche` |

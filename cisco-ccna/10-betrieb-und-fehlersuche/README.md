# 10 Betrieb

Übung **10.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skripte im Container ausgeführt (Ubuntu 24.04.5); keine Cisco-Geräte, kein Packet Tracer, Hyper-V-Labor nicht aufgebaut.

| Datei | Zweck |
|---|---|
| `10.1-betrieb-und-fehlersuche.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `fehlersuche.sh` | Modul 10b: Methodische Fehlersuche. Fünf Fehler werden nacheinander in ein funktionierendes Netz eingebaut; ein Prüfskript arbeitet von unten nach oben (Bottom-up) und meldet die erste Ebene, die versagt. Linux-Werkzeuge statt IOS-Befehle. |
| `snmp-syslog.sh` | Modul 10a: Überwachung und Protokollierung mit SNMP (snmpd, Net-SNMP) und Syslog (rsyslog), plus Konfigurationssicherung. Linux-Dienste; die IOS-Befehle (snmp-server, logging host) stehen nur in der Aufgabe. |
| `beispiele/fehlersuche.ausgabe.txt` | Echte Ausgabe des Laufs von `fehlersuche` |
| `beispiele/snmp-syslog.ausgabe.txt` | Echte Ausgabe des Laufs von `snmp-syslog` |

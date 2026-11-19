# Anmerkungen zum Lehrplan P09

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Laborbeschreibung:** Der Lehrplan nennt „einen privaten Hyper-V-Switch“; für zwei Netze (LAN und Server) sind zwei private Switches oder VLAN-Zuordnungen nötig. | Im Lehrplan „zwei private Switches“ oder „ein Switch mit VLAN-Zuordnung“ nennen. |
| 2 | 01 | **Kettennamen:** `fwd` und `in`/`out` sind in nftables reservierte oder unglückliche Namen (Syntaxfehler beim Schreiben der Skripte). | Hinweis „beschreibende Kettennamen verwenden“ in Einheit 2.1 ergänzen. |
| 3 | 08 | **ICMP-Falle:** Steht `ct state established,related accept` vor der Limit-Regel, greift ein Limit für wiederholte Pings nicht; die erste Fassung des Skripts ließ alle 40 Pakete durch. | Reihenfolge-Hinweis in Einheit 8.1 ergänzen. |
| 4 | 08 | **Protokoll-Präfix:** Der Präfix von `log … group` ist in `tcpdump` nicht sichtbar; für die Auswertung wird ein Werkzeug wie `ulogd2` benötigt (nicht getestet). | Im Lehrplan nennen oder `ulogd2` als Voraussetzung aufnehmen. |
| 5 | 09 | **include:** Ein relativer include-Pfad ohne passendes Verzeichnis im Suchpfad lädt still ein leeres Regelwerk. | Hinweis „Zeilenzahl prüfen“ in Einheit 9.2 ergänzen. |
| 6 | 12 | **firewalld:** Neue Policies lassen sich nur mit `--permanent` anlegen; Zonen-Zuordnungen zur Laufzeit gehen beim `--reload` verloren, wenn sie nicht dauerhaft gesetzt wurden. | Im Lehrplan als Hinweis in Einheit 12.2 ergänzen. |
| 7 | 13 | **Abschlussprojekt:** Die Aufgabe hat mehrere Lösungen; der Lehrplan nennt keine Abnahmekriterien. | Testkatalog als Abnahmekriterium im Lehrplan aufnehmen. |

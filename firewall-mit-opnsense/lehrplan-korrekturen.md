# Anmerkungen zum Lehrplan P08

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Laborbeschreibung:** Der Lehrplan nennt „1 Client-VM im LAN“, „1 Linux-Server-VM im zweiten Netz“ und „einen privaten Hyper-V-Switch“; für die drei Zonen (LAN, DMZ, WAN) und eine Gegenstelle im „Internet“ sind drei private Switches und optional eine vierte VM (`wan01`) nötig. | Im Lehrplan „drei private Switches“ und `wan01` nennen oder die NAT-Aufgaben anpassen. |
| 2 | alle | **Vorrang der Prüfbarkeit:** OPNsense ließ sich im Labor nicht ausführen; der Kurs bildet Verhalten mit Linux nach. Die Beschreibungen der Oberfläche sind „nicht bestätigt“. | Vor dem Einsatz im Unterricht gegen eine installierte OPNsense prüfen. |
| 3 | 02 | **VLAN:** Der Labor-Kernel hat kein `8021q`-Modul; die Einheit zeigt statt einer VLAN-Schnittstelle einen von Hand gebauten Rahmen. | In der VM-Umgebung eine echte VLAN-Schnittstelle ergänzen. |
| 4 | 04 | **Regelauswertung:** Das Skript wertet „erste passende Regel gilt“ aus (wie nftables). pf-basierte Firewalls können je nach Regeloption die letzte passende Regel verwenden (Fachwissen, nicht bestätigt). | Im Lehrplan Einheit 4.2 mit der echten OPNsense-Regelauswertung abgleichen. |
| 5 | 05 | **NAT-Reihenfolge:** Eine allgemeine Masquerade-Regel vor einer 1:1-Regel verdeckt diese; die erste Fassung des Skripts zeigte deshalb die falsche Quelladresse. | Reihenfolge-Hinweis in Einheit 5.3 ergänzen. |
| 6 | 09 | **Suricata:** Eine Regel auf `../` in `http.uri` meldet nicht, weil der Pfad normalisiert wird; `http.uri.raw` ist nötig. Die Option `stats.enabled=no` lässt Suricata abbrechen. | Hinweis in Einheit 9.2 ergänzen. |
| 7 | 10 | **CARP:** CARP und pfsync sind im Labor nicht verfügbar; keepalived (VRRP) ist nur ein Ersatz für das Prinzip. | Im Lehrplan klarstellen, dass die Einheit 10.3 auf OPNsense-CARP umzustellen ist. |
| 8 | 13 | **Abschlussprojekt:** Die Aufgabe hat mehrere Lösungen; der Lehrplan nennt keine Abnahmekriterien. | Testkatalog als Abnahmekriterium im Lehrplan aufnehmen. |

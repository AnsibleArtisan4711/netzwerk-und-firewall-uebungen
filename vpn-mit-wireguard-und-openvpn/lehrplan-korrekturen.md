# Anmerkungen zum Lehrplan P10

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | 05 | **Aufgabe 3:** Pingt `VM 1` als Erstes nach dem Neustart von `wg0`, gehen alle Pings verloren: der Server kennt den Endpoint des Clients erst nach dem ersten Paket des Clients. | In der Aufgabe: zuerst von `VM 2` pingen oder `PersistentKeepalive = 25`. |
| 2 | 05 | **Aufgabe 2:** `wg syncconf` verändert Routen weder beim Entfernen noch beim Wiedereintragen von `AllowedIPs` (Testumgebung). Der Lehrplan beschreibt nur das Wiedereintragen. | Erwartungsformulierung ergänzen; Hinweis auf Root-Shell bei `<(…)`. |
| 3 | 04 | **Aufgabe 4:** Tabelle 51820 und die Regeln von `wg-quick` bei `0.0.0.0/0` wurden in der Testumgebung bestätigt (`wireguard-go`). | Vermerk „nicht bestätigt“ kann entfallen, auf Debian 12 wiederholen. |
| 4 | 12 | **Aufgabe 2:** Falscher `tls-crypt`-Schlüssel: Meldung am Client nach rund 60 Sekunden und `tls-crypt unwrap error` am Server bestätigt. Verändertes Zeichen im Block `<cert>`: Client-Meldung `key values mismatch`, Server-Seite nicht beobachtet. | Aufgabentext präzisieren: Der Server-Fehler tritt beim falschen Schlüssel auf, nicht beim Zertifikat. |
| 5 | 12 | **Aufgabe 5:** `dynamic_debug` und das WireGuard-Kernelmodul waren in der Testumgebung nicht verfügbar. | Auf Debian-Kernel prüfen; Vermerk „nicht bestätigt“ belassen. |
| 6 | 12 | **Aufgabe 4:** MTU 1420 und Grenze 1392/1393 Byte wurden bestätigt (mit `wireguard-go`). | Mit Kernelmodul wiederholen. |
| 7 | 10 | **Aufgabe 3, Frage 3:** `MULTI: bad source address …` erscheint erst bei `verb 6` oder höher; bei `verb 3` nur Zeitüberschreitung. | Log-Stufe in der Aufgabe nennen. |
| 8 | 02, 11 | **Dummy-Interface:** `dummy0` fehlte in der Testumgebung (Container ohne Modul); die Adresse lag auf `lo`. | Auf Debian 12 prüfen. |
| 9 | 06 | **EasyRSA:** Testversion 3.1.7 (Ubuntu); die Version in Debian 12 ist nicht bestätigt. Gültigkeit der Zertifikate 825 Tage. | Version und Rückfragen vergleichen. |
| 10 | 07 | **Server-Konfiguration:** Relative Pfade funktionieren mit `--cd`; das Arbeitsverzeichnis des systemd-Dienstes wurde nicht geprüft. | systemd-Dienst prüfen. |
| 11 | 08 | **Client-Profil:** Die Testprofile enthielten zusätzlich `nobind`; der Lehrplan nennt die Direktive nicht. Das Profil wurde nur mit `nobind` getestet. | Profil ohne `nobind` prüfen. |
| 12 | 05, 10 | **Frage 3 / Frage 2:** Der Lehrplan sagt, Forwarding sei bei Site-to-Site zwingend. Für Pings zwischen den Gateways selbst wurde das nicht getestet (Forwarding war an); für Endgeräte hinter den Gateways ist es zwingend. | Aufgabe um einen Endgerät-Test (`lan-a`) ergänzen. |

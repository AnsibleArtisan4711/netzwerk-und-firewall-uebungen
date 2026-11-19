# 11 WebSocket

Übung **11.1** (Priorität 2, Vertiefung, kann bei Zeitmangel entfallen). Geschätzte Zeit: 4 bis 6 Stunden (Schätzung; Lehrplan: 7 UE zu 45 Minuten = 5,25 Stunden).

> Skript im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `11.1-websocket.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `websocket.sh` | WebSocket hinter nginx und HAProxy: fehlender Upgrade, richtige Header, Leerlaufzeit (read_timeout bzw. timeout tunnel). |
| `ws.cfg` | WebSocket über HAProxy: der Upgrade wird erkannt; für die Leerlaufzeit nach dem Upgrade gilt „timeout tunnel“ |
| `ws.conf` | WebSocket über nginx: ohne und mit Upgrade-Header, kurze und lange Leerlaufzeit |
| `ws_client.py` | Minimaler WebSocket-Client (nur Standardbibliothek): Handshake, Textnachricht, Antwort, optional Pause und zweite Nachricht. |
| `beispiele/websocket.ausgabe.txt` | Echte Ausgabe des Laufs von `websocket` |

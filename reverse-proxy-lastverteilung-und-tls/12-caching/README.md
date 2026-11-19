# 12 Caching

Übung **12.1** (Priorität 2, Vertiefung, kann bei Zeitmangel entfallen). Geschätzte Zeit: 5 bis 6 Stunden (Schätzung; Lehrplan: 8 UE zu 45 Minuten = 6 Stunden).

> Skript im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `12.1-caching.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `cache.conf` | Caching im Reverse Proxy (nginx): Zone, Gültigkeit aus dem Backend (Cache-Control), Bypass, veraltete Antworten bei Ausfall |
| `cache_demo.sh` | Caching im nginx-Proxy: MISS/HIT/EXPIRED/BYPASS/STALE, Cache-Datei, Verhalten bei Ausfall des Backends. |
| `beispiele/cache_demo.ausgabe.txt` | Echte Ausgabe des Laufs von `cache_demo` |

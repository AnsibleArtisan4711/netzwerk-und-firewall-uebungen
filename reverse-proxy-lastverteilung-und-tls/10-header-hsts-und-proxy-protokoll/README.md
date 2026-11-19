# 10 Header und PROXY

Übung **10.1** (Priorität 1). Geschätzte Zeit: 5 bis 6 Stunden (Schätzung; Lehrplan: 8 UE zu 45 Minuten = 6 Stunden).

> Skript im Container ausgeführt.

| Datei | Zweck |
|---|---|
| `10.1-header-hsts-und-proxy-protokoll.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `haproxy_pp.cfg` | Skript |
| `header.conf` | a) naiv: hängt die Client-Adresse an eine vom Client gelieferte Kette an |
| `header_proxyprotocol.sh` | Header am Proxy: gefälschtes X-Forwarded-For, Sicherheits-Header, versteckte Server-Angaben; echte Client-Adresse über das PROXY-Protokoll. |
| `beispiele/header_proxyprotocol.ausgabe.txt` | Echte Ausgabe des Laufs von `header_proxyprotocol` |

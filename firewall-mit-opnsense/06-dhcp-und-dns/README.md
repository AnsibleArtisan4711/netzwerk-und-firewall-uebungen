# 06 DHCP und DNS

Übung **06.1** (Priorität 1). Geschätzte Zeit: 5 bis 7 Stunden (Schätzung; Lehrplan: 9 UE zu 45 Minuten = 6,75 Stunden).

> Skript im Container ausgeführt (nftables-Nachbildung); OPNsense nicht geprüft.

| Datei | Zweck |
|---|---|
| `06.1-dhcp-und-dns.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `dhcp-hook.sh` | Ersatz für dhclient-script: setzt die Adresse und schreibt die Optionen nach /tmp/p08-hook.out (keine Änderung an /etc). |
| `dhcp_dns.sh` | Modul 6: DHCP und DNS auf der Firewall. OPNsense bringt eigene Dienste mit; hier wird dnsmasq als Stand-in verwendet. |
| `dnsmasq-lan.conf` | dnsmasq als Stand-in für DHCP- und DNS-Dienst der Firewall (LAN-Seite) |
| `beispiele/dhcp_dns.ausgabe.txt` | Echte Ausgabe des Laufs von `dhcp_dns` |

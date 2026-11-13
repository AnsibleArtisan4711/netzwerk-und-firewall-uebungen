# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf auf Debian 12: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = in der Testumgebung (Namespaces) ausgeführt; **–** = weder noch.

| Modul | Aussage oder Befehl | Status | Was zu prüfen ist |
|---|---|---|---|
| alle | Alle Befehle auf Debian 12 unter Hyper-V | – | im Labor ausführen und Befund eintragen |
| 01 | Aussagen zu IPsec, OpenVPN, WireGuard (Fachwissen) | – | gegen RFCs und Handbuch prüfen |
| 02 | `apt install`, Umstellen des Switches, Prüfpunkte | – | in den VMs ausführen |
| 02 | `/etc/network/interfaces` und `systemctl restart networking` unter Debian 12 | – | Debian-Dokumentation lesen, ausprobieren |
| 02 | persistentes `net.ipv4.ip_forward` in `/etc/sysctl.conf`, `sysctl -p`, Neustart | – (temporäres `sysctl -w` L) | nach Neustart prüfen |
| 02, 11, 12 | Kernelmodul `dummy`, `lab-dummy.sh` | – | `modprobe dummy` prüfen; in der Testumgebung stand `lo` stattdessen |
| 03 | `systemctl start wg-quick@wg0` | – | auf Debian 12 prüfen |
| 03, 04, 05, 12 | WireGuard-Kernelmodul (Testumgebung: `wireguard-go`) | L (mit wireguard-go) | mit Kernelmodul wiederholen, MTU 1420 prüfen |
| 04 | Tabelle 51820 und Regeln bei `AllowedIPs = 0.0.0.0/0` | L, Q (wg-quick-Skript) | bestätigt in der Testumgebung |
| 05 | `wg syncconf` und Routen | L | bestätigt; auf Debian 12 wiederholen |
| 06 | EasyRSA-Version und Pfad `/usr/share/easy-rsa` unter Debian 12 | L (3.1.7, Ubuntu) | Version vergleichen |
| 07 | `openvpn-server@server`, Arbeitsverzeichnis des Dienstes, relative Pfade | L (Pfade mit `--cd`) | systemd-Dienst prüfen |
| 08 | `scp`, SSH, `sudo`-Rechte von `labadmin` | – | prüfen |
| 08, 09, 10 | OpenVPN-Verbindung, ccd, `route`/`iroute` | L | auf Debian 12 wiederholen |
| 10 | Meldung `MULTI: bad source address …` | L (`verb 6`) | Log-Stufe notieren |
| 11 | Skript `lab-lan-a.sh` selbst; SSH-Regel; `nftables.service` | – (Befehle einzeln L) | Skript ausführen |
| 12 | `dynamic_debug`, `debugfs`, Kernelmeldungen von WireGuard | – (nicht prüfbar) | auf Debian-Kernel prüfen |
| 12 | Fehlerbild bei verändertem Zeichen im Zertifikat (Server-Seite) | L (nur Client-Meldung `key values mismatch`) | weitere Varianten ausprobieren |

Die Liste ist aus den Warnhinweisen der Module zusammengestellt und **nicht vollständig**.

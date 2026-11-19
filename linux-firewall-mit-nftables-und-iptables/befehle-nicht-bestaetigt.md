# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Aufbau des Hyper-V-Labors mit zwei privaten Switches, Internetphase für die Pakete | – | laut Lehrplan aufbauen und prüfen |
| alle | Namensgebung der Schnittstellen in den VMs (statt `v-fw1`, `v-fw2`) | – | Variablen `LAN` und `SRV` und `iifname`-Regeln anpassen |
| 01 | Hook-Zähler (`pfad_zaehlen.sh`); Aussagen zu Prioritäten der Kettentypen (raw, mangle, filter, security, nat) | L (nftables 1.0.9); Prioritäten – | Prioritäten gegen Handbuch lesen |
| 02 | `nft`-Grundbefehle (`add`, `insert`, `delete … handle`, `jump`) | L | mit der Debian-12-Version (nftables 1.0.6) wiederholen |
| 03 | `host_firewall.nft`, Test mit zweiter Quelladresse | L | in der VM wiederholen; `at`-Rückweg prüfen |
| 04 | `conntrack -L`, Zeitlimits (sysctl) | L (conntrack-tools 1.4.8) | Zeitlimits der VM mit denen des Labors vergleichen |
| 04 | Folge einer vollen Verbindungstabelle | – (Fachwissen) | mit `nf_conntrack_max` absichtlich provozieren |
| 05 | `sets_maps.nft`, Laufzeit-Änderungen an Sets | L | wiederholen |
| 06 | `masquerade`, `dnat`, `redirect`, `ct status dnat` | L | in der VM wiederholen |
| 07 | `zonen.nft` | L | in der VM wiederholen |
| 08 | `limit rate` (ICMP, meter je Quelladresse), nflog-Gruppen, tcpdump | L | Kernel-Log (`log` ohne Gruppe) und `ulogd2` prüfen |
| 09 | `nft -I`, `include`, atomares Laden | L | `nftables.service` und `/etc/nftables.conf` in der VM prüfen |
| 10 | `iptables`-Befehle, Zähler, Sicht in `nft list ruleset` | L (iptables 1.8.10 nf_tables) | `iptables-legacy` und `update-alternatives` prüfen |
| 11 | `iptables-restore-translate`, `iptables-translate`, `recent`-Modul | L | weitere Module (z. B. `string`, `recent`, `hashlimit`) auf Übersetzbarkeit prüfen |
| 12 | `ufw`, `firewall-cmd` (Zonen, Policy, rich rule, Reload) | L (ufw 0.36.2, firewalld 2.1.1; firewalld mit Python 3.12 gestartet) | in der VM (Debian 12) wiederholen; Zonenvorgaben der Pakete prüfen |
| 13 | `fehlersuche.sh`, `abschluss_loesung.nft`, `abschluss_test.sh` | L | wiederholen; Testkatalog erweitern |

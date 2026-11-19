#!/usr/bin/env bash
# Modul 8 (Priorität 2): VPN-Überblick. Der Kernel des Labors hat KEIN WireGuard-Modul, ein Tunnel wird deshalb NICHT aufgebaut.
# Gezeigt wird nur, was ohne Tunnel prüfbar ist: Schlüsselpaar erzeugen, Konfiguration aus einer Vorlage bauen, Aufbau prüfen.
umask 077
W=$(mktemp -d /tmp/p08-wg.XXXX); cd "$W"
step() { echo; echo "## $*"; }
step "1. Kann der Kernel einen WireGuard-Tunnel anlegen?"
echo '$ ip link add wgtest type wireguard'; ip link add wgtest type wireguard 2>&1 | head -1
step "2. Schlüsselpaare für Firewall und Gegenstelle erzeugen (nur Länge und Format, die Schlüssel selbst werden nicht gezeigt)"
wg genkey > fw.key; wg pubkey < fw.key > fw.pub; wg genkey > road.key; wg pubkey < road.key > road.pub
echo "privater Schlüssel: $(wc -c < fw.key) Zeichen inkl. Zeilenende; öffentlicher: $(wc -c < fw.pub) Zeichen"
grep -qE '^[A-Za-z0-9+/]{43}=$' fw.pub && echo "Format des öffentlichen Schlüssels: 44 Zeichen Base64 (korrekt)"
step "3. Konfiguration der Firewall-Seite aus der Vorlage (private Schlüssel geschwärzt)"
cat > wg0.conf <<RS
[Interface]
Address = 10.8.50.1/24
ListenPort = 51820
PrivateKey = $(cat fw.key)

[Peer]
# Mitarbeiter unterwegs
PublicKey = $(cat road.pub)
AllowedIPs = 10.8.50.2/32
RS
sed -E 's/^(PrivateKey = ).*/\1<geschwärzt>/; s/^(PublicKey = ).{6}.*/\1<öffentlicher Schlüssel von road>/' wg0.conf
step "4. Syntax prüfen, ohne den Tunnel zu starten (wg-quick strip entfernt wg-quick-Zeilen und gibt die reine WireGuard-Konfiguration aus)"
wg-quick strip ./wg0.conf >/dev/null 2>&1 && echo "wg-quick strip: Konfiguration lesbar" || echo "wg-quick strip: Fehler"
step "5. Was ein Tunnel zusätzlich braucht (auf der Firewall, nicht ausgeführt): Freigabe des UDP-Ports 51820 am WAN, Regeln für die Tunnelschnittstelle, ggf. NAT"
cd /; rm -rf "$W"

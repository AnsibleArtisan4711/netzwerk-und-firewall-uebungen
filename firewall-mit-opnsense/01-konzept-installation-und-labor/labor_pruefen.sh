#!/usr/bin/env bash
# Modul 1: Labor aufbauen und prüfen – Erreichbarkeit ohne Firewallregeln, Routen, Isolation des „Internets“.
. "$(dirname "$0")/../lab.sh"
lab_up
step "1. Adressen und Routen der Firewall (Stand-in für OPNsense: LAN, DMZ, WAN)"
cmd on fw ip -br addr show
cmd on fw ip route
step "2. Ohne Regeln: Weiterleitung eingeschaltet, alles erlaubt (nur im Labor!)"
test_ping cl 10.8.1.1; test_ping cl 10.8.2.2; test_http cl 10.8.2.2 80
step "3. Das „Internet“ (wan) kennt die internen Netze nicht: keine Rückroute"
cmd on wan ip route
test_http cl 10.8.9.1 80
step "4. Der Server im WAN-Netz ist von der Firewall aus erreichbar"
test_http fw 10.8.9.1 80
lab_down

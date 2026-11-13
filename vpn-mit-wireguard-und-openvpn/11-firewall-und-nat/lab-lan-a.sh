#!/bin/sh
# Modul 11, Aufgabe 1: ersetzt dummy0 durch einen simulierten Rechner lan-a (192.168.10.10)
# in einem Netzwerk-Namespace. Läuft auf VM 1 (vpn-a) als root.
# Stand: Entwurf; das Skript selbst wurde NICHT ausgeführt. Seine Befehle wurden in der Testumgebung
# von außen mit "ip -n" ausgeführt (dort ohne dummy0, die Adresse lag auf lo).
# Vor einem erneuten Lauf nach einem Neustart gegebenenfalls: ip netns del lan-a
ip addr flush dev dummy0
ip netns add lan-a
ip link add veth-gw type veth peer name veth-host
ip link set veth-host netns lan-a
ip addr add 192.168.10.1/24 dev veth-gw
ip link set veth-gw up
ip netns exec lan-a ip addr add 192.168.10.10/24 dev veth-host
ip netns exec lan-a ip link set veth-host up
ip netns exec lan-a ip link set lo up
ip netns exec lan-a ip route add default via 192.168.10.1

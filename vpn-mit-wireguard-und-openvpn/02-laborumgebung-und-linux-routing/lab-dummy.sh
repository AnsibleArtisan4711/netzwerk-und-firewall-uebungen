#!/bin/sh
# Modul 02, Aufgabe 4: simuliertes LAN des Standorts als Dummy-Schnittstelle (Debian-VM).
# VM 1: 192.168.10.1/24 (wie hier), VM 2: 192.168.20.1/24 - dazu die Adresse in Zeile 7 ändern.
# Stand: Entwurf; auf Debian 12 NICHT ausgeführt (das Kernelmodul dummy fehlte in der Testumgebung).
modprobe dummy
ip link show dummy0 >/dev/null 2>&1 || ip link add dummy0 type dummy
ip addr replace 192.168.10.1/24 dev dummy0
ip link set dummy0 up

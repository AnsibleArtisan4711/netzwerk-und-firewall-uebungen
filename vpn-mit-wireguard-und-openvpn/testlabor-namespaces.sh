#!/bin/bash
# Hilfsmittel (NICHT Teil des Lehrplans): baut das Zwei-Standorte-Labor ohne Hyper-V in zwei
# Netzwerk-Namespaces nach. So wurden die Befehle dieser Reihe getestet. Nur als root, nur auf einem
# Linux-Testrechner (nicht auf einem Produktivsystem). Benötigt: iproute2, wireguard-tools, wireguard-go
# (Userspace-WireGuard, falls kein Kernelmodul), openvpn, easy-rsa, nftables, tcpdump, iputils-ping.
#
# Verwendung:   source testlabor-namespaces.sh; lab_up          # Namespaces va (=VM 1) und vb (=VM 2)
#               nsx va wg-quick up /pfad/zu/wg0.conf            # Befehl im Namespace va
#               ip netns exec va ip -br a                       # beliebiger Befehl im Namespace
#               lab_down                                        # alles entfernen
# Unterschiede zu den VMs: Adapter eth0 (WAN) 10.0.0.1 bzw. 10.0.0.100; das LAN der Standorte liegt als
# Adresse auf lo (statt dummy0); kein systemd, kein SSH; WireGuard laeuft als wireguard-go.
# Stand: Entwurf; ausgefuehrt auf Ubuntu 24.04, nicht auf Debian 12.
nsx(){ local n=$1; shift; mkdir -p /run/wg-$n /run/wireguard
  ip netns exec $n unshare -m bash -c 'mount --bind /run/wg-'$n' /run/wireguard; export WG_QUICK_USERSPACE_IMPLEMENTATION=wireguard-go; "$@"' _ "$@"; }
lab_up(){
  set -e
  ip netns add va; ip netns add vb
  ip link add wanA type veth peer name wanB
  ip link set wanA netns va; ip link set wanB netns vb
  ip -n va link set wanA name eth0; ip -n vb link set wanB name eth0
  ip -n va addr add 10.0.0.1/24 dev eth0; ip -n vb addr add 10.0.0.100/24 dev eth0
  for n in va vb; do ip -n $n link set lo up; ip -n $n link set eth0 up; done
  ip -n va addr add 192.168.10.1/24 dev lo; ip -n vb addr add 192.168.20.1/24 dev lo
  ip netns exec va ping -c1 -W2 10.0.0.100 >/dev/null
  set +e
}
lab_down(){ pkill wireguard-go 2>/dev/null; pkill openvpn 2>/dev/null; sleep 1
  ip netns del lan-a 2>/dev/null; ip netns del va 2>/dev/null; ip netns del vb 2>/dev/null
  rm -rf /run/wg-va /run/wg-vb; }

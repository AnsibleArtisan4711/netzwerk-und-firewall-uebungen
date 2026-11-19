#!/usr/bin/env bash
# Fehlersuche an vier eingebauten Fehlern: Reihenfolge, falscher Schnittstellenname, fehlende Rückrichtung, ip_forward; dazu nft trace und tcpdump.
. "$(dirname "$0")/../lab.sh"
lab_up
regeln() { on fw nft -f - ; }
step "Fehler 1: Reihenfolge – das drop steht vor dem accept"
regeln <<'RS'
flush ruleset
table inet f {
  chain forward { type filter hook forward priority 0; policy drop;
  ct state established,related accept
  tcp dport 80 counter drop
  tcp dport 80 counter accept
  }
}
RS
http_get cl 10.0.2.2 80
echo "-- Diagnose: Zähler zeigen, welche Regel trifft"
on fw nft list chain inet f forward | grep counter
echo "-- Behebung: Regel ersetzen, indem das drop gelöscht wird"
H=$(on fw nft -a list chain inet f forward | awk '/counter packets [0-9]+ bytes [0-9]+ drop/ {print $NF}')
on fw nft delete rule inet f forward handle $H
http_get cl 10.0.2.2 80

step "Fehler 2: falscher Schnittstellenname in der Regel (eth0 statt v-fw1)"
regeln <<'RS'
flush ruleset
table inet f {
  chain forward { type filter hook forward priority 0; policy drop;
  ct state established,related accept
  iifname "eth0" tcp dport 80 counter accept
  }
}
RS
http_get cl 10.0.2.2 80
echo "-- Diagnose: Zähler der Regel bleibt 0; tatsächliche Namen mit ip -br link"
on fw nft list chain inet f forward | grep counter
on fw ip -br link show | grep v-fw
echo "-- Behebung: iifname v-fw1"
regeln <<'RS'
flush ruleset
table inet f {
  chain forward { type filter hook forward priority 0; policy drop;
  ct state established,related accept
  iifname "v-fw1" tcp dport 80 counter accept
  }
}
RS
http_get cl 10.0.2.2 80

step "Fehler 3: Rückrichtung fehlt (kein ct state established)"
regeln <<'RS'
flush ruleset
table inet f {
  chain forward { type filter hook forward priority 0; policy drop;
  iifname "v-fw1" tcp dport 80 counter accept
  }
}
RS
echo "-- Diagnose: tcpdump auf beiden Firewall-Schnittstellen mitschneiden, während der Client einmal zugreift"
( on fw timeout 5 tcpdump -n -l -i v-fw1 'tcp port 80' > /tmp/p09-innen.txt 2>/dev/null & )
( on fw timeout 5 tcpdump -n -l -i v-fw2 'tcp port 80' > /tmp/p09-aussen.txt 2>/dev/null & )
sleep 1; http_get cl 10.0.2.2 80; sleep 4.5
for f in innen aussen; do
  echo "$f: SYN=$(grep -c 'Flags \[S\],' /tmp/p09-$f.txt)  SYN/ACK=$(grep -c 'Flags \[S\.\],' /tmp/p09-$f.txt)"
done
echo "(innen = v-fw1 zum Client, aussen = v-fw2 zum Server: Die Antwort SYN/ACK des Servers kommt außen an, wird aber nicht nach innen weitergegeben.)"

step "Fehler 4: ip_forward ist aus"
regeln <<'RS'
flush ruleset
table inet f { chain forward { type filter hook forward priority 0; policy accept; counter
  }
}
RS
on fw sysctl -qw net.ipv4.ip_forward=0
http_get cl 10.0.2.2 80
echo "-- Diagnose: forward-Zähler bleibt 0, obwohl die Pakete an der Schnittstelle ankommen"
on fw nft list chain inet f forward | grep counter
on fw sysctl net.ipv4.ip_forward
on fw sysctl -qw net.ipv4.ip_forward=1
http_get cl 10.0.2.2 80
on fw nft list chain inet f forward | grep counter

step "Werkzeug: nft trace verfolgt ein Paket durch alle Ketten"
regeln <<'RS'
flush ruleset
table inet f {
  chain pre {
    type filter hook prerouting priority -300;
    tcp dport 80 meta nftrace set 1
  }
  chain forward { type filter hook forward priority 0; policy drop;
    ct state established,related accept
    iifname "v-fw1" tcp dport 80 accept
  }
}
RS
( on fw timeout 4 nft monitor trace 2>/dev/null | grep -E "^trace id" | sed -E 's/trace id [0-9a-f]+ //' | head -9 | cut -c1-150 > /tmp/p09-trace.txt & )
sleep 1; http_get cl 10.0.2.2 80 >/dev/null; sleep 3.5
cat /tmp/p09-trace.txt
lab_down

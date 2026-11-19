#!/usr/bin/env bash
# lab.sh – Testlabor aus vier Netzwerk-Namespaces: Client – Proxy – zwei Backends
#
#   cl (10.1.1.2/24) --- px (10.1.1.1/24 | 10.1.2.1/24) --- b1 (10.1.2.11/24), b2 (10.1.2.12/24)
#
# Namen (nur im Test): shop.lab.test und api.lab.test zeigen auf den Proxy 10.1.1.1 (Eintrag in /etc/hosts, wird am Ende entfernt).
# Nutzung in den Modulskripten:  . "$(dirname "$0")/../lab.sh"; lab_up ... lab_down
# Benötigt root, ip, nginx, haproxy, curl, openssl, python3. Nur im Testlabor ausführen.

P=p11
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy; export NO_PROXY='*' no_proxy='*'   # die Skripte sprechen nur mit dem Labor, nie über einen Proxy der Umgebung
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CA=/tmp/$P-ca

on() { local ns=$1; shift; ip netns exec "$P-$ns" "$@"; }          # on px nginx -t
cmd() { echo "\$ $*"; "$@" 2>&1; return $?; }
step() { echo; echo "## $*"; }
bg() { local ns=$1; shift; ( setsid ip netns exec "$P-$ns" "$@" >/dev/null 2>&1 < /dev/null & ); }   # Hintergrunddienst

lab_down() {
  { for n in cl px b1 b2; do ip netns pids "$P-$n" 2>/dev/null | xargs -r kill >/dev/null 2>&1; done; sleep 0.3
    for n in cl px b1 b2; do ip netns del "$P-$n" 2>/dev/null; done
    sed -i '/# p11-lab$/d' /etc/hosts; rm -f /tmp/$P-*.down; } 2>/dev/null
  wait 2>/dev/null
  return 0
}

lab_up() {
  lab_down
  for n in cl px b1 b2; do ip netns add "$P-$n"; on $n ip link set lo up; done
  ip link add v-cl type veth peer name v-px1;  ip link set v-cl netns $P-cl;  ip link set v-px1 netns $P-px
  ip link add v-b1 type veth peer name v-px2;  ip link set v-b1 netns $P-b1;  ip link set v-px2 netns $P-px
  ip link add v-b2 type veth peer name v-px3;  ip link set v-b2 netns $P-b2;  ip link set v-px3 netns $P-px
  on cl ip addr add 10.1.1.2/24 dev v-cl; on cl ip link set v-cl up; on cl ip route add default via 10.1.1.1
  on px ip addr add 10.1.1.1/24 dev v-px1; on px ip link set v-px1 up
  on px ip link add br-b type bridge; on px ip link set v-px2 master br-b; on px ip link set v-px3 master br-b
  on px ip link set v-px2 up; on px ip link set v-px3 up; on px ip addr add 10.1.2.1/24 dev br-b; on px ip link set br-b up
  on b1 ip addr add 10.1.2.11/24 dev v-b1; on b1 ip link set v-b1 up; on b1 ip route add default via 10.1.2.1
  on b2 ip addr add 10.1.2.12/24 dev v-b2; on b2 ip link set v-b2 up; on b2 ip route add default via 10.1.2.1
  printf '10.1.1.1 shop.lab.test api.lab.test # p11-lab\n' >> /etc/hosts
  bg b1 python3 "$HERE/backend.py" b1 8080
  bg b2 python3 "$HERE/backend.py" b2 8080
  sleep 0.8
}

# Zertifizierungsstelle und Serverzertifikat (siehe Modul 4); idempotent
ca_erzeugen() {
  [ -f $CA/server.pem ] && return 0
  mkdir -p $CA && cd $CA || return 1
  openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.pem -days 30 -subj "/O=Lab/CN=Lab Root CA" >/dev/null 2>&1
  openssl req -newkey rsa:2048 -nodes -keyout server.key -out server.csr -subj "/O=Lab/CN=shop.lab.test" >/dev/null 2>&1
  printf 'subjectAltName=DNS:shop.lab.test,DNS:api.lab.test\nbasicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\n' > san.ext
  openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out server.crt -days 30 -extfile san.ext >/dev/null 2>&1
  cat server.crt server.key > server.pem      # für HAProxy: Zertifikat und Schlüssel in einer Datei
  cd - >/dev/null
}

# weiteres Serverzertifikat nur für einen Namen: zert_erzeugen NAME  ->  $CA/NAME.pem (Zertifikat + Schlüssel)
zert_erzeugen() {
  ca_erzeugen; cd $CA || return 1
  openssl req -newkey rsa:2048 -nodes -keyout $1.key -out $1.csr -subj "/O=Lab/CN=$1" >/dev/null 2>&1
  printf 'subjectAltName=DNS:%s\nbasicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\n' "$1" > $1.ext
  openssl x509 -req -in $1.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out $1.crt -days 30 -extfile $1.ext >/dev/null 2>&1
  cat $1.crt $1.key > $1.pem; cd - >/dev/null
}

# Hilfen für Tests
von_cl() { on cl curl -s -m 3 "$@"; }
verteilung() {   # verteilung N URL [curl-Optionen]: zählt, welches Backend wie oft antwortet
  local n=$1 url=$2; shift 2
  for i in $(seq 1 "$n"); do on cl curl -s -m 3 "$@" "$url" 2>/dev/null | sed -n 's/^backend=//p'; done | sort | uniq -c | sed 's/^ *//'
}

# ---------------------------------------------------------------- Dienste im Proxy-Namespace
# nginx: Rahmen für den Testbetrieb (Pfade unter /tmp). In einem Debian-Paket steht dieser Rahmen schon in /etc/nginx/nginx.conf;
# die Übungsdatei enthält nur, was in http { } gehört (server, upstream, map …).
# nginx_start HTTP-DATEI [OBERSTE-EBENE-DATEI]
nginx_stop() { [ -f /tmp/$P-nginx/nginx.pid ] && kill "$(cat /tmp/$P-nginx/nginx.pid)" 2>/dev/null; sleep 0.4; return 0; }
nginx_start() {
  nginx_stop
  rm -rf /tmp/$P-nginx; mkdir -p /tmp/$P-nginx
  { echo "worker_processes 1; pid /tmp/$P-nginx/nginx.pid; error_log /tmp/$P-nginx/error.log info; daemon off;"
    echo "load_module /usr/lib/nginx/modules/ngx_stream_module.so;"
    [ -n "$2" ] && cat "$2"
    echo "events { worker_connections 256; }"
    echo "http { access_log /tmp/$P-nginx/access.log; client_body_temp_path /tmp/$P-nginx/body; proxy_temp_path /tmp/$P-nginx/proxy;"
    echo "  fastcgi_temp_path /tmp/$P-nginx/fcgi; uwsgi_temp_path /tmp/$P-nginx/uwsgi; scgi_temp_path /tmp/$P-nginx/scgi;"
    echo "  include $1; }"; } > /tmp/$P-nginx.conf
  on px nginx -t -c /tmp/$P-nginx.conf 2>&1 | sed 's#/tmp/p11-nginx.conf#nginx.conf#'
  bg px nginx -c /tmp/$P-nginx.conf; sleep 0.7
}
nginx_neu_laden() { kill -HUP "$(cat /tmp/$P-nginx/nginx.pid)"; sleep 0.5; }
# HAProxy: haproxy_start KONFIGURATION (komplette Datei; Admin-Socket /tmp/p11-haproxy.sock)
haproxy_pruefen() { on px haproxy -c -f "$1" 2>&1 | grep -v '^\[NOTICE\]' | sed -E 's/\([0-9]+\)/(PID)/; s#[^ []*/([^/ ]+\.cfg)#\1#g'; }
haproxy_start() {
  rm -f /tmp/$P-haproxy.sock
  haproxy_pruefen "$1"
  bg px haproxy -f "$1"; sleep 0.8
}
haproxy_tabelle() { haproxy_cli "show stat" | awk -F, 'NR>1 && $1!="" {printf "%-12s %-10s %s\n", $1, $2, $18}'; }
haproxy_cli() { echo "$1" | on px socat stdio /tmp/$P-haproxy.sock; }

#!/usr/bin/env bash
# Ersatz für dhclient-script: setzt die Adresse und schreibt die Optionen nach /tmp/p08-hook.out (keine Änderung an /etc).
case "$reason" in
  BOUND|REBOOT|RENEW|REBIND)
    ip addr flush dev "$interface"; ip addr add "$new_ip_address/$new_subnet_mask" dev "$interface"
    echo "Hook: reason=$reason ip=$new_ip_address router=$new_routers dns=$new_domain_name_servers domain=$new_domain_name lease=${new_dhcp_lease_time}s" >> /tmp/p08-hook.out ;;
esac
exit 0

#!/bin/bash
set -euo pipefail
#varibales
read -p "ENTER TDOMAIN:" TDOMAIN
acme.sh --issue -d $TDOMAIN --dns dns_cf --server letsencrypt
acme.sh --install-cert -d $TDOMAIN --key-file /usr/local/etc/acme/private.key --fullchain-file /usr/local/etc/acme/certificate.crt
systemctl restart trojan
systemctl restart nginx

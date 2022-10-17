#!/bin/bash
set -euo pipefail

read -p "ENTER PWD TDOMAIN RTDOMAIN TIP:" PWD TDOMAIN RTDOMAIN TIP

#~/.acme.sh/acme.sh --issue -d $TDOMAIN --dns dns_cf --server letsencrypt
#~/.acme.sh/acme.sh --install-cert -d $TDOMAIN --key-file /usr/local/etc/acme/private.key --fullchain-file /usr/local/etc/acme/certificate.crt

echo $PWD |sudo -S bash -c "$(cat <<AAA
cat > /etc/nginx/sites-available/default <<-EOF
server {
    listen 127.0.0.1:80 default_server;
    server_name $TDOMAIN;
    include /etc/nginx/conf.d/agentdeny;
    include /etc/nginx/bots.d/blockbots.conf;
    include /etc/nginx/bots.d/ddos.conf;
    location / {
    proxy_pass https://$RTDOMAIN;
    }
}
server {
    listen 127.0.0.1:80;
    server_name $TIP;
    include /etc/nginx/conf.d/agentdeny;
    include /etc/nginx/bots.d/blockbots.conf;
    include /etc/nginx/bots.d/ddos.conf;
    return 301 https://$TDOMAIN\$request_uri;
}
server {
    listen 0.0.0.0:80;
    listen [::]:80;
    server_name _;
    return 444 ;
}
EOF

systemctl restart nginx
AAA
)"
echo Done！

#VERSION=$(curl -fsSL https://api.github.com/repos/trojan-gfw/trojan/releases/latest | grep tag_name | sed -E 's/.*"v(.*)".*/\1/')
#!/bin/bash
set -euo pipefail
 
#varibales
NAME=trojan
VERSION=1.16.0
TMPDIR="$(mktemp -d)"
INSTALLPREFIX=/usr/local
SYSTEMDPREFIX=/etc/systemd/system
BINARYPATH="$INSTALLPREFIX/bin/$NAME"
CONFIGPATH="$INSTALLPREFIX/etc/$NAME/config.json"
SYSTEMDPATH="$SYSTEMDPREFIX/$NAME.service"
read -p "ENTER USER TDOMAIN RTDOMAIN TIP TPWD EMAIL KEY:" USER TDOMAIN RTDOMAIN TIP TPWD EMAIL KEY

#acme
sudo -s <<AAA
apt install -y socat cron curl
if [ ! -d "/usr/local/etc/acme" ]; then
mkdir /usr/local/etc/acme
fi
chown -R $USER:$USER /usr/local/etc/acme
AAA
curl  https://get.acme.sh | sh
export CF_Key="$KEY"
export CF_Email="$EMAIL"
~/.acme.sh/acme.sh --issue -d $TDOMAIN --dns dns_cf --server letsencrypt
~/.acme.sh/acme.sh --install-cert -d $TDOMAIN --key-file /usr/local/etc/acme/private.key --fullchain-file /usr/local/etc/acme/certificate.crt
~/.acme.sh/acme.sh  --upgrade  --auto-upgrade
chmod -R 750 /usr/local/etc/acme

sudo -s <<BBB
#trojan 1
useradd -r trojan
adduser trojan $USER

wget -P "$TMPDIR" https://github.com/xlabr/u/releases/download/$VERSION/trojan
wget -P "$TMPDIR" https://github.com/xlabr/u/releases/download/$VERSION/server.json-example

cd "$TMPDIR"
install -Dm755 "$NAME" "$BINARYPATH"

if ! [[ -f "$CONFIGPATH" ]] || prompt "The server config already exists in $CONFIGPATH, overwrite?"; then
    install -Dm644 server.json-example "$CONFIGPATH"
else
    echo Skipping installing $NAME server config...
fi

if [[ -d "$SYSTEMDPREFIX" ]]; then
    echo Installing $NAME systemd service to $SYSTEMDPATH...
    if ! [[ -f "$SYSTEMDPATH" ]] || prompt "The systemd service already exists in $SYSTEMDPATH, overwrite?"; then
        cat > "$SYSTEMDPATH" << EOF
[Unit]
Description=$NAME
Documentation=https://xlabr.github.io/$NAME/config https://xlabr.github.io/t/
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service
[Service]
Type=simple
StandardError=journal
ExecStart="$BINARYPATH" "$CONFIGPATH"
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=51200
Restart=on-failure
RestartSec=1s
[Install]
WantedBy=multi-user.target
EOF
        echo Reloading systemd daemon...
        systemctl daemon-reload
    else
        echo Skipping installing $NAME systemd service...
    fi
fi

#trojan 2
sed -i '3s/0.0.0.0/::/g' /usr/local/etc/trojan/config.json
sed -i "8s/password1\",/$TPWD\"/g" /usr/local/etc/trojan/config.json
sed -i '13s/path\/to/usr\/local\/etc\/acme/g' /usr/local/etc/trojan/config.json
sed -i '14s/path\/to/usr\/local\/etc\/acme/g' /usr/local/etc/trojan/config.json
sed -i '9d' /usr/local/etc/trojan/config.json

#trojan 3
chown -R trojan:trojan /usr/local/etc/trojan
apt install -y libcap2-bin
setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/trojan
echo trojan Done!

#nginx setting
apt install -y nginx
bash -c "$(curl -fsSL https://raw.githubusercontent.com/xlabr/u/sh/nginx-block.sh)"
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
echo nginx Done!

systemctl enable trojan
systemctl enable nginx

systemctl restart trojan
systemctl restart nginx

echo Deleting temp directory $TMPDIR...
rm -rf "$TMPDIR"
BBB
echo Done!

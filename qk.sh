#!/bin/bash
set -euo pipefail

function prompt() {
    while true; do
        read -p "$1 [y/N] " yn
        case $yn in
            [Yy] ) return 0;;
            [Nn]|"" ) return 1;;
        esac
    done
}

if [[ $(id -u) != 0 ]]; then
    echo Please run this script as root.
    exit 1
fi

if [[ $(uname -m 2> /dev/null) != x86_64 ]]; then
    echo Please run this script on x86_64 machine.
    exit 1
fi

read -p "ENTER TDOMAIN RTDOMAIN TIP TPWD:" TDOMAIN RTDOMAIN TIP TPWD

NAME=trojan
VERSION=$(curl -fsSL https://api.github.com/repos/trojan-gfw/trojan/releases/latest | grep tag_name | sed -E 's/.*"v(.*)".*/\1/')
TMPDIR="$(mktemp -d)"
INSTALLPREFIX=/usr/local
SYSTEMDPREFIX=/etc/systemd/system

BINARYPATH="$INSTALLPREFIX/bin/$NAME"
CONFIGPATH="$INSTALLPREFIX/etc/$NAME/config.json"
SYSTEMDPATH="$SYSTEMDPREFIX/$NAME.service"
 
wget -P "$TMPDIR" https://github.com/xlabr/u/releases/download/$VERSION/trojan
wget -P "$TMPDIR" https://github.com/xlabr/u/releases/download/$VERSION/server.json-example

echo Entering temp directory $TMPDIR...
cd "$TMPDIR"

echo Installing $NAME $VERSION to $BINARYPATH...
install -Dm755 "$NAME" "$BINARYPATH"

echo Installing $NAME server config to $CONFIGPATH...
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

#custon trojan json
sed -i "8s/password1\",/$TPWD\"/g" /usr/local/etc/trojan/config.json
sed -i '13s/path\/to/usr\/local\/etc\/acme/g' /usr/local/etc/trojan/config.json
sed -i '14s/path\/to/usr\/local\/etc\/acme/g' /usr/local/etc/trojan/config.json
sed -i '9d' /usr/local/etc/trojan/config.json

#
chown -R trojan:trojan /usr/local/etc/trojan
apt install -y libcap2-bin
setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/trojan

echo trojan Done!

#nginx setting

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

echo Done！

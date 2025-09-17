#!/bin/bash
sudo service firewalld stop
sudo systemctl disable --now firewalld

#sudo nano /etc/selinux/config
#SELINUX=disabled

echo 'export CF_Token=\"2xhHe1Wuq_Umqr0lObDNGESk583VUZaDAyVrzrWr\"' >>.bashrc
echo 'export CF_Email=\"nicki2019@outlook.com\"' >>.bashrc
curl https://get.acme.sh | sh -s email=nickji2019@outlook.com
source .bashrc
acme.sh --upgrade --auto-upgrade

acme.sh --issue -d vpn.woznes.com --dns dns_cf --keylength ec-256 --server letsencrypt --force

acme.sh --install-cronjob



sudo yum install nginx -y
sudo systemctl enable --now nginx
sudo service nginx restart

wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-arm.zip
unzip trojan-go-linux*.zip
touch config.json



sudo nano /etc/systemd/system/trojan-go.service

[Unit]
Description=trojan-go service
After=network.target

[Service]
ExecStart=/home/opc/trojan-go -config /home/opc/config.json
ExecStop=/bin/kill -s SIGTERM $MAINPID
ExecReload=/bin/kill -s HUP $MAINPID
Type=simple
Restart=always
RestartSec=5
StartLimitIntervalSec=30
StartLimitBurst=3
User=root
WorkingDirectory=/home/opc
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl enable --now trojan-go
systemctl status trojan-go

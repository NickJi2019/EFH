#!/bin/bash
echo """
Welcome to the trojan-fo installer script!
!!! Attention !!!
This script will disable SELinux, firewall, and install dependencies.

requirements:
 - root permission
 - internet connection
 - registered domain name on Cloudflare
 - Cloudflare Account API token with DNS zone edit permission
 - Cloudflare email address
"""

#GREEN='\033[0;32m'
#RED='\033[0;31m'
#YELLOW='\033[1;33m'
#NC='\033[0m'

# Check root permission
if [[ $EUID -ne 0 ]]; then
  echo "${RED}Please run as root$NC"
  exit 1
fi

echo "Do you want to continue? [y/N]"
read -r -p "" input
if [[ ! $input =~ ^[Yy]$ ]]; then
  exit 1
fi

read -r -p "Enter your email address: " EMAIL

# Check Email address format
if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
  echo "${RED}invalid email address: $EMAIL$NC"
  exit 1
fi

read -r -p "Enter your Cloudflare Account API token: " CFToken

# Validating Cloudflare Account API token and permission for DNS zone edit
echo "Validating Cloudflare Account API token..."
if ! curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
  -H "Authorization: Bearer $CFToken" \
  -H "Content-Type: application/json" | grep -q '"success":true'; then
  echo "${RED}Your Global API Key is invalid.$NC"
  exit 1
fi
echo "${GREEN}Your CF_Token is valid.$NC"

read -r -p "Enter your root domain: " DOMAIN
read -r -p "Enter your sub domain: " SUBDOMAIN

# Check if domain is available on Cloudflare
echo "Checking if $DOMAIN is available on Cloudflare..."
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
  -H "Authorization: Bearer $CFToken" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [[ "$ZONE_ID" == "null" || -z "$ZONE_ID" ]]; then
  echo "${RED}$DOMAIN is not available on your Cloudflare account.$NC"
  exit 1
fi
echo "${GREEN}$DOMAIN is available on your Cloudflare account.$NC"

echo "Checking if DNS permission is enabled for $DOMAIN..."
resp=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CFToken" \
  -H "Content-Type: application/json")

if echo "$resp" | grep -q '"success":true'; then
  echo "${GREEN}Your token have DNS permission to $DOMAIN$NC"
else
  echo "${RED}Your token does not have DNS permission to $DOMAIN$NC"
  exit 1
fi


# Get CPU info
arch=$(uname -m)
echo "CPU Architecture: $arch"

# Disable SELinux
echo "Detecting SELinux..."
if command -v getenforce >/dev/null 2>&1; then
  echo "SELinux is detected. Disabling..."
  setenforce 0
  sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
  echo "SELinux disabled."
fi

pm=""
release=""

# Detect release and package manager
echo "Detecting OS Release..."
. /etc/os-release
echo "OS: $NAME $VERSION_ID"
if [[ "$ID_LIKE" == *"debian"* ]] || [[ "$ID_LIKE" == *"ubuntu"* ]]; then
  echo "Debian/Ubuntu detected."
  echo "Using apt-get as package manager."
  echo "Installing dependencies..."
  apt-get update
  apt-get install -y curl wget unzip
  pm="apt"
  release="debian"
elif [[ "$ID_LIKE" == *"rhel"* ]] || [[ "$ID_LIKE" == *"fedora"* ]] || [[ "$ID_LIKE" == *"centos"* ]]; then
  echo "Fedora/CentOS detected."
  echo "Using dnf as package manager."
  echo "Installing dependencies..."
  dnf install -y curl wget unzip
  pm="dnf"
  release="fedora"
else
  echo "Unsupported OS."
  exit 1
fi

# Disable firewall
echo "Detecting firewall type..."
if command -v ufw >/dev/null 2>&1; then
  echo "ufw detected. Disabling..."
  ufw disable
  ufw reset
  ufw default allow incoming
  systemctl stop ufw
  systemctl disable --now ufw
elif systemctl list-unit-files | grep -q firewalld; then
  echo "firewalld detected. Disabling..."
  systemctl stop firewalld
  systemctl disable --now firewalld
elif command -v firewall-cmd >/dev/null 2>&1; then
  echo "firewalld detected. Disabling..."
  systemctl stop firewalld
  systemctl disable --now firewalld
elif command -v nft >/dev/null 2>&1; then
  echo "nft detected. Disabling..."
  nft flush ruleset
  nft delete table inet filter
  nft delete table ip nat
  nft add table inet filter
  nft 'add chain inet filter input { type filter hook input priority 0; policy accept; }'
  nft 'add chain inet filter forward { type filter hook forward priority 0; policy accept; }'
  nft 'add chain inet filter output { type filter hook output priority 0; policy accept; }'
  if [[ $release == "debian" ]]; then
    sh -c "nft list ruleset > /etc/nftables.conf"
  elif [[ $release == "fedora" ]]; then
    nft list ruleset | sudo tee /etc/sysconfig/nftables.conf
  fi
  systemctl stop nftables
  systemctl disable --now nftables
elif command -v iptables >/dev/null 2>&1; then
  echo "iptables detected. Disabling..."
  iptables -F
  iptables -X
  sudo iptables -t nat -F
  sudo iptables -t nat -X
  sudo iptables -t mangle -F
  sudo iptables -t mangle -X
  sudo iptables -t raw -F
  sudo iptables -t raw -X
  iptables -P INPUT ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -P FORWARD ACCEPT
  systemctl stop iptables
  systemctl disable --now iptables
fi
echo "Firewall disabled."


# Downloading trojan-go
echo "Downloading trojan-go"
case $arch in
"x86_64")
  wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
  ;;
"aarch64")
  wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-armv8.zip
  ;;
"armv7l"|"armv8l")
  wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-armv7.zip
  ;;
"armv6l")
  wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-armv6.zip
  ;;
"armv5"*)
  wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-armv5.zip
  ;;
"arm"*)
  wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-arm.zip
  ;;
"mips64")
  wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-mips64.zip
  ;;
"mips64le")
  wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-mips64le.zip
  ;;
"i386"|"i486"|"i586"|"i686")
  wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-386.zip
  ;;
*)
  echo "Unsupported architecture."
  exit 1
  ;;
esac

unzip trojan-go-linux*.zip
rm trojan-go-linux*.zip
echo "trojan-go installed."

# Creating service
echo "Creating service..."
touch /etc/systemd/system/trojan-go.service
cat > /etc/systemd/system/trojan-go.service <<EOF
[Unit]
Description=trojan-go service
After=network.target

[Service]
ExecStart=$(pwd)/trojan-go -config $(pwd)/config.json
ExecStop=/bin/kill -s SIGTERM \$MAINPID
ExecReload=/bin/kill -s HUP \$MAINPID
Type=simple
Restart=always
RestartSec=5
StartLimitIntervalSec=30
StartLimitBurst=3
User=root
WorkingDirectory=$(pwd)
StandardOutput=syslog
StandardError=syslog

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload


touch config.json
cat > config.json <<EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "log_level": 1,
    "log_file": "",
    "password": [
        "114514"
    ],
    "disable_http_check": false,
    "udp_timeout": 60,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "$(pwd)/cert/fullchain.cer",
        "key": "$(pwd)/cert/${SUBDOMAIN}.${DOMAIN}.key",
        "key_password": "",
        "cipher": "",
        "curves": "",
        "prefer_server_cipher": false,
        "sni": "",
        "alpn": [
            "http/1.1"
        ],
        "session_ticket": true,
        "reuse_session": true,
        "plain_http_response": "",
        "fallback_addr": "",
        "fallback_port": 0,
        "fingerprint": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "prefer_ipv4": false
    },
    "mux": {
        "enabled": false,
        "concurrency": 8,
        "idle_timeout": 60
    },
    "router": {
        "enabled": false,
        "bypass": [],
        "proxy": [],
        "block": [],
        "default_policy": "proxy",
        "domain_strategy": "as_is",
        "geoip": "\$PROGRAM_DIR\$/geoip.dat",
        "geosite": "\$PROGRAM_DIR\$/geosite.dat"
    },
    "websocket": {
        "enabled": false,
        "path": "",
        "host": ""
    },
    "shadowsocks": {
        "enabled": false,
        "method": "AES-128-GCM",
        "password": ""
    },
    "transport_plugin": {
        "enabled": false,
        "type": "",
        "command": "",
        "option": "",
        "arg": [],
        "env": []
    },
    "forward_proxy": {
        "enabled": false,
        "proxy_addr": "",
        "proxy_port": 0,
        "username": "",
        "password": ""
    },
    "mysql": {
        "enabled": false,
        "server_addr": "localhost",
        "server_port": 3306,
        "database": "",
        "username": "",
        "password": "",
        "check_rate": 60
    },
    "api": {
        "enabled": true,
        "api_addr": "0.0.0.0",
        "api_port": 444,
        "ssl": {
            "enabled": true,
            "key": "$(pwd)/cert/api.key",
            "cert": "$(pwd)/cert/api.crt",
            "verify_client": true,
            "client_cert": ["$(pwd)/cert/apiserver.crt"]
        }
    }
}
EOF


# Install nginx
echo "Installing nginx..."
eval "$pm" install nginx -y

systemctl enable --now nginx
service nginx restart


# Generating config for trojan-go
echo "Generating config for trojan-go..."
mkdir cert
: > cert/api.key
: > cert/api.crt
: > cert/apiserver.crt
: > cert/ca.crt

echo "Please input your API Cert: "

in_block=0
while IFS= read -r line; do
  if [[ "$line" == -----BEGIN* ]]; then
    in_block=1
    echo "$line" >> "cert/api.crt"
  fi
  if [[ $in_block -eq 1 ]]; then
    echo "$line" >> "cert/api.crt"
  fi
  if [[ "$line" == -----END* ]]; then
    echo "$line" >> "cert/api.crt"
    break
  fi
done

echo "Please input your API Cert private key: "
in_block=0
while IFS= read -r line; do
  if [[ "$line" == -----BEGIN* ]]; then
    in_block=1
    echo "$line" >> "cert/api.key"
  fi
  if [[ $in_block -eq 1 ]]; then
    echo "$line" >> "cert/api.key"
  fi
  if [[ "$line" == -----END* ]]; then
    echo "$line" >> "cert/api.key"
    break
  fi
done

echo "Please input your API Cert of client: "
in_block=0
while IFS= read -r line; do
  if [[ "$line" == -----BEGIN* ]]; then
    in_block=1
    echo "$line" >> "cert/apiserver.crt"
  fi
  if [[ $in_block -eq 1 ]]; then
    echo "$line" >> "cert/apiserver.crt"
  fi
  if [[ "$line" == -----END* ]]; then
    echo "$line" >> "cert/apiserver.crt"
    break
  fi
done

echo "Please input your CA Cert: "
in_block=0
while IFS= read -r line; do
  if [[ "$line" == -----BEGIN* ]]; then
    in_block=1
    echo "$line" >> "cert/ca.crt"
  fi
  if [[ $in_block -eq 1 ]]; then
    echo "$line" >> "cert/ca.crt"
  fi
  if [[ "$line" == -----END* ]]; then
    echo "$line" >> "cert/ca.crt"
    break
  fi
done

if [[ $release == "debian" ]]; then
  cp cert/ca.crt /usr/local/share/ca-certificates/
  update-ca-certificates
fi
if [[ $release == "fedora" ]]; then
  cp cert/ca.crt /etc/pki/ca-trust/source/anchors/
  update-ca-trust extract
fi

# Install acme.sh
echo "Installing acme.sh..."
curl https://get.acme.sh | sh -s email=$EMAIL --home $(pwd)/acme.sh

# Install SSL certificate
export CF_Email="$EMAIL"
export CF_Token="$CFToken"
$(pwd)/acme.sh/acme.sh --upgrade --auto-upgrade
echo "Installing SSL certificate..."
if $(pwd)/acme.sh/acme.sh --issue -d ${SUBDOMAIN}.${DOMAIN} --dns dns_cf --keylength ec-256 --server letsencrypt --nocron --force; then
  echo "SSL certificate installed."
  $(pwd)/acme.sh/acme.sh --set-default-ca --server letsencrypt
  $(pwd)/acme.sh/acme.sh --install-cronjob
  $(pwd)/acme.sh/acme.sh --install-cert -d ${SUBDOMAIN}.${DOMAIN} \
    --key-file       $(pwd)/cert/${SUBDOMAIN}.${DOMAIN}key \
    --fullchain-file $(pwd)/cert/fullchain.cer \
    --reloadcmd     "systemctl reload trojan-go"
else
  echo "Failed to install SSL certificate."
  exit 1
fi

systemctl start trojan-go
systemctl enable --now trojan-go
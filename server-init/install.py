import os
import platform
from os import *
import subprocess

def exe(command:str):
   result = os.popen(command).read()
   print(result)

cwd = getcwd()
print(f'your current dir is {cwd}')
print("moving to /home/ubuntu/\n")
chdir("/home/ubuntu/")

print("writing Cloudflare account config\n")
exe("echo 'export CF_Token=\"2xhHe1Wuq_Umqr0lObDNGESk583VUZaDAyVrzrWr\"' >> .bashrc")
exe("echo 'export CF_Email=\"nicki2019@outlook.com\"' >> .bashrc")
print("downloading acme\n")
exe("curl https://get.acme.sh | sh -s email=nickji2019@outlook.com")
exe("source .bashrc")
exe("acme.sh --upgrade --auto-upgrade")
print("starting to assign cert\n")
domain=input("please enter the domain: ")
exe(f"acme.sh --issue -d {domain} --dns dns_cf --keylength ec-256 --server letsencrypt --force")
print("installing cronjob\n")
exe("acme.sh --install-cronjob")

print("downloading nginx\n")
exe("sudo apt install nginx -y")
exe("sudo systemctl enable --now nginx")
exe("sudo service nginx restart")

print("downloading trojan-go")
if platform.machine() == "aarch64":
    exe("wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-arm.zip")
elif platform.machine() == "x86_64":
    exe("wget https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip")

print("unzipping trojan-go")
exe("unzip trojan-go-linux*.zip")

print("configuring trojan")
exe("touch config.json")
exe(f"""echo "{
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
        "cert": ".acme.sh/{domain}_ecc/fullchain.cer",
        "key": ".acme.sh/{domain}_ecc/{domain}.key",
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
        "fallback_port": 1234,
        "fingerprint": ""
    }
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
        "geoip": "$PROGRAM_DIR$/geoip.dat",
        "geosite": "$PROGRAM_DIR$/geosite.dat"
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
        "api_addr": "127.0.0.1",
        "api_port": 444,
        "ssl": {
            "enabled": false,
            "key": "",
            "cert": "",
            "verify_client": false,
            "client_cert": []
        }
    }
}" >> config.json""")


print("done")

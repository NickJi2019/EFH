# EFH · Escape From HDSB Project

[简体中文](README_ZH.md)

[![GitHub stars](https://img.shields.io/github/stars/NickJi2019/EFH?style=social)](https://github.com/NickJi2019/EFH)
[![License](https://img.shields.io/github/license/NickJi2019/EFH)](LICENSE.txt)
[![Release](https://img.shields.io/github/v/release/NickJi2019/EFH?include_prereleases&label=release)](https://github.com/NickJi2019/EFH/releases)

> Let everyone enjoy internet freedom.

EFH (Escape From HDSB Project) is a network acceleration and access-freedom project: it provides **Trojan**-based proxy nodes and subscription delivery, along with a set of handy tools (service status, website blocking checker, etc.). The frontend sticks to zero dependencies and loads fast.

- Site: <https://vpn.woznes.com>
- Repo: <https://github.com/NickJi2019/EFH>
- License: [MIT](LICENSE.txt)

## Features

- **One-click config import** — generate subscription links from a password hash; supports Clash / Shadowrocket / Surge, with manual copy as a fallback.
- **Service status** — browser-side direct latency plus server-side (mihomo) node reachability, double-checked.
- **Website blocking check** — based on the Cloudflare Radar Top domain list, probes locally whether a site is blocked by HDSB.
- **Appearance & language** — dark / light / follow system, Simplified Chinese / English, switchable from the navbar.

## Tech Stack

| Layer | Tech |
| --- | --- |
| Server | Kotlin + Ktor (Netty), Redisson (Redis) |
| Node | trojan-go + nginx, certificates issued and renewed automatically by acme.sh |
| Frontend | Vanilla HTML / CSS / JavaScript (Bootstrap 4 theme), home-grown lightweight i18n and theme scripts |
| Client | Flutter (`efh_connectivity_test`) |
| Deployment | Fat JAR + systemd |

## Repository Layout

```
EFH/
├── EFHServer/                  Ktor server (also hosts the static site)
│   ├── src/main/kotlin/        Application / Routing / Status / TopDomains / Redis
│   └── src/main/resources/
│       ├── static/             Frontend static site (HTML / CSS / JS)
│       ├── clash.yaml          subscription template
│       ├── shadowrocket.conf   subscription template
│       └── application.yaml    Ktor config (port 80)
├── EFHServerSetup/             trojan-go server one-click install script
│   ├── install.sh
│   └── config.json
├── efh_connectivity_test/      Flutter client
├── deploy.sh                   one-click deploy script
├── DEPLOY.md                   deployment guide
└── LICENSE.txt                 MIT
```

## Quick Start

### Install the node (trojan-go server) in one command

On your server:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/NickJi2019/EFH/refs/heads/main/EFHServerSetup/install.sh)"
```

The script installs dependencies, issues a certificate with acme.sh, and configures nginx and trojan-go. Before running it, prepare:

- root access and a working network
- a domain hosted on Cloudflare
- a Cloudflare API Token with DNS edit permission
- an email address

> Note: the script disables SELinux and the firewall. Make sure that is acceptable for your server before running it.

### Build and run the server locally

You need a JDK (the project uses Kotlin 2.4 / Ktor 3.5):

```sh
cd EFHServer
./gradlew buildFatJar
java -jar build/libs/EFHServer-all.jar
```

It listens on port `80` by default (see `application.yaml`) and serves both the backend APIs and the whole site under `static/`.

### Client

```sh
cd efh_connectivity_test
flutter run
```

## Server API

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/clash/{passwd}` | Returns the Clash subscription (`clash.yaml`) for the password |
| `GET` | `/surge/{passwd}` | Returns the Surge subscription (`shadowrocket.conf`) for the password |
| `GET` | `/get-config/{passwd}/Woznes-EFH-Clash` | Clash subscription for one-click import |
| `GET` | `/get-config/{passwd}/Woznes-EFH-Surge` | Surge subscription for one-click import |
| `GET` | `/status/nodes?test=true\|false` | Node status; `test=true` probes via mihomo, `false` returns node names only |
| `GET` | `/top-domains/{top}` | Serves Cloudflare Radar Top domains (one per line) |

Pages and assets are served by `staticResources("/", "static")`; `404` / `500` use `static/404.html` and `static/50x.html`.

`/top-domains/{top}` accepts `top` values: `200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000`.

## Configuration

The server is configured through environment variables (systemd: prefer `EnvironmentFile`):

| Variable | Default | Description |
| --- | --- | --- |
| `CF_Token` | none | Cloudflare API Token. Used as a Radar API fallback when the public endpoint returns 403 |
| `MIHOMO_CONTROLLER` | `http://127.0.0.1:9091` | mihomo external controller address |
| `MIHOMO_TEST_URL` | `http://www.gstatic.com/generate_204` | Probe URL for latency tests |

Redis connects to `redis://127.0.0.1:6379` by default (`Redis.kt`).

> A systemd service does not load `~/.bashrc`; environment variables must be provided through an `EnvironmentFile`. See [DEPLOY.md](DEPLOY.md) for details.

## Deployment

Package a fat JAR → publish a GitHub Release → replace and restart on the server, wrapped up in `deploy.sh`:

```sh
./deploy.sh                # auto-increment the patch version
./deploy.sh v0.1.0         # specify a version
./deploy.sh v0.1.0 --dirty # allow uncommitted changes in the working tree
```

Prerequisites: `gh` is logged in (or `GH_TOKEN` is set) and passwordless `ssh opc@vpn.woznes.com` works from your machine. Full steps are in [DEPLOY.md](DEPLOY.md).

## Frontend Notes

The static site lives in `EFHServer/src/main/resources/static/`:

- `js/i18n.js` — lightweight i18n; loads `/i18n/{zh-CN,en}.json` and fills elements by their `data-i18n*` attributes; a manually chosen language takes precedence over the browser language.
- `js/theme.js` — appearance switching (dark / light / follow system); the preference is stored in `localStorage` (`efh.theme`).
- `css/theme.css` — dark theme overrides.

## Disclaimer

This project is for learning and researching networking technology only. Please comply with the laws and regulations of your region. Any consequences arising from use of this service are borne by the user.

## License

[MIT](LICENSE.txt) © 2025 Nick Ji

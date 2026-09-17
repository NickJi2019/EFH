# EFH · Escape From HDSB Project

[English](README.MD)

[![GitHub stars](https://img.shields.io/github/stars/NickJi2019/EFH?style=social)](https://github.com/NickJi2019/EFH)
[![License](https://img.shields.io/github/license/NickJi2019/EFH)](LICENSE.txt)
[![Release](https://img.shields.io/github/v/release/NickJi2019/EFH?include_prereleases&label=release)](https://github.com/NickJi2019/EFH/releases)

> 让所有人获得互联网访问自由。

EFH（Escape From HDSB Project）是一个网络加速与访问自由项目：提供基于 **Trojan** 协议的代理节点与订阅下发，并附带一组顺手的小工具（服务状态、网站屏蔽检测等）。前端坚持零依赖、加载飞快。

- 站点：<https://vpn.woznes.com>
- 仓库：<https://github.com/NickJi2019/EFH>
- 许可：[MIT](LICENSE.txt)

## 功能特性

- **一键导入配置** —— 按密码哈希生成订阅链接，支持 Clash / Shadowrocket / Surge，附带手动复制。
- **服务状态** —— 浏览器侧直连延迟 + 服务器侧（mihomo）节点可达性，双重检测。
- **网站屏蔽检测** —— 基于 Cloudflare Radar Top 域名列表，在本地网络探测网站是否被 HDSB 拦截。
- **外观与语言** —— 深色 / 浅色 / 跟随系统，简体中文 / English，均可在导航栏切换。

## 技术栈

| 层 | 技术 |
| --- | --- |
| 服务端 | Kotlin + Ktor（Netty）、Redisson（Redis） |
| 节点 | trojan-go + nginx，acme.sh 自动签发与续签证书 |
| 前端 | 原生 HTML / CSS / JavaScript（Bootstrap 4 主题），自研轻量 i18n 与主题脚本 |
| 客户端 | Flutter（`efh_connectivity_test`） |
| 部署 | Fat JAR + systemd |

## 仓库结构

```
EFH/
├── EFHServer/                  Ktor 服务端（同时托管静态站点）
│   ├── src/main/kotlin/        Application / Routing / Status / TopDomains / Redis
│   └── src/main/resources/
│       ├── static/             前端静态站点（HTML / CSS / JS）
│       ├── clash.yaml          订阅模板
│       ├── shadowrocket.conf   订阅模板
│       └── application.yaml    Ktor 配置（端口 80）
├── EFHServerSetup/             trojan-go 服务端一键安装脚本
│   ├── install.sh
│   └── config.json
├── efh_connectivity_test/      Flutter 客户端
├── deploy.sh                   一键部署脚本
├── DEPLOY.md                   部署流程说明
└── LICENSE.txt                 MIT
```

## 快速开始

### 一键安装节点（trojan-go 服务端）

在你的服务器上执行：

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/NickJi2019/EFH/refs/heads/main/EFHServerSetup/install.sh)"
```

脚本会安装依赖、用 acme.sh 签发证书、配置 nginx 与 trojan-go。运行前请准备好：

- root 权限与可用的网络
- 已托管在 Cloudflare 的域名
- 具备 DNS 编辑权限的 Cloudflare API Token
- 一个邮箱地址

> 注意：脚本会关闭 SELinux 与防火墙，请确认服务器用途后再执行。

### 本地构建并运行服务端

需要 JDK（项目使用 Kotlin 2.4 / Ktor 3.5）：

```sh
cd EFHServer
./gradlew buildFatJar
java -jar build/libs/EFHServer-all.jar
```

默认监听 `80` 端口（见 `application.yaml`）；启动后会同时提供后端接口与 `static/` 下的整站页面。

### 客户端

```sh
cd efh_connectivity_test
flutter run
```

## 服务端接口

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `GET` | `/clash/{passwd}` | 按密码返回 Clash 订阅（`clash.yaml`） |
| `GET` | `/surge/{passwd}` | 按密码返回 Surge 订阅（`shadowrocket.conf`） |
| `GET` | `/get-config/{passwd}/Woznes-EFH-Clash` | 一键导入用 Clash 订阅 |
| `GET` | `/get-config/{passwd}/Woznes-EFH-Surge` | 一键导入用 Surge 订阅 |
| `GET` | `/status/nodes?test=true\|false` | 节点状态；`test=true` 走 mihomo 测速，`false` 仅返回节点名 |
| `GET` | `/top-domains/{top}` | 下发 Cloudflare Radar Top 域名（每行一个域名） |

页面与资源由 `staticResources("/", "static")` 提供；`404` / `500` 使用 `static/404.html`、`static/50x.html`。

`/top-domains/{top}` 支持的 `top` 取值：`200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000`。

## 配置

服务端通过环境变量配置（systemd 建议使用 `EnvironmentFile`）：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `CF_Token` | 无 | Cloudflare API Token。Radar 公开端点返回 403 时，用它走 Radar API 回退 |
| `MIHOMO_CONTROLLER` | `http://127.0.0.1:9091` | mihomo 外部控制器地址 |
| `MIHOMO_TEST_URL` | `http://www.gstatic.com/generate_204` | 测速探测地址 |

Redis 默认连接 `redis://127.0.0.1:6379`（`Redis.kt`）。

> systemd 服务不会加载 `~/.bashrc`，环境变量需通过 `EnvironmentFile` 提供，详见 [DEPLOY.md](DEPLOY.md)。

## 部署

打包 fat JAR → 发布 GitHub Release → 服务器替换并重启，已封装为 `deploy.sh`：

```sh
./deploy.sh                # 自动递增 patch 版本号
./deploy.sh v0.1.0         # 指定版本号
./deploy.sh v0.1.0 --dirty # 允许工作区有未提交改动
```

前置：`gh` 已登录（或设置 `GH_TOKEN`），且本机可免密 `ssh opc@vpn.woznes.com`。完整步骤见 [DEPLOY.md](DEPLOY.md)。

## 前端说明

静态站点位于 `EFHServer/src/main/resources/static/`：

- `js/i18n.js` —— 轻量 i18n，读取 `/i18n/{zh-CN,en}.json`，按 `data-i18n*` 属性回填；手动选择的语言优先于浏览器语言。
- `js/theme.js` —— 外观切换（深色 / 浅色 / 跟随系统），偏好存于 `localStorage`（`efh.theme`）。
- `css/theme.css` —— 深色主题覆盖样式。

## 免责声明

本项目仅用于学习与研究网络技术，请遵守你所在地区的法律法规。因使用本服务而产生的一切后果，由使用者自行承担。

## License

[MIT](LICENSE.txt) © 2025 Nick Ji

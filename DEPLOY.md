# EFHServer 部署流程

将 EFHServer 打包为 fat jar，通过 GitHub Release 分发，并在服务器上替换后重启服务。

- 仓库：`https://github.com/NickJi2019/EFH`
- 服务器：`opc@vpn.woznes.com`
- 产物：`EFHServer/build/libs/EFHServer-all.jar`
- 服务：`EFHServer`

## 一键部署脚本

`deploy.sh` 封装了下面的全部步骤（推送 → 打包 → 发布 Release → 服务器替换并重启 → 验证），并会在首次部署时自动配置服务器的 `CF_Token`：

```sh
./deploy.sh                # 自动递增 patch 版本号（基于最新 tag）
./deploy.sh v0.1.0         # 指定版本号
./deploy.sh v0.1.0 --dirty # 允许工作区有未提交改动
```

前置：已安装并登录 `gh`（或设置 `GH_TOKEN`），且本机能免密 `ssh opc@vpn.woznes.com`。

## 服务器前置配置（仅首次）

`/top-domains/{top}` 需要 Cloudflare `CF_Token`：服务器 IP 请求 Radar 公开 attachment 端点会返回 403，需用 token 走 Radar API 回退。

注意：systemd 服务不加载 `~/.bashrc`，写在 bashrc 里的 `export CF_Token` **不会生效**。必须通过 systemd `EnvironmentFile` 提供：

```sh
# 取出安装时使用过的同一个 token（acme.sh 保存的）
TOKEN=$(sed -n "s/^SAVED_CF_Token='\(.*\)'/\1/p" ~/.acme.sh/account.conf)

# 写入环境文件并设置权限
printf 'CF_Token=%s\n' "$TOKEN" | sudo tee /etc/EFHServer.env >/dev/null
sudo chmod 600 /etc/EFHServer.env

# 在 service 中加入 EnvironmentFile（仅当尚未存在）
grep -q 'EnvironmentFile=/etc/EFHServer.env' /etc/systemd/system/EFHServer.service || \
  sudo sed -i '/^\[Service\]/a EnvironmentFile=/etc/EFHServer.env' /etc/systemd/system/EFHServer.service

sudo systemctl daemon-reload
sudo service EFHServer restart

# 验证
curl -sS -o /dev/null -w '%{http_code}\n' https://vpn.woznes.com/top-domains/200
```

## 步骤

### 1. 提交并推送代码

```sh
git add .
git commit -m "your message"
git push
```

### 2. 打包 jar

```sh
cd EFHServer
./gradlew buildFatJar
```

产物位于 `EFHServer/build/libs/EFHServer-all.jar`。

### 3. 上传到 GitHub Release

设置版本号并创建 release（版本号用新的 tag，例如 `v0.0.5`）：

```sh
VERSION=v0.0.6

gh release create "$VERSION" \
  EFHServer/build/libs/EFHServer-all.jar \
  --title "$VERSION" \
  --notes "EFHServer $VERSION" \
  --prerelease
```

如果 release 已存在，改用上传附件：

```sh
gh release upload "$VERSION" EFHServer/build/libs/EFHServer-all.jar --clobber
gh release edit "$VERSION" --prerelease
```

### 4. 登录服务器并替换 jar

```sh
ssh opc@vpn.woznes.com

VERSION=v0.0.6
rm -f EFHServer-all.jar
curl -fL -o EFHServer-all.jar \
  "https://github.com/NickJi2019/EFH/releases/download/$VERSION/EFHServer-all.jar"
```

> jar 所在目录需与服务 `ExecStart` 中配置的路径一致（默认为当前用户目录）。

### 5. 重启服务

```sh
sudo service EFHServer restart
sudo service EFHServer status
```

## 一次性命令（本地执行）

```sh
cd EFHServer && ./gradlew buildFatJar
VERSION=v0.0.6
gh release create "$VERSION" build/libs/EFHServer-all.jar --title "$VERSION" --notes "EFHServer $VERSION" --prerelease
ssh opc@vpn.woznes.com "rm -f EFHServer-all.jar && curl -fL -o EFHServer-all.jar https://github.com/NickJi2019/EFH/releases/download/$VERSION/EFHServer-all.jar && sudo service EFHServer restart"
```

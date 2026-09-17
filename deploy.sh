#!/usr/bin/env bash
# 根据 DEPLOY.md 的一键部署脚本：
#   1. git push
#   2. 打包 fat jar
#   3. 上传到 GitHub Release
#   4. ssh 到服务器替换 jar 并重启服务
#   5. 验证
#
# 用法:
#   ./deploy.sh                # 自动递增 patch 版本号 (基于最新 tag)
#   ./deploy.sh v0.1.0         # 指定版本号
#   ./deploy.sh v0.1.0 --dirty # 允许工作区有未提交改动
set -euo pipefail

REPO="NickJi2019/EFH"
SERVER="opc@vpn.woznes.com"
SITE="https://vpn.woznes.com"
JAR="EFHServer/build/libs/EFHServer-all.jar"
REMOTE_JAR="EFHServer-all.jar"
SERVICE="EFHServer"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

BLUE=$'\033[0;34m'; GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; NC=$'\033[0m'
step() { printf '\n%s==> %s%s\n' "$BLUE" "$*" "$NC"; }
ok()   { printf '%s%s%s\n' "$GREEN" "$*" "$NC"; }
die()  { printf '%sERROR: %s%s\n' "$RED" "$*" "$NC" >&2; exit 1; }

VERSION=""
ALLOW_DIRTY=0
for arg in "$@"; do
  case "$arg" in
    --dirty) ALLOW_DIRTY=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    -* ) die "未知参数: $arg" ;;
    * ) VERSION="$arg" ;;
  esac
done

# ---------------------------------------------------------------- 版本号
git fetch --tags --quiet 2>/dev/null || true
if [[ -z "$VERSION" ]]; then
  latest="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n1)"
  if [[ -z "$latest" ]]; then
    VERSION="v0.0.1"
  else
    IFS=. read -r major minor patch <<<"${latest#v}"
    VERSION="v${major}.${minor}.$((patch + 1))"
  fi
fi
[[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "版本号格式应为 vX.Y.Z，收到: $VERSION"
step "版本号: $VERSION"

# ---------------------------------------------------------------- 环境检查
command -v gh   >/dev/null 2>&1 || die "未找到 gh，请先安装 GitHub CLI"
command -v ssh  >/dev/null 2>&1 || die "未找到 ssh"

if ! gh auth status >/dev/null 2>&1; then
  if [[ -z "${GH_TOKEN:-}" ]]; then
    tok="$(printf 'protocol=https\nhost=github.com\n\n' | git credential-osxkeychain get 2>/dev/null | sed -n 's/^password=//p' || true)"
    [[ -n "$tok" ]] && export GH_TOKEN="$tok"
  fi
fi
gh auth status >/dev/null 2>&1 || die "gh 未登录，请先 'gh auth login' 或设置 GH_TOKEN"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "当前目录不是 git 仓库"

# ---------------------------------------------------------------- 1. git push
if [[ "$ALLOW_DIRTY" -eq 0 ]] && [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  git status --short
  die "工作区有未提交的改动；请先提交，或加 --dirty 强制部署当前代码"
fi
step "1/5 推送到远端"
#git pull --rebase
git push
ok "已推送"

# ---------------------------------------------------------------- 2. 打包
step "2/5 打包 fat jar"
( cd EFHServer && ./gradlew buildFatJar )
[[ -f "$JAR" ]] || die "未找到产物: $JAR"
ok "产物: $JAR ($(du -h "$JAR" | cut -f1))"

# ---------------------------------------------------------------- 3. 发布
step "3/5 上传 GitHub Release ${VERSION}（pre-release）"
if gh release view "$VERSION" -R "$REPO" >/dev/null 2>&1; then
  gh release upload "$VERSION" "$JAR" -R "$REPO" --clobber
  gh release edit "$VERSION" -R "$REPO" --prerelease
else
  gh release create "$VERSION" "$JAR" -R "$REPO" \
    --title "$VERSION" --notes "EFHServer $VERSION" --prerelease
fi
ok "Release: https://github.com/$REPO/releases/tag/$VERSION"

# ---------------------------------------------------------------- 4. 部署
step "4/5 服务器替换 jar 并重启"
ssh -o BatchMode=yes "$SERVER" "bash -s" <<REMOTE
set -e

# 首次部署：确保服务能拿到 CF_Token（systemd 不读 ~/.bashrc）
if ! grep -q 'EnvironmentFile=/etc/EFHServer.env' /etc/systemd/system/$SERVICE.service 2>/dev/null; then
  echo "配置 CF_Token 环境文件..."
  TOKEN=\$(sed -n "s/^SAVED_CF_Token='\(.*\)'/\1/p" ~/.acme.sh/account.conf)
  if [ -n "\$TOKEN" ]; then
    printf 'CF_Token=%s\n' "\$TOKEN" | sudo tee /etc/EFHServer.env >/dev/null
    sudo chmod 600 /etc/EFHServer.env
    sudo sed -i '/^\[Service\]/a EnvironmentFile=/etc/EFHServer.env' /etc/systemd/system/$SERVICE.service
    sudo systemctl daemon-reload
  else
    echo "警告: 未找到 token，如 /top-domains 报 502 请手动配置 /etc/EFHServer.env"
  fi
fi

cd ~
rm -f $REMOTE_JAR
curl -fsSL -o $REMOTE_JAR https://github.com/$REPO/releases/download/$VERSION/$REMOTE_JAR
ls -la $REMOTE_JAR
sudo service $SERVICE restart
sleep 3
sudo systemctl is-active $SERVICE
REMOTE
ok "已重启"

# ---------------------------------------------------------------- 5. 验证
step "5/5 验证"
code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$SITE/top-domains/200" || true)"
[[ "$code" == "200" ]] || die "接口验证失败: $SITE/top-domains/200 -> HTTP $code"
ok "接口正常: $SITE/top-domains/200 -> HTTP 200"
ok "部署完成: $VERSION"

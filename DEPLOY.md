# EFHServer 部署流程

将 EFHServer 打包为 fat jar，通过 GitHub Release 分发，并在服务器上替换后重启服务。

- 仓库：`https://github.com/NickJi2019/EFH`
- 服务器：`opc@vpn.woznes.com`
- 产物：`EFHServer/build/libs/EFHServer-all.jar`
- 服务：`EFHServer`

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
VERSION=v0.0.5

gh release create "$VERSION" \
  EFHServer/build/libs/EFHServer-all.jar \
  --title "$VERSION" \
  --notes "EFHServer $VERSION"
```

如果 release 已存在，改用上传附件：

```sh
gh release upload "$VERSION" EFHServer/build/libs/EFHServer-all.jar --clobber
```

### 4. 登录服务器并替换 jar

```sh
ssh opc@vpn.woznes.com

VERSION=v0.0.5
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
VERSION=v0.0.5
gh release create "$VERSION" build/libs/EFHServer-all.jar --title "$VERSION" --notes "EFHServer $VERSION"
ssh opc@vpn.woznes.com "rm -f EFHServer-all.jar && curl -fL -o EFHServer-all.jar https://github.com/NickJi2019/EFH/releases/download/$VERSION/EFHServer-all.jar && sudo service EFHServer restart"
```

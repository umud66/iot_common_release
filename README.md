# SeaControll Release

这个仓库只负责 **编译与发布后端服务**，不保存业务源码。

当前自动构建内容：

- `seacontroll-http`
- `seacontroll-mqtt`

Pages 托管在 Cloudflare Pages，不参与本仓库构建。设备固件也不参与本仓库构建。

构建完成后会自动发布到 GitHub Release。

## 仓库来源

默认源码仓库：

| 模块 | 仓库 |
| --- | --- |
| backend | `umud66/iot_common_server` |

本仓库只拉取并编译 `backend`。

## 配置文件

HTTP 和 MQTT 服务都支持 YAML 配置文件：

```bash
./seacontroll-http -config ./seacontroll-http.yaml
./seacontroll-mqtt -config ./seacontroll-mqtt.yaml
```

也可以用环境变量指定：

```bash
SEACONTROLL_HTTP_CONFIG=./seacontroll-http.yaml ./seacontroll-http
SEACONTROLL_MQTT_CONFIG=./seacontroll-mqtt.yaml ./seacontroll-mqtt
```

如果没有环境变量，也没有配置文件，服务会在运行目录生成默认配置文件并退出，用户修改后重新启动即可。

示例配置在：

- `templates/seacontroll-http.yaml`
- `templates/seacontroll-mqtt.yaml`

## 第一次创建 GitHub 仓库

1. 在 GitHub 新建仓库，仓库名填写：`release`
2. 把本目录内容推送到这个仓库。
3. 如果源码仓库是私有仓库，需要在 `release` 仓库中添加 Secret：
   - `SOURCE_TOKEN`
   - 值填写一个能读取源码仓库的 GitHub Personal Access Token。
4. 如果源码仓库是公开仓库，可以不配置 `SOURCE_TOKEN`。

## 可选仓库变量

如果后续仓库名变化，可以在 GitHub 仓库：

`Settings -> Secrets and variables -> Actions -> Variables`

添加：

| 变量 | 默认值 |
| --- | --- |
| `BACKEND_REPO` | `umud66/iot_common_server` |

变量值只写 `owner/repo`，不要写完整 URL。

## 手动发布

进入 GitHub：

`Actions -> Build SeaControll Release -> Run workflow`

填写：

- `version`：例如 `v0.1.0`
- `backend_ref`：后端分支、标签或 commit，例如 `master`
- `prerelease`：测试版本选 `true`，正式版本选 `false`

执行成功后会生成 Release，包含：

- `seacontroll-http-v0.1.0-linux-amd64.tar.gz`
- `seacontroll-http-v0.1.0-linux-arm64.tar.gz`
- `seacontroll-http-v0.1.0-darwin-arm64.tar.gz`
- `seacontroll-mqtt-v0.1.0-linux-amd64.tar.gz`
- `seacontroll-mqtt-v0.1.0-linux-arm64.tar.gz`
- `seacontroll-mqtt-v0.1.0-darwin-arm64.tar.gz`
- `SHA256SUMS`

每个压缩包只包含一个平台、一个服务的二进制和对应示例配置。

## 容器镜像

手动运行 Release workflow 时，`publish_images` 默认开启。开启后会推送到 GitHub Container Registry：

- `ghcr.io/<你的GitHub用户名>/seacontroll-http:<version>`
- `ghcr.io/<你的GitHub用户名>/seacontroll-mqtt:<version>`
- `ghcr.io/<你的GitHub用户名>/seacontroll-postgres:<version>`

数据库镜像基于官方 `postgres:16-alpine`，只额外内置后端仓库里的 `migrations/*.sql` 初始化脚本。

> 注意：PostgreSQL 已有数据卷时不会重复执行初始化 SQL，这是 PostgreSQL 官方镜像的正常行为。

### 使用 Compose 部署

Release 会附带：

- `docker-compose.release.example.yml`
- `docker-compose.postgres-only.yml`
- `seacontroll-http.yaml`
- `seacontroll-http.local-binary.yaml`
- `seacontroll-mqtt.yaml`

建议部署目录：

```text
seacontroll-deploy/
  docker-compose.yml
  config/
    seacontroll-http.yaml
    seacontroll-mqtt.yaml
```

把 `docker-compose.release.example.yml` 改名为 `docker-compose.yml`，并修改里面的镜像地址：

```bash
SEACONTROLL_HTTP_IMAGE=ghcr.io/<你的GitHub用户名>/seacontroll-http:v0.1.0 \
SEACONTROLL_MQTT_IMAGE=ghcr.io/<你的GitHub用户名>/seacontroll-mqtt:v0.1.0 \
SEACONTROLL_POSTGRES_IMAGE=ghcr.io/<你的GitHub用户名>/seacontroll-postgres:v0.1.0 \
docker compose up -d
```

如果 GHCR 镜像不是公开的，需要先登录：

```bash
docker login ghcr.io
```

### PostgreSQL 用容器，HTTP/MQTT 用二进制运行

适合私服部署：数据库交给容器持久化，HTTP/MQTT 下载 Release 里的二进制直接运行。

部署目录示例：

```text
seacontroll-deploy/
  docker-compose.yml
  config/
    seacontroll-http.yaml
    seacontroll-mqtt.yaml
  bin/
    seacontroll-http
    seacontroll-mqtt
```

操作步骤：

```bash
# 1. 下载 docker-compose.postgres-only.yml，改名为 docker-compose.yml
# 2. 使用官方 PostgreSQL 镜像启动数据库
POSTGRES_PASSWORD=请改成强密码 \
docker compose up -d

# 3. 下载 seacontroll-http-<version>-linux-<arch>.tar.gz 并解压
# 4. 复制 seacontroll-http.local-binary.yaml 为 config/seacontroll-http.yaml
# 5. 修改 database.url、publicHost、deviceBrokerUrl、internalToken
./bin/seacontroll-http -config ./config/seacontroll-http.yaml
```

如果只先启动 HTTP，不启动 MQTT，页面登录和设备管理可以先用；设备下发命令需要 MQTT 网关可用。

## 本地测试

本地只测试脚本语法：

```bash
bash -n scripts/checkout-sources.sh
bash -n scripts/build-backend.sh
```

如果要本地完整构建：

```bash
./scripts/checkout-sources.sh
VERSION=v0.1.0 ./scripts/build-backend.sh
```

## 注意

- 不要把 `.env`、Token、数据库密码提交到仓库。
- Release 产物可以公开，但源码权限仍由各源码仓库控制。
- 如果源码仓库是私有仓库，`SOURCE_TOKEN` 必须具备读取权限。

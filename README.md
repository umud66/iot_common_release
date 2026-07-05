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

- `seacontroll-backend-v0.1.0.tar.gz`
- `SHA256SUMS`

压缩包内包含：

- `seacontroll-http-linux-amd64`
- `seacontroll-http-linux-arm64`
- `seacontroll-http-darwin-arm64`
- `seacontroll-mqtt-linux-amd64`
- `seacontroll-mqtt-linux-arm64`
- `seacontroll-mqtt-darwin-arm64`

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

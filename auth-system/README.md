# 内网鉴权系统第一阶段部署包

本目录用于单机 Docker 部署 Keycloak + oauth2-proxy + Nginx，第一阶段优先保护 OpenClaw。

默认访问链路：

1. 用户访问 `OPENCLAW_BASE_URL`。
2. Nginx 通过 `auth_request` 调用 oauth2-proxy。
3. oauth2-proxy 跳转到 `AUTH_BASE_URL` 的 Keycloak Realm 登录。
4. 登录且属于 `/openclaw-users` 后，Nginx 代理到 OpenClaw 上游。

## 目录结构

- `docker-compose.yml`：PostgreSQL、Keycloak、oauth2-proxy、Nginx 编排。
- `.env.example`：部署变量模板，真实 `.env` 不入库。
- `nginx/templates/default.conf.template`：Nginx 域名、鉴权、反代、WebSocket 和日志配置。
- `keycloak/company-realm.template.json`：Realm、Client、Group 和测试用户模板。
- `keycloak/realm-export/`：初始化脚本生成的 Keycloak 导入目录，真实 JSON 不入库。
- `scripts/`：初始化、证书生成、配置校验和端点验收脚本。
- `certs/`：放置 `openclaw.crt` 和 `openclaw.key`，证书私钥不入库。

## 端口规避

默认配置使用宿主机 `18081/18443`，避免覆盖服务器已有的 80/443 Nginx：

```text
HTTP_PORT=18081
HTTPS_PORT=18443
AUTH_BASE_URL=https://auth.company.local:18443
AUTH_ADMIN_BASE_URL=https://auth-admin.company.local:18443
OPENCLAW_BASE_URL=https://openclaw.company.local:18443
```

如果部署机 80/443 空闲，可改回：

```text
HTTP_PORT=80
HTTPS_PORT=443
AUTH_BASE_URL=https://auth.company.local
AUTH_ADMIN_BASE_URL=https://auth-admin.company.local
OPENCLAW_BASE_URL=https://openclaw.company.local
```

注意：OIDC 的 issuer、callback、Keycloak hostname 必须和浏览器实际访问 URL 完全一致；非标准端口时 `*_BASE_URL` 必须带端口。`OAUTH2_PROXY_COOKIE_SECRET` 使用 32 字符随机字符串，例如 `openssl rand -hex 16`。

## 前置条件

- Docker Engine / Docker Desktop，支持 `docker compose`。
- 内网 DNS 或 hosts 指向部署机：
  - `auth.company.local`
  - `auth-admin.company.local`
  - `openclaw.company.local`
- 可用 HTTPS 证书，证书 SAN 至少包含上述三个域名。
- OpenClaw 已运行，并且 Nginx 容器能访问其上游地址。

## 初始化

在本目录执行：

```powershell
.\scripts\init-env.ps1 -Force
```

Ubuntu/Linux：

```bash
sh scripts/init-env.sh --force
```

然后编辑：

- `.env`：确认域名、端口、`OPENCLAW_UPSTREAM`、管理员网段和密钥。
- `keycloak\realm-export\company-realm.json`：把 `CHANGE_ME_TEST_USER_PASSWORD` 替换成临时测试密码，或删除 `users` 数组后启动再手工创建用户。

如果修改了 `OPENCLAW_BASE_URL`，需要重新执行 `.\scripts\init-env.ps1 -Force`，或同步修改 `keycloak/realm-export/company-realm.json` 中的 redirect URI。

## 证书

生产或正式内网验证建议使用公司内部 CA 签发证书，并保存为：

```text
certs/openclaw.crt
certs/openclaw.key
```

短期实验可生成自签证书：

```powershell
.\scripts\generate-self-signed-cert.ps1
```

或在 Linux 上：

```bash
sh scripts/generate-self-signed-cert.sh
```

浏览器和 oauth2-proxy 需要信任该证书链。实验环境可临时设置 `OAUTH2_PROXY_SSL_INSECURE_SKIP_VERIFY=true`，正式环境保持 `false`。

## 启动

先校验配置：

```powershell
.\scripts\validate.ps1
```

启动服务：

```powershell
docker compose up -d
docker compose ps
```

查看日志：

```powershell
docker compose logs -f keycloak
docker compose logs -f oauth2-proxy
docker compose logs -f nginx
```

## OpenClaw 上游

默认 `.env`：

```text
OPENCLAW_UPSTREAM=http://host.docker.internal:18789
```

如果 OpenClaw 在宿主机 `127.0.0.1:18789`，Linux Docker 通过 `host-gateway` 可用上述默认值。

安全边界要求：普通用户网段不能直接访问 OpenClaw 真实端口，只能访问 `OPENCLAW_BASE_URL`。

## 验收

使用默认高端口和自签证书时：

```powershell
.\scripts\verify-endpoints.ps1 -OpenClawUrl https://openclaw.company.local:18443 -AuthUrl https://auth.company.local:18443 -SkipCertificateCheck
```

人工验收项：

- 未登录访问 `OPENCLAW_BASE_URL`，跳转 Keycloak。
- `openclaw.user` 或其他 `/openclaw-users` 成员登录后进入 OpenClaw。
- 非 `/openclaw-users` 用户登录后被拒绝。
- 刷新页面不重复登录。
- OpenClaw WebSocket 正常连接并保持。
- 伪造 `X-Auth-Request-Email` 请求头不会覆盖真实登录用户。
- 普通用户不能访问 OpenClaw 后端端口、Keycloak 9000、PostgreSQL 5432。

## 常见问题

OIDC issuer 或 redirect URI 报错：

- 检查 `.env` 的 `*_BASE_URL` 是否与 `keycloak/realm-export/company-realm.json` 中的 redirect URI 一致。
- 检查 `AUTH_DOMAIN` 是否能从浏览器和容器内访问。

用户组授权不生效：

- 确认用户属于 `/openclaw-users`。
- 确认 Keycloak Client 中存在 `groups` mapper，且 `full.path=true`。
- 检查 oauth2-proxy 日志中的 group claim。

WebSocket 失败：

- 检查 OpenClaw 上游地址是否正确。
- 检查 Nginx 日志中是否有 502/504。
- 确认 `proxy_http_version 1.1`、`Upgrade`、`Connection` 配置未被改动。

管理端访问限制：

- `auth-admin.company.local` 默认只允许 `.env` 中 `ADMIN_ALLOWED_CIDR` 指定的网段。
- 不要把 Keycloak 9000 健康检查端口暴露给普通用户。

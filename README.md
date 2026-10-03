# EasyTier 云端节点部署

你没有服务器也能建节点，因为 EasyTier 支持 **无 TUN 模式（`--no-tun`）**：
不创建虚拟网卡、不需要 root / `NET_ADMIN` / `/dev/net/tun`，只做「打洞协调 + 流量中继」，
因此可以跑在免费容器平台里。

- 云端节点：公共共享节点模式（不带 `--network-name`/`--network-secret`），谁都能带身份接入
- 客户端：各自带相同的网络名 + 网络密钥，先尝试 P2P 直连，打洞失败才走云端中继

---

## 路线 A：Koyeb 免费档（0 元，用你的 GitHub 账号）

### 1. 把这个目录推到 GitHub

仓库已经在本地 `git init` 并提交好了，你只需要给一个 token：

1. 打开 https://github.com/settings/tokens → **Generate new token (classic)**
2. 勾选 `repo`（全部）和 `workflow`，有效期随意
3. 复制生成的 `ghp_...`，然后执行：

```bash
cd easytier-cloud-node
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
bash push-to-github.sh
```

脚本会自动建仓库、推代码，最后打印仓库地址。

> 注意：GitHub **早已不支持用账号密码推代码或调 API**（2021 年起全面改为 token），
> 所以只能用 Personal Access Token，密码给我也没用。

仓库里已经有 `Dockerfile` 和 `entrypoint.sh`，Koyeb 会自动用 Dockerfile 构建。

### 2. 在 Koyeb 上创建服务

1. 打开 koyeb.com，**用 GitHub 登录**（免费档）
2. `Create Web Service` → 部署方式选 **GitHub** → 授权 Koyeb 的 GitHub App → 选中刚推的仓库
3. 构建方式保持 **Dockerfile**
4. Instance 类型选 **Free / Nano**
5. Region 选 **Singapore**（离国内最近，日本/新加坡都行）
6. **Ports**：Port 填 `8000`，协议 `HTTP`
7. **Health checks**：协议改成 **TCP**（不要选 HTTP，EasyTier 不会返回 200，会被判定 unhealthy 反复重启）
8. 环境变量（Settings → Environment），强烈建议配第 1 个：

| 变量 | 值 | 说明 |
|---|---|---|
| `ET_RELAY_NETWORK_WHITELIST` | `hangzhou-office` | 只允许给这个名字的网络做中继，防止被陌生人白嫖带宽 |
| `ET_HOSTNAME` | `et-cloud` | 节点显示名，随意 |
| `PORT` | `8000` | 与上面填的端口保持一致 |

9. 点 **Deploy**

部署完成后会得到一个域名，形如 `https://your-app-org.koyeb.app`。

### 3. 客户端接入地址

把 `https://` 换成 `wss://`，**不带端口**（走 443）：

```
wss://your-app-org.koyeb.app
```

### 4. 保活（可选但建议）

免费档空闲可能缩容到 0。仓库里的 `.github/workflows/keepalive.yml` 每 10 分钟打一次请求保活。

在 GitHub 仓库 → Settings → Secrets and variables → Actions → New repository secret：

- Name: `NODE_URL`
- Value: `your-app-org.koyeb.app`（不要带 https://）

> 就算真的缩到 0 也不用慌，下一次连入会自动唤醒，只是首次连接慢 1~2 秒。

---

## 路线 B：便宜 VPS 自建（推荐做主力节点）

国内轻量 2核2G 常年活动价 **¥38~99/年**，延迟 10~30ms，比免费容器稳得多。
买完（腾讯云 / 阿里云 / 华为云 / 京东云都行，选国内节点）后：

```bash
curl -fsSL https://raw.githubusercontent.com/<你的用户名>/easytier-cloud-node/main/install-vps.sh | sudo bash
# 或者先把仓库 clone 下来再跑：sudo bash install-vps.sh
```

脚本会装上 `easytier-core` + systemd 服务 + 防火墙放行。
**云厂商控制台的安全组也要放行：11010 TCP/UDP、11011 TCP、11012 TCP。**

接入地址：`tcp://<公网IP>:11010`

> 两条路可以并存：EasyTier 支持同时填多个 peer，自动选路。
> 国内 VPS 当主力，Koyeb 当备份，挂了自动切。

---

## 验证节点活着

```bash
# 云端（Koyeb 看日志即可）
easytier-cli node
easytier-cli peer

# 客户端上
ping <另一台机器的虚拟 IP>
```

---

## 重要提醒：别和物理网段撞车

你们物理内网是 **10.126.126.0/24**，而 EasyTier 的 DHCP 默认网段正好也是 10.126.126.0/24。
**必须手动指定另一个网段**，否则路由会打架。建议用 `10.144.144.0/24`，见 `windows-client.md`。

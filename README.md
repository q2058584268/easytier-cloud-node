# EasyTier 云端节点部署

你没有服务器也能建节点，因为 EasyTier 支持 **无 TUN 模式（`--no-tun`）**：
不创建虚拟网卡、不需要 root / `NET_ADMIN` / `/dev/net/tun`，只做「打洞协调 + 流量中继」，
因此可以跑在免费容器平台里。

- 云端节点：公共共享节点模式（不带 `--network-name`/`--network-secret`），谁都能带身份接入
- 客户端：各自带相同的网络名 + 网络密钥，先尝试 P2P 直连，打洞失败才走云端中继

## 当前进度

代码已推送到 **https://github.com/q2058584268/easytier-cloud-node**（GitHub Actions 已开启）。
剩下最后一步：在 Render 上点一下部署，拿到域名。

## ⚠️ 2026-10 现状：免费托管集体关门

| 平台 | 现状 |
|---|---|
| **Koyeb** | ❌ 2026-02 被 Mistral 收购，**免费 Starter 档对新用户关闭**，新账号最低 Pro $29/月 |
| **Render** | ✅ 免费档仍在，但**每月仅 5GB 流量**，空闲 15 分钟休眠 |
| **Fly.io** | ❌ 免费额度 2024 年已取消 |
| **Northflank** | ⚠️ 免费档不休眠，但注册要信用卡验证 |
| **Oracle Cloud** | ⚠️ 永久免费是真 VPS，但注册要信用卡 + 境外手机号，国内较难 |

**结论**：免费档能跑通，但只适合"偶尔连一下"。办公 RDP 长期用，建议花 ¥38~99/年 买台国内轻量（见路线 B）。

---

## 路线 A：Render 免费档（0 元，用 GitHub 登录）

仓库里已经有 `render.yaml`，Render 会自动识别。

1. 打开 https://render.com → **Deploy for free**（Hobby 计划，$0/月）
2. 用 GitHub 登录，授权时选中 `q2058584268/easytier-cloud-node`
3. Dashboard → **New +** → **Blueprint** → 选 `q2058584268/easytier-cloud-node`
4. 自动读取 `render.yaml`，点 **Apply**
5. 拿到 `https://xxx.onrender.com`，客户端填 **`wss://xxx.onrender.com`**（走 443，不带端口）

### 三个必须知道的坑

1. **空闲 15 分钟会休眠**，唤醒要 1 分钟左右。
   仓库里的 `keepalive.yml` 每 **5 分钟** ping 一次来保活（仓库公开，Actions 不耗额度）。
   但 GitHub Actions 的 cron 并不严格准时，偶尔会延迟，所以偶尔还是会睡 —— 这是免费档的固有代价。
2. **每月只有 5GB 流量**，超出 $0.15/GB。
   好消息：打洞成功时是 P2P 直连，流量**完全不经过** Render；只有打洞失败才走中继。
3. **区域**：`render.yaml` 里写的是 `singapore`（离国内最近）。若部署时提示该区域不可用，改成 `oregon` 重来。

### 配置够不够用

免费实例 512MB 内存、不到 1 核，跑 EasyTier 纯中继绰绰有余（它只转发包，自己不入网）。
瓶颈是带宽和休眠，不是 CPU。

---

## 路线 B：便宜 VPS 自建（推荐做主力节点）

国内轻量 2核2G 常年活动价 **¥38~99/年**（约 ¥3~8/月），延迟 10~30ms，独占带宽，不休眠。
腾讯云 / 阿里云 / 华为云 / 京东云都有，选国内节点。

买完后：

```bash
sudo bash install-vps.sh
```

脚本会装好 `easytier-core` + systemd 服务 + 防火墙放行。
**云厂商控制台的安全组也要放行：11010 TCP/UDP、11011 TCP、11012 TCP。**

接入地址：`tcp://<公网IP>:11010`

> 两条路可以并存：EasyTier 支持同时填多个 peer，自动选路。
> 国内 VPS 当主力、Render 当备份，挂了自动切。

---

## 验证节点活着

```bash
easytier-cli peer
ping <另一台机器的虚拟 IP>
```

`easytier-cli peer` 的 `cost` 列：`p2p` 表示直连（不耗云端带宽），`relay` 表示走了云端中继。

---

## 重要提醒：别和物理网段撞车

你们物理内网是 **10.126.126.0/24**，而 EasyTier 的 DHCP 默认网段正好也是 10.126.126.0/24。
**必须手动指定另一个网段**，否则路由会打架。建议用 `10.144.144.0/24`，见 `windows-client.md`。

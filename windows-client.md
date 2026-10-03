# Windows 客户端接入（每台机器都装）

## 1. 安装

下载 EasyTier GUI（v2.6.4）：

```
https://github.com/EasyTier/EasyTier/releases/download/v2.6.4/easytier-gui_2.6.4_x64-setup.exe
```

每台要互通的 Windows 都装一遍，**用管理员身份运行**（要创建虚拟网卡）。

## 2. 统一的网络身份（所有机器必须完全一致）

| 项目 | 值 | 说明 |
|---|---|---|
| 网络名称 | `hangzhou-office` | 自己起，越复杂越好，别和别人撞 |
| 网络密码 | `改成你自己的强密码` | 用于认证和加密，所有机器必须相同 |
| 虚拟网段 | `10.144.144.0/24` | **不要用 10.126.126.0/24**，和你们物理内网撞车 |

## 3. 每台机器固定虚拟 IP

在 GUI 里手动填 IPv4，别用 DHCP，否则重启后 IP 会变、RDP 连接会断：

| 机器 | 虚拟 IP |
|---|---|
| 10.126.126.2 | `10.144.144.2/24` |
| 10.126.126.100 | `10.144.144.100/24` |
| 10.126.126.101 | `10.144.144.101/24` |
| 10.126.126.110 | `10.144.144.110/24` |

（建议虚拟 IP 最后一段沿用物理 IP 最后一段，好记。）

## 4. 填云端节点地址

在 GUI 的「对等节点 / Peer」里添加云端节点地址，**只填一种**：

- Koyeb 路线：`wss://your-app-org.koyeb.app`
- VPS 路线：`tcp://<公网IP>:11010`

可以两个都填，EasyTier 会自动选路，一个挂了自动切另一个。

## 5. 开机自启

GUI 里有「注册为系统服务 / 启动器」选项，勾上即可开机自动组网，不需要每次手动开客户端。

## 6. 命令行等价写法（想脚本化批量部署时用）

```powershell
easytier-core.exe -i 10.144.144.110/24 `
  --network-name hangzhou-office `
  --network-secret <你的密码> `
  --hostname office-110 `
  -p wss://your-app-org.koyeb.app
```

## 7. 验证

```powershell
easytier-cli peer
ping 10.144.144.110
```

`easytier-cli peer` 输出里：

- `cost` 列显示 `p2p` → 已经打洞成功，两台机器直连，**不经过云端**，速度最快
- `cost` 列显示 `relay` → 走云端中继，能用但会消耗云端带宽

## 8. 远程桌面

1. 目标机上确认已开启「允许远程连接到此计算机」
2. 从任意一台入网的机器 `mstsc` → 填目标的**虚拟 IP**（如 `10.144.144.110`）
3. 如果 ping 得通但 RDP 连不上，多半是目标机防火墙拦了 3389，放行即可：

```powershell
netsh advfirewall firewall add rule name="RDP" dir=in action=allow protocol=TCP localport=3389
```

## 9. 顺手加个冗余（可选）

如果公司里有一台长期开机的机器，也可以照 README 的方式让它再跑一个 `--no-tun` 的共享节点，
用 Cloudflare Tunnel 暴露出来，作为第三个接入点。

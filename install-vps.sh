#!/usr/bin/env bash
# 一键在某台便宜 VPS 上部署 EasyTier 云端节点（Debian / Ubuntu）
# 用法：sudo bash install-vps.sh
# 可用环境变量覆盖：ET_VERSION / NODE_IP / PORT / NET_NAME / NET_SECRET
set -euo pipefail

ET_VERSION="${ET_VERSION:-v2.6.4}"
NODE_IP="${NODE_IP:-10.144.144.1/24}"
PORT="${PORT:-11010}"
NET_NAME="${NET_NAME:-hangzhou-office}"
NET_SECRET="${NET_SECRET:-ChangeMe_$(head -c 6 /dev/urandom | od -An -tx1 | tr -d ' \n')}"

ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64|amd64) ASSET="easytier-linux-x86_64-${ET_VERSION}.zip" ;;
  aarch64|arm64) ASSET="easytier-linux-aarch64-${ET_VERSION}.zip" ;;
  *) echo "不支持的架构: ${ARCH}"; exit 1 ;;
esac

echo "==> 安装依赖"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq unzip curl

echo "==> 下载 EasyTier ${ET_VERSION} (${ASSET})"
TMP="$(mktemp -d)"
curl -fsSL -o "${TMP}/et.zip" \
  "https://github.com/EasyTier/EasyTier/releases/download/${ET_VERSION}/${ASSET}"
unzip -q -o "${TMP}/et.zip" -d "${TMP}/et"
install -m 0755 "$(find "${TMP}/et" -type f -name easytier-core | head -1)" /usr/local/bin/easytier-core
install -m 0755 "$(find "${TMP}/et" -type f -name easytier-cli  | head -1)" /usr/local/bin/easytier-cli
rm -rf "${TMP}"

echo "==> 写 systemd 服务"
mkdir -p /etc/easytier
cat >/etc/systemd/system/easytier.service <<EOF
[Unit]
Description=EasyTier Cloud Node
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/easytier-core \\
  --ipv4 ${NODE_IP} \\
  --network-name ${NET_NAME} \\
  --network-secret ${NET_SECRET} \\
  --hostname vps-node \\
  --relay-network-whitelist ${NET_NAME} \\
  -l tcp://0.0.0.0:${PORT} \\
  -l udp://0.0.0.0:${PORT} \\
  -l ws://0.0.0.0:$((PORT+1)) \\
  -l wss://0.0.0.0:$((PORT+2))
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now easytier

echo "==> 放行防火墙（控制台安全组也要同步放行）"
if command -v ufw >/dev/null 2>&1; then
  ufw allow ${PORT}/tcp  || true
  ufw allow ${PORT}/udp  || true
  ufw allow $((PORT+1))/tcp || true
  ufw allow $((PORT+2))/tcp || true
fi

sleep 2
echo
echo "部署完成。本机公网 IP：$(curl -fsS -m 5 ifconfig.me || echo '请手动确认')"
echo "客户端接入地址：tcp://<公网IP>:${PORT}"
echo "网络名：${NET_NAME}"
echo "网络密钥：${NET_SECRET}"
echo "节点虚拟 IP：${NODE_IP}"
echo
systemctl status easytier --no-pager || true

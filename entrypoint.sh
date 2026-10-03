#!/bin/sh
# EasyTier 云端共享节点启动脚本
# 不加 --network-name / --network-secret / --private-mode => 公共共享节点模式，
# 各客户端自带网络身份接入，云端节点只负责「打洞协调 + 流量中继」，自己不入网。
set -eu

PORT="${PORT:-8000}"
HOSTNAME_TAG="${ET_HOSTNAME:-et-cloud}"

set -- \
  --no-tun \
  --hostname "${HOSTNAME_TAG}" \
  -l "ws://0.0.0.0:${PORT}/"

# 只允许为指定的网络名做中继，防止被陌生人白嫖带宽
# 例：ET_RELAY_NETWORK_WHITELIST="hangzhou-office"
if [ -n "${ET_RELAY_NETWORK_WHITELIST:-}" ]; then
  set -- "$@" --relay-network-whitelist "${ET_RELAY_NETWORK_WHITELIST}"
fi

exec /usr/local/bin/easytier-core "$@"

#!/usr/bin/env bash
# EasyTier 云端节点 —— 一键推送到 GitHub
#
# 前提：先去 https://github.com/settings/tokens 生成一个 Classic token，
#       勾选 repo（全部）和 workflow 两个权限，30 天有效即可。
#
# 用法（在本目录打开 Git Bash 或 PowerShell）：
#   export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
#   bash push-to-github.sh
#
# 可选环境变量：
#   REPO=easytier-cloud-node   仓库名

# 本机 git 不在默认 PATH 里，先补上
export PATH="/c/Users/Administrator/.workbuddy/binaries/PortableGit/versions/1.2.0/bin:/c/Users/Administrator/.workbuddy/binaries/PortableGit/versions/1.2.0/cmd:/c/Users/Administrator/.workbuddy/binaries/PortableGit/versions/1.2.0/usr/bin:/c/Users/Administrator/.workbuddy/binaries/PortableGit/versions/1.2.0/mingw64/bin:$PATH"

set -euo pipefail

TOKEN="${GITHUB_TOKEN:-}"
if [ -z "${TOKEN}" ]; then
  echo "错误：请先设置环境变量 GITHUB_TOKEN"
  echo "  export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx"
  exit 1
fi

REPO="${REPO:-easytier-cloud-node}"
API="https://api.github.com"
HDR=(-H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.github+json")

echo "==> 读取账号信息"
LOGIN="$(curl -fsS "${HDR[@]}" "${API}/user" | grep -o '"login": *"[^"]*"' | cut -d'"' -f4)"
if [ -z "${LOGIN}" ]; then
  echo "错误：token 无效或权限不足"
  exit 1
fi
echo "    GitHub 账号：${LOGIN}"

echo "==> 创建仓库 ${LOGIN}/${REPO}"
if curl -fsS -X POST "${HDR[@]}" "${API}/user/repos" \
     -d "{\"name\":\"${REPO}\",\"private\":false,\"auto_init\":false}" >/dev/null 2>&1; then
  echo "    已创建"
else
  echo "    （仓库可能已存在，直接复用）"
fi

echo "==> 推送代码"
git remote remove origin 2>/dev/null || true
git remote add origin "https://${LOGIN}:${TOKEN}@github.com/${LOGIN}/${REPO}.git"
git branch -M main
git push -u origin main

echo
echo "完成：https://github.com/${LOGIN}/${REPO}"
echo
echo "下一步（在浏览器里做，约 2 分钟）："
echo "  1. 打开 koyeb.com，用 GitHub 登录"
echo "  2. Create Web Service -> GitHub -> 选 ${REPO}"
echo "  3. Dockerfile 构建 / Free 实例 / Region 选 Singapore"
echo "  4. Ports: 8000, HTTP"
echo "  5. Health checks: 改成 TCP（必须！HTTP 会被判 unhealthy 反复重启）"
echo "  6. 环境变量 ET_RELAY_NETWORK_WHITELIST=hangzhou-office"
echo "  7. Deploy -> 拿到 https://xxx.koyeb.app，客户端用 wss://xxx.koyeb.app"

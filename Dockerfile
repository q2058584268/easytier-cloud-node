# EasyTier 云端中继节点
# 特点：--no-tun 无 TUN 模式，不需要 root / NET_ADMIN / /dev/net/tun
# 因此可以跑在任何免费容器平台（Koyeb / Render / Zeabur / 自建 Docker）
FROM debian:bookworm-slim

ARG ET_VERSION=v2.6.4
ARG ET_ASSET=easytier-linux-x86_64-${ET_VERSION}.zip

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl unzip tini; \
    rm -rf /var/lib/apt/lists/*; \
    curl -fsSL -o /tmp/et.zip \
      "https://github.com/EasyTier/EasyTier/releases/download/${ET_VERSION}/${ET_ASSET}"; \
    unzip -q -o /tmp/et.zip -d /tmp/et; \
    find /tmp/et -type f -name 'easytier-core' -exec install -m 0755 {} /usr/local/bin/easytier-core \; ; \
    find /tmp/et -type f -name 'easytier-cli'  -exec install -m 0755 {} /usr/local/bin/easytier-cli  \; ; \
    rm -rf /tmp/et /tmp/et.zip; \
    test -x /usr/local/bin/easytier-core

ENV PORT=8000
ENV TZ=Asia/Shanghai

EXPOSE 8000

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]

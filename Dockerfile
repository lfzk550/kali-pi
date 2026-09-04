# Reconstruct of ghcr.io/tunmax/openclaw_computer:hermes_latest
# Scripts extracted from the published image rootfs.
FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    TZ=Asia/Shanghai \
    ROOT_PASSWD=123456 \
    MODELSCOPE_API_KEY=not_set_yet \
    UV_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    OPENCLAW_DISABLE_BONJOUR=1

RUN sed -i 's|deb.debian.org|mirrors.tuna.tsinghua.edu.cn|g; s|security.debian.org|mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list.d/debian.sources \
 && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
 && echo Asia/Shanghai > /etc/timezone

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl wget gnupg git sudo unzip rsync procps htop vim \
        locales tzdata net-tools iputils-ping openssh-client \
        python3 python3-dev python3-pip python3-venv python3-websockify \
        zsh build-essential inotify-tools wmctrl \
        dbus dbus-x11 \
        xorg xvfb x11-utils x11-xserver-utils \
        tigervnc-standalone-server tigervnc-common tigervnc-tools \
        novnc websockify \
        kde-plasma-desktop plasma-desktop plasma-workspace kwin-x11 \
        konsole kde-cli-tools \
        fcitx5 fcitx5-chinese-addons fcitx5-pinyin fcitx5-frontend-qt5 \
        fcitx5-frontend-gtk3 kde-config-fcitx5 \
        fonts-noto-cjk fonts-noto-color-emoji fonts-wqy-microhei fonts-wqy-zenhei \
        fonts-liberation \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
 && echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main' \
      > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends google-chrome-stable \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://rclone.org/install.sh | bash

ENV NODE_VERSION=24.14.0
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
      | tar -xJ -C /usr/local \
 && mv /usr/local/node-v${NODE_VERSION}-linux-x64 /usr/local/node \
 && ln -sf /usr/local/node/bin/node /usr/local/bin/node \
 && ln -sf /usr/local/node/bin/npm  /usr/local/bin/npm \
 && ln -sf /usr/local/node/bin/npx  /usr/local/bin/npx

ENV PATH="/root/.local/bin:/usr/local/node/bin:/usr/local/bin:${PATH}"
RUN curl -fsSL https://astral.sh/uv/install.sh | sh

RUN mkdir -p /root/.hermes /root/bz-startup /root/Desktop /root/.vnc /bz \
 && (git clone --depth 1 --branch v0.15.1 https://github.com/NousResearch/hermes-agent.git /root/.hermes/hermes-agent \
     || git clone --depth 1 https://github.com/NousResearch/hermes-agent.git /root/.hermes/hermes-agent) \
 && uv pip install --system -e /root/.hermes/hermes-agent || uv pip install --python python3 hermes-agent || true \
 && mkdir -p /root/.local/bin \
 && if [ -x /root/.hermes/hermes-agent/venv/bin/hermes ]; then ln -sf /root/.hermes/hermes-agent/venv/bin/hermes /root/.local/bin/hermes; fi \
 && command -v hermes >/dev/null 2>&1 && ln -sf "$(command -v hermes)" /root/.local/bin/hermes || true

COPY entrypoint.sh /entrypoint.sh
COPY bz/ /bz/
COPY root/.vnc/xstartup /root/.vnc/xstartup
COPY root/bz-startup/main.sh /root/bz-startup/main.sh
COPY usr/clear_apt_npm_cache.sh /usr/clear_apt_npm_cache.sh
COPY config/hermes.yaml /root/.hermes/config.yaml

RUN chmod +x /entrypoint.sh /bz/*.sh /root/.vnc/xstartup /usr/clear_apt_npm_cache.sh /root/bz-startup/main.sh \
 && echo 'root:123456' | chpasswd

EXPOSE 7860
ENTRYPOINT ["/entrypoint.sh"]

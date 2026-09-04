# Kali rolling desktop + Pi coding agent
# Official base: kalilinux/kali-rolling (weekly snapshot, no tools preinstalled)
FROM kalilinux/kali-rolling:latest

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    TZ=Asia/Shanghai \
    ROOT_PASSWD=123456 \
    MODELSCOPE_API_KEY=not_set_yet \
    OPENCLAW_DISABLE_BONJOUR=1

# Kali 2026+ uses sources.list.d/*.sources; older snapshots still have sources.list.
RUN set -eux; \
    if [ -f /etc/apt/sources.list.d/kali.sources ]; then \
      sed -i 's|http://http.kali.org/kali|http://mirrors.tuna.tsinghua.edu.cn/kali|g; s|https://http.kali.org/kali|http://mirrors.tuna.tsinghua.edu.cn/kali|g' /etc/apt/sources.list.d/kali.sources; \
    fi; \
    if [ -f /etc/apt/sources.list ]; then \
      sed -i 's|http.kali.org/kali|mirrors.tuna.tsinghua.edu.cn/kali|g' /etc/apt/sources.list; \
    fi; \
    ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    echo Asia/Shanghai > /etc/timezone

RUN apt-get update && apt-get install -y --no-install-recommends \
        kali-archive-keyring ca-certificates curl wget gnupg git sudo unzip rsync \
        procps htop vim locales tzdata net-tools iproute2 iputils-ping openssh-client \
        python3 python3-pip python3-venv python3-websockify \
        zsh build-essential inotify-tools wmctrl \
        dbus dbus-x11 \
        xorg xvfb x11-utils x11-xserver-utils \
        tigervnc-standalone-server tigervnc-common tigervnc-tools \
        novnc websockify \
        kali-desktop-kde plasma-desktop plasma-workspace \
        kwin-x11 konsole kde-cli-tools \
        fcitx5 fcitx5-chinese-addons fcitx5-pinyin fcitx5-frontend-qt5 \
        fcitx5-frontend-gtk3 \
        fonts-noto-cjk fonts-noto-color-emoji fonts-wqy-microhei fonts-wqy-zenhei \
        fonts-liberation \
    && (apt-get install -y --no-install-recommends kde-config-fcitx5 || true) \
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

ENV PATH="/root/.local/bin:/usr/local/node/bin:/usr/local/bin:${PATH}" \
    npm_config_update_notifier=false

# Pi coding agent (replaces Hermes). Official package moved to @earendil-works.
RUN npm config set registry https://registry.npmmirror.com \
 && npm install -g @earendil-works/pi-coding-agent \
 && npm cache clean --force \
 && command -v pi \
 && ln -sf "$(command -v pi)" /usr/local/bin/pi \
 && mkdir -p /root/.pi/agent /root/bz-startup /root/Desktop /root/.vnc /bz /root/.local/bin \
 && ln -sf /usr/local/bin/pi /root/.local/bin/pi

COPY entrypoint.sh /entrypoint.sh
COPY bz/ /bz/
COPY root/.vnc/xstartup /root/.vnc/xstartup
COPY root/bz-startup/main.sh /root/bz-startup/main.sh
COPY usr/clear_apt_npm_cache.sh /usr/clear_apt_npm_cache.sh
COPY config/models.json /root/.pi/agent/models.json

RUN chmod +x /entrypoint.sh /bz/*.sh /root/.vnc/xstartup /usr/clear_apt_npm_cache.sh /root/bz-startup/main.sh \
 && echo 'root:123456' | chpasswd

EXPOSE 7860
ENTRYPOINT ["/entrypoint.sh"]

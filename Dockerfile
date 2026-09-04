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
        procss htop vim locales tzdata net-tools iproute2 iputils-ping openssh-client \
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
    && mkdir -p /etc/xdg /root/.config \
    && printf '%s\n' '[Daemon]' 'Autolock=false' 'LockOnResume=false' 'LockOnLid=false' 'Timeout=0' > /etc/xdg/kscreenlockerrc \
    && cp /etc/xdg/kscreenlockerrc /root/.config/kscreenlockerrc \
    && find /usr -name 'kscreenlocker_greet' -exec chmod a-x {} + || true \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

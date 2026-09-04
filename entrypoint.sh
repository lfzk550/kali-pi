#!/bin/bash

start_services() {
    echo "[*] 启动服务..."

    export USER="${USER:-root}"
    export HOME="${HOME:-/root}"
    export DISPLAY=":1"

    VNC_GEOMETRY="${VNC_GEOMETRY:-1920x1080}"
    VNC_DEPTH="${VNC_DEPTH:-24}"
    VNC_PORT=5901
    NOVNC_PORT=7860
    NOVNC_PATH="/usr/share/novnc"
    if [ ! -d "$NOVNC_PATH" ]; then
        for p in /usr/share/novnc /usr/share/novnc/utils /usr/share/webapps/novnc; do
            if [ -f "$p/vnc.html" ]; then NOVNC_PATH="$p"; break; fi
        done
    fi

    # Kali/Debian novnc package has vnc.html but no index.html → directory listing at /
    if [ -f "${NOVNC_PATH}/vnc.html" ] && [ ! -f "${NOVNC_PATH}/index.html" ]; then
        cat > "${NOVNC_PATH}/index.html" <<'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=1&resize=scale">
  <title>noVNC</title>
</head>
<body>
  <p><a href="vnc.html?autoconnect=1&resize=scale">Connect to desktop</a></p>
</body>
</html>
EOF
    fi

    if [ -n "${VNC_PASSWD}" ]; then
        mkdir -p "${HOME}/.vnc"
        echo "${VNC_PASSWD}" | vncpasswd -f > "${HOME}/.vnc/passwd"
        chmod 600 "${HOME}/.vnc/passwd"
        VNC_SECURITY_ARGS="-SecurityTypes VncAuth"
    else
        VNC_SECURITY_ARGS="-SecurityTypes None --I-KNOW-THIS-IS-INSECURE"
    fi

    DEMO_ARGS=""
    if [[ "$(hostname)" == *"-brianzhou-"* ]]; then
        DEMO_ARGS="-AcceptPointerEvents=0 -AcceptKeyEvents=0"
        sed -i 's/set resizeSession(resize) {/set resizeSession(resize) {\n        return;/' "${NOVNC_PATH}/core/rfb.js" 2>/dev/null || true
        sed -i "/<option value=\"remote\">/d" "${NOVNC_PATH}/vnc.html" 2>/dev/null || true
    fi

    vncserver -kill "${DISPLAY}" 2>/dev/null || true
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null || true

    echo "[*] 启动 TigerVNC on ${DISPLAY} (${VNC_GEOMETRY})..."
    vncserver "${DISPLAY}" \
        -geometry "${VNC_GEOMETRY}" \
        -depth "${VNC_DEPTH}" \
        $VNC_SECURITY_ARGS \
        -localhost no \
        -fg \
        $DEMO_ARGS &

    echo "[*] 等待 VNC 服务就绪（端口 ${VNC_PORT}）..."
    for i in $(seq 1 30); do
        if ss -tlnp 2>/dev/null | grep -q ":${VNC_PORT}"; then
            echo "[*] VNC 已就绪"
            break
        fi
        sleep 1
    done

    source /tmp/dbus-session.env 2>/dev/null || true
    export DBUS_SESSION_BUS_ADDRESS
    export XDG_CURRENT_DESKTOP=KDE
    export KDE_FULL_SESSION=true
    export DESKTOP_SESSION=plasma
    export XDG_SESSION_TYPE=x11
    export GTK_IM_MODULE=fcitx
    export QT_IM_MODULE=fcitx
    export XMODIFIERS=@im=fcitx
    export INPUT_METHOD=fcitx
    export SDL_IM_MODULE=fcitx
    mkdir -p /tmp/root-runtime
    chmod 700 /tmp/root-runtime
    export XDG_RUNTIME_DIR=/tmp/root-runtime

    if [[ "$(hostname)" == *"-brianzhou-"* ]]; then
        plasma-apply-wallpaperimage /bz/desktop.png 2>/dev/null || true
        rm -rf /mnt/workspace/root
    fi

    echo "[*] 启动 noVNC，监听端口 ${NOVNC_PORT}，webroot=${NOVNC_PATH}..."
    websockify \
        --web "${NOVNC_PATH}" \
        --heartbeat 30 \
        "0.0.0.0:${NOVNC_PORT}" \
        "localhost:${VNC_PORT}" &

    echo ""
    echo "============================================"
    echo "  KDE Plasma 桌面已启动！"
    echo "  访问地址: http://<host>:${NOVNC_PORT}/vnc.html?autoconnect=1"
    echo "  分辨率:   ${VNC_GEOMETRY}"
    echo "  时区:     Asia/Shanghai (UTC+8)"
    echo "  语言:     zh_CN.UTF-8"
    echo "  输入法:   Fcitx5 拼音（Ctrl+Shift 切换）"
    echo "  代理:     Pi coding agent"
    echo "============================================"

    echo "root:${ROOT_PASSWD:-123456}" | chpasswd

    if [ "$SKIP_RESTORE" = "1" ]; then
        echo "检测到 SKIP_RESTORE，跳过配置恢复/备份与自定义启动脚本"
    else
        echo "开始 Pi 历史配置恢复，同时执行用户自定义启动脚本"
        /bz/auto_recover.sh
    fi

    export MODELSCOPE_API_KEY="${MODELSCOPE_API_KEY:-not_set_yet}"
    export PATH="/root/.local/bin:/usr/local/node/bin:$PATH"

    PI_BIN="$(command -v pi || true)"
    if [ -z "$PI_BIN" ] && [ -x /root/.local/bin/pi ]; then
        PI_BIN=/root/.local/bin/pi
    fi

    rm /root/.config/google-chrome/Singleton* >/dev/null 2>&1
    google-chrome-stable \
    --no-sandbox \
    --disable-dev-shm-usage \
    --disable-gpu \
    --disable-software-rasterizer \
    --test-type \
    about:blank >/dev/null 2>&1 &

    if [ -n "$PI_BIN" ]; then
        konsole --geometry 1555x945+177+51 -e "$PI_BIN" >/dev/null 2>&1 &
    else
        echo "警告: 未找到 pi 可执行文件" >&2
        konsole --geometry 1555x945+177+51 >/dev/null 2>&1 &
    fi
    sleep 10
    wmctrl -r "pi" -b add,above 2>/dev/null || true
    sleep 30
    wmctrl -r "pi" -b remove,above 2>/dev/null || true
    wmctrl -a "pi" 2>/dev/null || true
    tail -f /dev/null
}

main() {
    export LANG=zh_CN.UTF-8
    export LC_ALL=zh_CN.UTF-8
    export LANGUAGE=zh_CN:zh
    export OPENCLAW_DISABLE_BONJOUR="${OPENCLAW_DISABLE_BONJOUR:-1}"
    start_services
}

main "$@"

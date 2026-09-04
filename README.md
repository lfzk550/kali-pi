# kali-pi · Kali Rolling + Hermes 桌面容器

`kali` 分支基座是官方 `kalilinux/kali-rolling`，不是 Debian Bookworm。  
启动脚本仍来自 `ghcr.io/tunmax/openclaw_computer:hermes_latest` 的 rootfs 反推。

浏览器打开 **http://localhost:7860** 进入 KDE + Hermes。

## 一键构建

```bash
git clone -b kali https://github.com/lfzk550/kali-pi.git
cd kali-pi
docker build -t kali-pi:kali .
```

GitHub Actions 在 push 到 `kali` 后会构建并推：

`ghcr.io/lfzk550/kali-pi:kali`

仓库需开启 Packages 写权限（Settings → Actions → Workflow permissions → Read and write）。

## 一键运行

```bash
docker run -d --name kali-pi \
  -p 7860:7860 \
  --shm-size=2g \
  -e ROOT_PASSWD=123456 \
  -e MODELSCOPE_API_KEY=你的key \
  kali-pi:kali
```

或：

```bash
MODELSCOPE_API_KEY=你的key docker compose up -d
```

打开 http://localhost:7860

| 环境变量 | 默认 | 说明 |
|---|---|---|
| `ROOT_PASSWD` | `123456` | 锁屏解锁密码 |
| `MODELSCOPE_API_KEY` | `not_set_yet` | ModelScope 推理密钥 |
| `VNC_PASSWD` | 空 | 设置后 noVNC 需要密码 |
| `SKIP_RESTORE` | `0` | `1` 跳过配置恢复/备份 |

## Kali 适配要点

- 基座：`kalilinux/kali-rolling`（官方推荐，周更新，默认不带工具集）
- 软源：写入前尝试切到清华 Kali 镜像；兼容 `kali.sources` 与旧 `sources.list`
- 桌面：`kali-desktop-kde`（Kali 2026.2 为 Plasma 6）+ TigerVNC / noVNC，仍走 X11 `startplasma-x11`
- **不**安装 `kali-linux-default` / `kali-linux-large`，只装桌面和运行依赖
- Python：Kali rolling 受 PEP 668 限制，Hermes 装进 `/root/.hermes/venv`
- Chrome：仍走 Google 官方源（Kali 仓没有 chrome）
- 输入法：Fcitx5；`kde-config-fcitx5` 若缺包则跳过

## 注意

这是等价还原 + Kali 适配，不是 bit 级复刻。第一次 `docker build` 会比较久（KDE + Chrome + Hermes）。

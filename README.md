# kali-pi · Hermes 桌面容器

从 `ghcr.io/tunmax/openclaw_computer:hermes_latest` 反推整理的可构建仓库。  
原镜像用 `docker export | docker import` 压扁过，没有官方 Dockerfile；本仓库脚本（`entrypoint.sh`、`bz/*`、`root/.vnc/xstartup`）来自该镜像 rootfs。

浏览器打开 **http://localhost:7860** 就是 KDE + Hermes。

## 一键构建

```bash
git clone https://github.com/lfzk550/kali-pi.git
cd kali-pi
docker build -t kali-pi:hermes .
```

GitHub Actions 在 push 到 `main` 后会自动构建并推到：

`ghcr.io/lfzk550/kali-pi:hermes`

仓库需开启 Packages 写权限（Settings → Actions → Workflow permissions → Read and write）。首次拉私有包：

```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u lfzk550 --password-stdin
docker pull ghcr.io/lfzk550/kali-pi:hermes
```

## 一键运行

```bash
docker run -d --name kali-pi \
  -p 7860:7860 \
  -e ROOT_PASSWD=123456 \
  -e MODELSCOPE_API_KEY=你的key \
  kali-pi:hermes
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
| `S3_*` / `WEBDAV_*` | 空 | 远程备份，逻辑与原镜像相同 |

## 目录

```
Dockerfile                 构建定义
entrypoint.sh              容器入口（VNC + noVNC:7860 + Hermes）
docker-compose.yml
bz/auto_recover.sh         启动时恢复
bz/sync_init.sh            从本机 / S3 / WebDAV 恢复
bz/sync_daemon.sh          实时备份
bz/rules.txt  watch.txt
root/.vnc/xstartup         KDE Plasma + Fcitx5
root/bz-startup/main.sh    自定义启动钩子（空）
config/hermes.yaml         Hermes 默认配置
usr/clear_apt_npm_cache.sh
.github/workflows/docker.yml
```

## 注意

这是等价还原，不是 bit 级复刻。Hermes 默认拉 `v0.15.1`，没有该 tag 时回退 `main`。

# kali-pi · Kali Rolling + Pi coding agent

`pi` 分支基座仍是 `kalilinux/kali-rolling`，代理从 Hermes 换成 [Pi](https://pi.dev) （`@earendil-works/pi-coding-agent`）。

浏览器打开 **http://localhost:7860** 进入 KDE；桌面会自动打开 Konsole 跑 `pi`。Pi 没有 Hermes 那种 dashboard/gateway，是 TUI 代理。

## 一键构建

```bash
git clone -b pi https://github.com/lfzk550/kali-pi.git
cd kali-pi
docker build -t kali-pi:pi .
```

GitHub Actions 在 push 到 `pi` 后会构建并推：

`ghcr.io/lfzk550/kali-pi:pi`

## 一键运行

```bash
docker run -d --name kali-pi \
  -p 7860:7860 \
  --shm-size=2g \
  -e ROOT_PASSWD=123456 \
  -e MODELSCOPE_API_KEY=你的key \
  kali-pi:pi
```

或：

```bash
MODELSCOPE_API_KEY=你的key docker compose up -d
```

打开 http://localhost:7860 ，在终端里用 `/model` 选 ModelScope 模型。

| 环境变量 | 默认 | 说明 |
|---|---|---|
| `ROOT_PASSWD` | `123456` | 锁屏解锁密码 |
| `MODELSCOPE_API_KEY` | `not_set_yet` | 写入 `~/.pi/agent/models.json` 的 `$MODELSCOPE_API_KEY` |
| `VNC_PASSWD` | 空 | 设置后 noVNC 需要密码 |
| `SKIP_RESTORE` | `0` | `1` 跳过配置恢复/备份 |

## 相对 Kali/Hermes 分支的改变

- 安装：`npm install -g @earendil-works/pi-coding-agent`，不再 clone hermes-agent / uv venv
- 启动：Konsole 执行 `pi`，不启 `hermes dashboard/gateway`，不再等 9119
- 配置：`/root/.pi/agent/models.json`（ModelScope OpenAI 兼容接口）
- 备份监控：`~/.pi`，远程包默认 `backups/data_pi.tar.gz`

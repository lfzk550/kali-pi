#!/bin/bash

echo "=== 开始清理缓存 ==="

echo "\n[apt] 清理中..."
apt clean
apt autoclean
apt autoremove --purge -y || true

echo "\n[npm] 清理中..."
npm cache clean --force 2>/dev/null || true

pkill hermes 2>/dev/null || true
rm -rf /root/.hermes/logs/* 2>/dev/null || true
uv cache clean 2>/dev/null || true

echo "" > /root/.zsh_history
rm -rf /root/.zcompdump*
echo "=== 清理完成 ==="

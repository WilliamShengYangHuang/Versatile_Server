#!/usr/bin/env bash
# 一键安装脚本 · Server Console Backend
# 用法: sudo bash install.sh
# 可选环境变量: PORT(默认8787) MODE(internal|external,默认internal) ADMIN_TOKEN(留空自动生成)

set -e

PORT="${PORT:-8787}"
MODE="${MODE:-internal}"
ADMIN_TOKEN="${ADMIN_TOKEN:-$(openssl rand -hex 16 2>/dev/null || date +%s%N)}"
HOST="127.0.0.1"
if [ "$MODE" = "external" ]; then HOST="0.0.0.0"; fi

echo "=============================================="
echo " Server Console Backend · 一键安装"
echo " 模式: $MODE   端口: $PORT   绑定: $HOST"
echo "=============================================="

# 1. 安装 Node.js (若未安装)
if ! command -v node >/dev/null 2>&1; then
  echo "→ 未检测到 Node.js,正在安装 Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >/dev/null 2>&1 || true
  sudo apt-get install -y nodejs >/dev/null 2>&1 || true
fi
echo "→ Node 版本: $(node -v 2>/dev/null || echo '安装失败,请手动安装 Node.js 18+')"

# 2. 安装依赖
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
echo "→ 安装依赖..."
npm install --omit=dev --no-audit --no-fund

# 3. 写入 .env
cat > .env <<EOF
PORT=$PORT
HOST=$HOST
MODE=$MODE
ADMIN_TOKEN=$ADMIN_TOKEN
EOF
echo "→ 已写入 .env"

# 4. 注册 systemd 服务(需要 root)
if [ "$(id -u)" = "0" ] && command -v systemctl >/dev/null 2>&1; then
  SERVICE_FILE="/etc/systemd/system/server-console-backend.service"
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Server Console Backend
After=network.target

[Service]
Type=simple
WorkingDirectory=$SCRIPT_DIR
EnvironmentFile=$SCRIPT_DIR/.env
ExecStart=$(command -v node) $SCRIPT_DIR/server.js
Restart=on-failure
User=$(logname 2>/dev/null || echo root)

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable server-console-backend
  systemctl restart server-console-backend
  echo "→ systemd 服务已启动: server-console-backend"
  echo "   查看状态: systemctl status server-console-backend"
  echo "   查看日志: journalctl -u server-console-backend -f"
else
  echo "→ 未以 root 运行或系统无 systemd,改为前台直接启动(关闭终端会停止服务):"
  echo "   nohup node server.js > backend.log 2>&1 &"
  MODE=$MODE PORT=$PORT HOST=$HOST ADMIN_TOKEN=$ADMIN_TOKEN nohup node server.js > backend.log 2>&1 &
  echo "→ 已在后台启动,PID: $!"
fi

echo "=============================================="
echo " 完成 ✓"
echo " 内部访问地址: http://$HOST:$PORT"
echo " 管理员 Token(用于外部写操作): $ADMIN_TOKEN"
echo " 把地址填入 Server Console 的「数据源设置」即可连接"
if [ "$MODE" = "external" ]; then
  echo " 提示: 已开放为外部模式,请自行配置防火墙/反向代理(nginx+SSL)并妥善保管 Token"
fi
echo "=============================================="

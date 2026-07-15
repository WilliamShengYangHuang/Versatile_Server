# Server Console Backend

给「多功能服务器架构设计」控制台提供真实数据接口的最小后端。JSON 文件持久化,无数据库依赖,一条命令即可跑起来。

## 一键部署

选你的机器类型:

**Linux(推荐用于长期挂机 / 云主机)**
```bash
cd backend
chmod +x install.sh
sudo bash install.sh
```
注册为 systemd 服务,开机自启,适合服务器或常年开机的 Linux 机器。

**Windows(用自己的电脑,不租云主机)**
```powershell
cd backend
powershell -ExecutionPolicy Bypass -File install.ps1
```
自动安装 Node.js(通过 winget)、写入配置、注册后台自启动(有 NSSM 则注册为 Windows 服务,否则用任务计划程序在每次登录时自动运行)。适合把家里/实验室一台常开的 Windows PC 当内部服务器,不需要额外云费用。

两种方案默认都是「内部模式」(仅本机/局域网可访问),接口和数据结构完全一致,团队从任意系统连接都一样。

自定义参数:

```bash
# Linux
sudo PORT=9000 MODE=external ADMIN_TOKEN=your-secret bash install.sh
```
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File install.ps1 -Port 9000 -Mode external -AdminToken your-secret
```

- `MODE=internal`(默认):只在服务器本机可访问,适合团队内网/隧道访问,最安全。
- `MODE=external`:对外监听 0.0.0.0,写操作(POST/DELETE)强制要求 `Authorization: Bearer <ADMIN_TOKEN>`。对外场景建议再套一层 nginx + HTTPS。

## 接口一览

- `GET /api/health` — 连接测试
- `GET /api/overview` — 各模块条目数统计
- `GET/POST/DELETE /api/sites` `/api/models` `/api/posts` `/api/pipelines` `/api/domains`
- `GET/POST /api/settings` — 如流量告警阈值
- `GET /api/usage` — 带宽遥测(占位,接入监控系统后返回真实序列)

## 常用运维

Linux:
```bash
systemctl status server-console-backend   # 状态
journalctl -u server-console-backend -f   # 日志
systemctl restart server-console-backend  # 重启
```

Windows(若用 NSSM):
```powershell
nssm status ServerConsoleBackend
nssm restart ServerConsoleBackend
```
Windows(若用计划任务): 打开「任务计划程序」→ 找到 ServerConsoleBackend → 右键运行/结束/查看历史记录。

数据文件在 `backend/data.json`,直接备份该文件即可备份全部数据。

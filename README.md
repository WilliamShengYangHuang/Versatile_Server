# Versatile Server · 多功能服务器架构设计

*[English below](#versatile-server--english)*

一个面向个人/小团队的多功能服务器管理平台原型 + 后端骨架:统一管理网站托管、AI 模型部署、内容发布、GitHub / CI-CD、流量与用量、域名与安全,并提供一键部署脚本(Windows / Linux 均支持),优先服务于团队内部使用,预留未来对外开放的接口。

## 项目结构

```
Server Console.dc.html   前端控制台(总览 + 6 个模块页面,中英文双语)
Setup Wizard.dc.html     一步步部署引导 UI(选机器类型 → 一键安装 → 连接测试 → 内部/外部 → 完成)
backend/                 后端服务(Node.js + Express,JSON 文件持久化)
  server.js              API 服务主体
  install.sh             Linux 一键安装脚本(注册 systemd 服务)
  install.ps1            Windows 一键安装脚本(注册计划任务 / NSSM 服务)
  package.json
  README.md              后端部署与运维说明
```

## 核心特性

- **总览仪表盘**:实时统计各模块条目数、待处理事项高亮显示,无数据时诚实展示"目前无数据",不使用任何假数据。
- **网站托管 / AI 模型 / 内容发布 / GitHub CI-CD / 域名与安全**:每个模块可直接在界面里新增条目(添加站点、部署模型、发布内容、连接仓库、绑定域名),写操作会实时同步到后端。
- **流量与用量**:告警阈值设置、操作日志查看与下载、真实网络测速(下载/上传速度、延迟,渐变环形可视化)。
- **数据源设置**:填入后端 API 地址即可连接,连接状态用灯号实时显示(未连接 / 连接中 / 已连接 / 失败)。
- **中英文切换**:界面全量文案支持中文 / English 一键切换。
- **部署引导向导**:5 步图形化引导,支持选择 Windows PC 或 Linux 机器,给出对应平台的具体命令。

## 快速开始

### 1. 打开前端

用浏览器直接打开 `Server Console.dc.html` 即可预览界面(默认无数据源,所有模块显示"目前无数据")。

### 2. 部署后端

打开 `Setup Wizard.dc.html` 按引导操作,或直接:

**Linux**
```bash
cd backend
chmod +x install.sh
sudo bash install.sh
```

**Windows**(管理员 PowerShell)
```powershell
cd backend
powershell -ExecutionPolicy Bypass -File install.ps1
```

默认注册为开机自启的后台服务,内部模式仅监听 `127.0.0.1:8787`。完成后终端会打印访问地址与管理员 Token。

### 3. 连接

回到 `Server Console.dc.html`,右上角「数据源设置」填入后端地址(如 `http://127.0.0.1:8787`)并保存,各模块即从"无数据"变为真实数据。

## 内部使用 / 外部开放

- 默认「内部模式」:仅本机 / 局域网可访问,无需公网 IP、无需备案,适合团队内部使用。
- 如需未来对外开放某些接口(如公开的 AI 模型 API),按 `backend/README.md` 说明切换到 `MODE=external`,写操作将强制要求 `Authorization: Bearer <ADMIN_TOKEN>`,并建议额外部署 nginx/反向代理 + HTTPS。

## 技术栈

- 前端:纯 HTML + 内联样式的 Design Component(无构建步骤,浏览器直接打开)
- 后端:Node.js + Express,JSON 文件持久化,无数据库依赖

---

# Versatile Server · English

A self-hosted, multi-purpose server management console prototype + backend skeleton for individuals or small teams: manage website hosting, AI model deployment, content publishing, GitHub / CI-CD, traffic & usage, and domains & security from one dashboard. Ships with one-click installers for both Windows and Linux, defaults to internal-only use, and leaves a clear path to open external access later.

## Project Structure

```
Server Console.dc.html   Frontend console (overview + 6 module pages, bilingual EN/中文)
Setup Wizard.dc.html     Step-by-step deployment wizard (pick machine type → one-click install → test connection → internal/external → done)
backend/                 Backend service (Node.js + Express, JSON file persistence)
  server.js              Main API server
  install.sh             Linux one-click installer (registers a systemd service)
  install.ps1            Windows one-click installer (registers a scheduled task / NSSM service)
  package.json
  README.md              Backend deployment & ops notes
```

## Key Features

- **Overview dashboard**: live counts per module, pending items surfaced prominently; shows an honest "no data yet" when empty — no fake/mock data anywhere.
- **Sites / AI Models / Content / GitHub CI-CD / Domains & Security**: add real entries directly from the UI (add a site, deploy a model, publish a post, connect a repo, bind a domain); writes sync live to the backend.
- **Usage & Traffic**: set a traffic alert threshold, view/download the activity log, and run a real network speed test (download/upload throughput + latency, shown as gradient ring gauges).
- **Data source settings**: point the console at your backend's API URL; a status indicator shows unconfigured / connecting / connected / error in real time.
- **Language toggle**: every string in the UI switches between 中文 and English instantly.
- **Setup wizard**: 5-step guided flow, lets you choose a Windows PC or a Linux machine and shows the matching commands.

## Quick Start

### 1. Open the frontend

Open `Server Console.dc.html` directly in a browser to preview the UI (no data source configured by default — every module shows "no data yet").

### 2. Deploy the backend

Open `Setup Wizard.dc.html` and follow the steps, or run directly:

**Linux**
```bash
cd backend
chmod +x install.sh
sudo bash install.sh
```

**Windows** (PowerShell as Administrator)
```powershell
cd backend
powershell -ExecutionPolicy Bypass -File install.ps1
```

Registers as an auto-starting background service by default, internal mode listening only on `127.0.0.1:8787`. The terminal prints the access URL and admin token when done.

### 3. Connect

Back in `Server Console.dc.html`, open "Data Source" (top right), enter the backend URL (e.g. `http://127.0.0.1:8787`), and save — every module switches from "no data" to live data.

## Internal Use / External Access

- Default is **internal mode**: accessible only on the local machine / LAN, no public IP or business registration needed — ideal for internal team use.
- To open specific endpoints externally later (e.g. a public AI model API), switch to `MODE=external` per `backend/README.md`; write operations then require `Authorization: Bearer <ADMIN_TOKEN>`, and adding nginx/a reverse proxy + HTTPS in front is recommended.

## Tech Stack

- Frontend: plain HTML with inline styles, built as a Design Component (no build step, opens directly in a browser)
- Backend: Node.js + Express, JSON file persistence, no database dependency

## License

See `LICENSE`.

# Server Console Backend — Windows 一键安装脚本
# 用法(以管理员身份打开 PowerShell): 
#   cd backend
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# 可选参数: -Port 8787 -Mode internal|external -AdminToken "your-secret"

param(
  [int]$Port = 8787,
  [string]$Mode = "internal",
  [string]$AdminToken = ""
)

$ErrorActionPreference = "Stop"
$HostAddr = if ($Mode -eq "external") { "0.0.0.0" } else { "127.0.0.1" }
if ([string]::IsNullOrEmpty($AdminToken)) {
  $AdminToken = [guid]::NewGuid().ToString("N")
}

Write-Host "=============================================="
Write-Host " Server Console Backend · Windows 一键安装"
Write-Host " 模式: $Mode   端口: $Port   绑定: $HostAddr"
Write-Host "=============================================="

# 1. 检查 / 安装 Node.js
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
  Write-Host "→ 未检测到 Node.js,正在通过 winget 安装..."
  try {
    winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
  } catch {
    Write-Host "→ winget 安装失败,请手动从 https://nodejs.org 下载安装 Node.js 18+ 后重新运行本脚本。"
    exit 1
  }
  Write-Host "→ 安装完成,请重新打开一个新的 PowerShell 窗口再运行本脚本(以刷新 PATH)。"
  exit 0
}
Write-Host "→ Node 版本: $(node -v)"

# 2. 安装依赖
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
Write-Host "→ 安装依赖..."
npm install --omit=dev --no-audit --no-fund

# 3. 写入 .env
@"
PORT=$Port
HOST=$HostAddr
MODE=$Mode
ADMIN_TOKEN=$AdminToken
"@ | Set-Content -Path ".env" -Encoding UTF8
Write-Host "→ 已写入 .env"

# 4. 注册为 Windows 服务(使用 NSSM 若已安装;否则提供任务计划程序方案)
$nssm = Get-Command nssm -ErrorAction SilentlyContinue
if ($nssm) {
  nssm install ServerConsoleBackend (Get-Command node).Source "$scriptDir\server.js"
  nssm set ServerConsoleBackend AppEnvironmentExtra "PORT=$Port" "HOST=$HostAddr" "MODE=$Mode" "ADMIN_TOKEN=$AdminToken"
  nssm set ServerConsoleBackend AppDirectory $scriptDir
  nssm start ServerConsoleBackend
  Write-Host "→ 已通过 NSSM 注册为 Windows 服务: ServerConsoleBackend"
} else {
  Write-Host "→ 未检测到 NSSM,改为创建开机自启的计划任务(每次登录自动启动,后台运行)"
  $action = New-ScheduledTaskAction -Execute (Get-Command node).Source -Argument "`"$scriptDir\server.js`"" -WorkingDirectory $scriptDir
  $trigger = New-ScheduledTaskTrigger -AtLogOn
  $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
  Register-ScheduledTask -TaskName "ServerConsoleBackend" -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
  Write-Host "→ 已注册计划任务 ServerConsoleBackend(下次登录自动启动)"
  Write-Host "→ 现在立即启动一次:"
  $env:PORT = $Port; $env:HOST = $HostAddr; $env:MODE = $Mode; $env:ADMIN_TOKEN = $AdminToken
  Start-Process -FilePath (Get-Command node).Source -ArgumentList "`"$scriptDir\server.js`"" -WindowStyle Hidden
}

Write-Host "=============================================="
Write-Host " 完成 ✓"
Write-Host " 内部访问地址: http://$HostAddr`:$Port"
Write-Host " 管理员 Token: $AdminToken"
Write-Host " 把地址填入 Server Console 的「数据源设置」即可连接"
if ($Mode -eq "external") {
  Write-Host " 提示: 已开放为外部模式,请自行配置 Windows 防火墙入站规则并妥善保管 Token"
}
Write-Host "=============================================="
